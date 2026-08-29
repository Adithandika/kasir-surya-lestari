import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/cart_item.dart';

class PrinterService {
  final PaperSize paperSize;
  final String connectionType;
  final String printerName;
  final String ipAddress;
  final int port;

  PrinterService({
    this.paperSize = PaperSize.mm80,
    this.connectionType = 'network',
    this.printerName = 'POS-58',
    this.ipAddress = '192.168.1.100',
    this.port = 9100,
  });

  final currencyFormatter = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  /// Generates the raw bytes for the receipt using ESC/POS protocol
  Future<List<int>> _generateReceiptBytes(
    List<CartItem> items,
    double subtotal,
    double globalDiscount,
    double total,
    double cashReceived,
    double change,
    {String? memberName}
  ) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(paperSize, profile);
    List<int> bytes = [];

    // Header
    bytes += generator.text(
      'SEMBAKO JAYA',
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        bold: true,
      ),
    );
    bytes += generator.text(
      'Jl. Merdeka No. 123, Jakarta',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      'Telp: 0812-3456-7890',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(1);
    
    if (memberName != null) {
      bytes += generator.text('Member: $memberName', styles: const PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.feed(1);
    }
    
    bytes += generator.hr();

    // Items
    for (var item in items) {
      bytes += generator.text(
        item.productName ?? 'Produk',
        styles: const PosStyles(bold: true),
      );
      String qtyAndPrice =
          '${item.quantity} x ${currencyFormatter.format(item.price)}';
      String subtotalStr = currencyFormatter.format(item.subtotal);

      final is58 = paperSize == PaperSize.mm58;
      bytes += generator.row([
        PosColumn(
          text: qtyAndPrice,
          width: is58 ? 7 : 8,
          styles: const PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: subtotalStr,
          width: is58 ? 5 : 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);

      if (item.discount > 0) {
        bytes += generator.text(
          '   (Diskon: -${currencyFormatter.format(item.discount * item.quantity)})',
          styles: const PosStyles(align: PosAlign.left),
        );
      }
    }
    bytes += generator.hr();

    // Totals
    bytes += generator.row([
      PosColumn(
        text: 'SUBTOTAL',
        width: 6,
        styles: const PosStyles(align: PosAlign.left),
      ),
      PosColumn(
        text: currencyFormatter.format(subtotal),
        width: 6,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    if (globalDiscount > 0) {
      bytes += generator.row([
        PosColumn(
          text: 'DISKON GLOBAL',
          width: 6,
          styles: const PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: '-${currencyFormatter.format(globalDiscount)}',
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    bytes += generator.row([
      PosColumn(
        text: 'TOTAL',
        width: 6,
        styles: const PosStyles(bold: true, align: PosAlign.left),
      ),
      PosColumn(
        text: currencyFormatter.format(total),
        width: 6,
        styles: const PosStyles(bold: true, align: PosAlign.right),
      ),
    ]);
    bytes += generator.hr();

    bytes += generator.row([
      PosColumn(
        text: 'TUNAI',
        width: 6,
        styles: const PosStyles(align: PosAlign.left),
      ),
      PosColumn(
        text: currencyFormatter.format(cashReceived),
        width: 6,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);
    bytes += generator.row([
      PosColumn(
        text: 'KEMBALI',
        width: 6,
        styles: const PosStyles(align: PosAlign.left),
      ),
      PosColumn(
        text: currencyFormatter.format(change),
        width: 6,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);
    bytes += generator.feed(1);

    // Footer
    bytes += generator.text(
      'Terima Kasih Atas Kunjungan Anda',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      'Barang yang sudah dibeli tidak dapat ditukar',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }

  /// Send "Pulse/Kick" command to open Cash Drawer via printer's RJ11
  List<int> _generateOpenDrawerBytes() {
    // Standard ESC/POS command to kick the drawer
    return [0x1B, 0x70, 0x00, 0x19, 0xFA];
  }

  /// Central method to trigger hardware (Print & Open Drawer)
  Future<bool> printReceiptAndOpenDrawer(
    List<CartItem> items,
    double subtotal,
    double globalDiscount,
    double total,
    double cashReceived,
    double change, {
    String? memberName,
    bool openDrawer = true,
  }) async {
    try {
      List<int> bytes = [];
      if (openDrawer) {
        bytes.addAll(_generateOpenDrawerBytes());
      }

      final receiptBytes = await _generateReceiptBytes(
        items,
        subtotal,
        globalDiscount,
        total,
        cashReceived,
        change,
        memberName: memberName,
      );
      bytes.addAll(receiptBytes);

      if (connectionType == 'usb_windows') {
        await _sendToWindowsUsbPrinter(bytes);
      } else {
        await _sendToNetworkPrinter(bytes);
      }
      return true;
    } catch (e) {
      debugPrint('Hardware Error: $e');
      return false;
    }
  }

  /// Send purely the open drawer command
  Future<bool> openCashDrawer() async {
    try {
      final bytes = _generateOpenDrawerBytes();
      if (connectionType == 'usb_windows') {
        await _sendToWindowsUsbPrinter(bytes);
      } else {
        await _sendToNetworkPrinter(bytes);
      }
      return true;
    } catch (e) {
      debugPrint('Hardware Error: $e');
      return false;
    }
  }

  /// Transport Layer: Sending bytes to Network Printer (Common for desktop POS)
  Future<void> _sendToNetworkPrinter(List<int> bytes) async {
    Socket? socket;
    try {
      // Connect to printer IP and Port, timeout after 3 seconds
      socket = await Socket.connect(
        ipAddress,
        port,
        timeout: const Duration(seconds: 3),
      );
      socket.add(bytes);
      await socket.flush();
    } catch (e) {
      throw Exception('Could not connect to printer at $ipAddress:$port');
    } finally {
      socket?.destroy();
    }
  }

  /// Send bytes to Local Windows USB Printer (via printer sharing spooler UNC path)
  Future<void> _sendToWindowsUsbPrinter(List<int> bytes) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(p.join(tempDir.path, 'receipt.bin'));
      await tempFile.writeAsBytes(bytes);

      // Run cmd command to copy bin file to shared printer UNC path
      final result = await Process.run(
        'cmd',
        ['/c', 'copy', '/b', tempFile.path, '"\\\\127.0.0.1\\$printerName"'],
        runInShell: true,
      );

      if (result.exitCode != 0) {
        throw Exception('Exit code ${result.exitCode}: ${result.stderr}');
      }
    } catch (e) {
      throw Exception('Gagal mengirim ke USB printer: $e');
    }
  }
}
