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
  final String shopName;
  final String shopAddress;
  final String shopPhone;
  final String cashierName;

  PrinterService({
    this.paperSize = PaperSize.mm80,
    this.connectionType = 'network',
    this.printerName = 'POS-58',
    this.ipAddress = '192.168.1.100',
    this.port = 9100,
    this.shopName = 'Cashierya App',
    this.shopAddress = '',
    this.shopPhone = '',
    this.cashierName = 'Anggi',
  });

  final currencyFormatter = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.decimalPattern('id');
    return 'Rp ${formatter.format(amount)}';
  }

  String _formatRow(String left, String right, bool is58) {
    int maxChars = is58 ? 32 : 48;
    int padLength = maxChars - left.length - right.length;
    if (padLength < 1) {
      return '$left $right';
    }
    return left + ' ' * padLength + right;
  }

  /// Generates the raw bytes for the receipt using ESC/POS protocol
  Future<List<int>> _generateReceiptBytes(
    List<CartItem> items,
    double subtotal,
    double globalDiscount,
    double total,
    double cashReceived,
    double change, {
    String? memberName,
    int? orderId,
    DateTime? transactionDate,
  }) async {
    final isPrinter58 = paperSize == PaperSize.mm58 ||
        printerName.toLowerCase().contains('58') ||
        printerName.toLowerCase().contains('cla58');
    final actualPaperSize = isPrinter58 ? PaperSize.mm58 : PaperSize.mm80;

    final profile = await CapabilityProfile.load();
    final generator = Generator(actualPaperSize, profile);
    List<int> bytes = [];
    final is58 = actualPaperSize == PaperSize.mm58;
    final dividerLine = is58
        ? '--------------------------------'
        : '------------------------------------------------';

    // Header
    bytes += generator.text(
      shopName,
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        bold: true,
      ),
    );
    if (shopAddress.isNotEmpty) {
      bytes += generator.text(
        shopAddress,
        styles: const PosStyles(align: PosAlign.center),
      );
    }
    if (shopPhone.isNotEmpty) {
      bytes += generator.text(
        shopPhone,
        styles: const PosStyles(align: PosAlign.center),
      );
    }

    // Always print transaction ID as in the image
    final printDate = transactionDate ?? DateTime.now();
    final txId = orderId != null
        ? '767132${DateFormat('yyyyMMddHHmmss').format(printDate)}'
        : '76713220210409203314';
    bytes += generator.text(
      txId,
      styles: const PosStyles(align: PosAlign.center),
    );

    bytes += generator.feed(1);
    bytes += generator.text(
      dividerLine,
      styles: const PosStyles(align: PosAlign.center),
    );

    // Transaction Metadata (Date, Time, Cashier, Order ID)
    final dateStr = DateFormat('yyyy-MM-dd').format(printDate);
    final timeStr = DateFormat('HH:mm:ss').format(printDate);
    final idStr = orderId != null ? 'No.0-$orderId' : 'No.0-5';

    bytes += generator.text(_formatRow(dateStr, memberName ?? '-', is58));
    bytes += generator.text(_formatRow(timeStr, cashierName, is58));
    bytes += generator.text(_formatRow(idStr, '', is58));

    bytes += generator.text(
      dividerLine,
      styles: const PosStyles(align: PosAlign.center),
    );

    final plainNumberFormatter = NumberFormat.decimalPattern('id');

    // Items
    for (var item in items) {
      bytes += generator.text(item.productName ?? 'Produk');
      String qtyAndPrice =
          '${item.quantity} x ${plainNumberFormatter.format(item.price)}';
      String subtotalStr = _formatCurrency(item.subtotal);

      bytes += generator.text(_formatRow(qtyAndPrice, subtotalStr, is58));

      if (item.discount > 0) {
        bytes += generator.text(
          '   (Diskon: -${_formatCurrency(item.discount * item.quantity)})',
          styles: const PosStyles(align: PosAlign.left),
        );
      }
    }
    bytes += generator.text(
      dividerLine,
      styles: const PosStyles(align: PosAlign.center),
    );

    // Totals
    if (globalDiscount > 0) {
      bytes += generator.text(_formatRow('Subtotal', _formatCurrency(subtotal), is58));
      bytes += generator.text(_formatRow('Diskon Global', '-${_formatCurrency(globalDiscount)}', is58));
    }

    bytes += generator.text(_formatRow('Total', _formatCurrency(total), is58));
    bytes += generator.text(_formatRow('Bayar', _formatCurrency(cashReceived), is58));
    bytes += generator.text(_formatRow('Kembali', _formatCurrency(change), is58));
    bytes += generator.feed(1);

    // Footer
    bytes += generator.text(
      'Terima kasih atas kunjungan anda',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      'Semoga anda puas dengan layanan kami',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      '--------------',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      '"Pembeli adalah raja"',
      styles: const PosStyles(align: PosAlign.center, bold: true),
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
  Future<String?> printReceiptAndOpenDrawer(
    List<CartItem> items,
    double subtotal,
    double globalDiscount,
    double total,
    double cashReceived,
    double change, {
    String? memberName,
    bool openDrawer = true,
    int? orderId,
    DateTime? transactionDate,
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
        orderId: orderId,
        transactionDate: transactionDate,
      );
      bytes.addAll(receiptBytes);

      if (connectionType == 'usb_windows' ||
          connectionType == 'usb_macos' ||
          connectionType == 'usb') {
        if (Platform.isWindows) {
          await _sendToWindowsUsbPrinter(bytes);
        } else if (Platform.isMacOS || Platform.isLinux) {
          await _sendToMacOsUsbPrinter(bytes);
        } else {
          throw Exception('Koneksi USB tidak didukung di platform ini');
        }
      } else {
        await _sendToNetworkPrinter(bytes);
      }
      return null;
    } catch (e) {
      debugPrint('Hardware Error: $e');
      return e.toString();
    }
  }

  /// Send purely the open drawer command
  Future<String?> openCashDrawer() async {
    try {
      final bytes = _generateOpenDrawerBytes();
      if (connectionType == 'usb_windows' ||
          connectionType == 'usb_macos' ||
          connectionType == 'usb') {
        if (Platform.isWindows) {
          await _sendToWindowsUsbPrinter(bytes);
        } else if (Platform.isMacOS || Platform.isLinux) {
          await _sendToMacOsUsbPrinter(bytes);
        } else {
          throw Exception('Koneksi USB tidak didukung di platform ini');
        }
      } else {
        await _sendToNetworkPrinter(bytes);
      }
      return null;
    } catch (e) {
      debugPrint('Hardware Error: $e');
      return e.toString();
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
      if (!await tempFile.parent.exists()) {
        await tempFile.parent.create(recursive: true);
      }
      await tempFile.writeAsBytes(bytes);

      // Run cmd command to copy bin file to shared printer UNC path
      final result = await Process.run('cmd', [
        '/c',
        'copy',
        '/b',
        tempFile.path,
        '"\\\\127.0.0.1\\$printerName"',
      ], runInShell: true);

      if (result.exitCode != 0) {
        throw Exception('Exit code ${result.exitCode}: ${result.stderr}');
      }
    } catch (e) {
      throw Exception('Gagal mengirim ke USB printer: $e');
    }
  }

  /// Send bytes to Local macOS/Linux USB Printer (via CUPS lp command)
  Future<void> _sendToMacOsUsbPrinter(List<int> bytes) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(p.join(tempDir.path, 'receipt.bin'));
      if (!await tempFile.parent.exists()) {
        await tempFile.parent.create(recursive: true);
      }
      await tempFile.writeAsBytes(bytes);

      // Run lp command to print raw bytes to the printer queue
      final result = await Process.run('lp', [
        '-d',
        printerName,
        '-o',
        'raw',
        tempFile.path,
      ]);

      if (result.exitCode != 0) {
        throw Exception('Exit code ${result.exitCode}: ${result.stderr}');
      }
    } catch (e) {
      throw Exception('Gagal mengirim ke USB printer macOS/Linux: $e');
    }
  }

  /// Get list of local printers installed on the system (Windows / macOS / Linux)
  static Future<List<String>> getLocalPrinters() async {
    try {
      if (Platform.isMacOS || Platform.isLinux) {
        final result = await Process.run('lpstat', ['-e']);
        if (result.exitCode == 0) {
          final output = result.stdout.toString().trim();
          if (output.isEmpty) return [];
          return output
              .split(RegExp(r'\r?\n'))
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      } else if (Platform.isWindows) {
        final result = await Process.run('powershell', [
          '-Command',
          'Get-Printer | Select-Object -ExpandProperty Name',
        ]);
        if (result.exitCode == 0) {
          final output = result.stdout.toString().trim();
          if (output.isEmpty) return [];
          return output
              .split(RegExp(r'\r?\n'))
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error getting local printers: $e');
    }
    return [];
  }

  /// Automatically detect and register any connected USB printers on macOS/Linux
  static Future<Map<String, String>> autoDetectAndRegisterUsbPrinters() async {
    Map<String, String> registered = {};
    try {
      if (Platform.isMacOS || Platform.isLinux) {
        // Run the CUPS USB backend to detect connected USB printers
        final detectResult = await Process.run(
          '/usr/libexec/cups/backend/usb',
          [],
        );
        if (detectResult.exitCode == 0) {
          final output = detectResult.stdout.toString().trim();
          if (output.isNotEmpty) {
            final lines = output.split(RegExp(r'\r?\n'));
            for (var line in lines) {
              final parts = line.split(' ');
              if (parts.isNotEmpty && parts[0] == 'direct') {
                final uri = parts[1];
                final parsedUri = Uri.parse(uri);
                String name = '';
                if (parsedUri.path.isNotEmpty) {
                  name = parsedUri.path
                      .split('/')
                      .lastWhere((e) => e.isNotEmpty, orElse: () => '');
                }
                if (name.isEmpty && parsedUri.host.isNotEmpty) {
                  name = parsedUri.host;
                }
                if (name.isEmpty) {
                  name = 'USB_Printer';
                }
                name = name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

                if (name.isNotEmpty && uri.isNotEmpty) {
                  // Register via lpadmin without the deprecated -m raw flag
                  final regResult = await Process.run('lpadmin', [
                    '-p',
                    name,
                    '-v',
                    uri,
                    '-E',
                  ]);
                  if (regResult.exitCode == 0) {
                    registered[name] = uri;
                  }
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error auto-detecting USB printer: $e');
    }
    return registered;
  }
}
