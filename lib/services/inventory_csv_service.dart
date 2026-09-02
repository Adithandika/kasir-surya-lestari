import '../models/product.dart';

class CsvParseResult {
  final List<Product> validProducts;
  final int totalRows;
  final List<String> errors;

  CsvParseResult({
    required this.validProducts,
    required this.totalRows,
    required this.errors,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get hasValidData => validProducts.isNotEmpty;
}

class InventoryCsvService {
  static const List<String> headers = [
    'Barcode',
    'Nama Produk',
    'Kategori',
    'Harga Modal',
    'Harga Jual',
    'Stok',
  ];

  static String _escapeCell(dynamic val) {
    final str = val?.toString() ?? '';
    if (str.contains(',') || str.contains(';') || str.contains('"') || str.contains('\n') || str.contains('\r')) {
      return '"${str.replaceAll('"', '""')}"';
    }
    return str;
  }

  /// Exports the list of products into a CSV formatted string
  static String exportProductsToCsv(List<Product> products) {
    final buffer = StringBuffer();
    buffer.writeln(headers.map(_escapeCell).join(','));

    for (final p in products) {
      buffer.writeln([
        _escapeCell(p.barcode),
        _escapeCell(p.name),
        _escapeCell(p.category),
        _escapeCell(p.costPrice.toInt()),
        _escapeCell(p.price.toInt()),
        _escapeCell(p.stock),
      ].join(','));
    }

    return buffer.toString();
  }

  /// Generates a standard template with headers and example items
  static String generateSampleCsvTemplate() {
    final buffer = StringBuffer();
    buffer.writeln(headers.map(_escapeCell).join(','));
    buffer.writeln([_escapeCell('899123456781'), _escapeCell('Beras Ramos 5Kg'), _escapeCell('Sembako'), 70000, 75000, 20].join(','));
    buffer.writeln([_escapeCell('899123456782'), _escapeCell('Minyak Goreng 2L'), _escapeCell('Sembako'), 35000, 38000, 15].join(','));
    buffer.writeln([_escapeCell('899123456783'), _escapeCell('Teh Botol 350ml'), _escapeCell('Minuman'), 3000, 4000, 50].join(','));
    return buffer.toString();
  }

  /// Parses raw CSV string into rows with support for quotes, commas, and semicolons
  static List<List<String>> _parseCsvRows(String input) {
    final List<List<String>> rows = [];
    List<String> currentRow = [];
    final StringBuffer currentCell = StringBuffer();
    bool inQuotes = false;

    // Detect delimiter: check if first line uses semicolon (common in Indonesian Excel)
    String delimiter = ',';
    final lines = input.split(RegExp(r'\r\n|\n|\r'));
    final firstNonEmpty = lines.firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
    if (firstNonEmpty.contains(';') && (!firstNonEmpty.contains(',') || firstNonEmpty.split(';').length > firstNonEmpty.split(',').length)) {
      delimiter = ';';
    }

    for (int i = 0; i < input.length; i++) {
      final char = input[i];

      if (inQuotes) {
        if (char == '"') {
          if (i + 1 < input.length && input[i + 1] == '"') {
            currentCell.write('"');
            i++; // skip escaped quote
          } else {
            inQuotes = false;
          }
        } else {
          currentCell.write(char);
        }
      } else {
        if (char == '"') {
          inQuotes = true;
        } else if (char == delimiter) {
          currentRow.add(currentCell.toString().trim());
          currentCell.clear();
        } else if (char == '\n' || char == '\r') {
          if (char == '\r' && i + 1 < input.length && input[i + 1] == '\n') {
            i++; // skip \r\n
          }
          currentRow.add(currentCell.toString().trim());
          currentCell.clear();
          if (currentRow.any((c) => c.isNotEmpty)) {
            rows.add(currentRow);
          }
          currentRow = [];
        } else {
          currentCell.write(char);
        }
      }
    }

    if (currentCell.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(currentCell.toString().trim());
      if (currentRow.any((c) => c.isNotEmpty)) {
        rows.add(currentRow);
      }
    }

    return rows;
  }

  /// Parses CSV content into a list of Product models with robust header detection and validation
  static CsvParseResult parseCsv(String csvContent) {
    if (csvContent.trim().isEmpty) {
      return CsvParseResult(
        validProducts: [],
        totalRows: 0,
        errors: ['Berkas CSV kosong.'],
      );
    }

    final rawRows = _parseCsvRows(csvContent);

    if (rawRows.isEmpty) {
      return CsvParseResult(
        validProducts: [],
        totalRows: 0,
        errors: ['Tidak ada data yang terbaca dari berkas CSV.'],
      );
    }

    // Find header indices (case-insensitive and tolerant)
    final headerRow = rawRows.first.map((e) => e.toLowerCase()).toList();

    int barcodeIdx = -1;
    int nameIdx = -1;
    int categoryIdx = -1;
    int costPriceIdx = -1;
    int priceIdx = -1;
    int stockIdx = -1;

    for (int i = 0; i < headerRow.length; i++) {
      final h = headerRow[i];
      if (h.contains('barcode') || h.contains('sku') || h == 'kode') {
        barcodeIdx = i;
      } else if (h.contains('nama') || h.contains('name') || h.contains('produk') || h.contains('item')) {
        nameIdx = i;
      } else if (h.contains('kategori') || h.contains('category')) {
        categoryIdx = i;
      } else if (h.contains('modal') || h.contains('cost') || h.contains('beli') || h.contains('harga beli')) {
        costPriceIdx = i;
      } else if (h.contains('jual') || h.contains('price') || h.contains('harga') || h.contains('harga jual')) {
        priceIdx = i;
      } else if (h.contains('stok') || h.contains('stock') || h.contains('qty') || h.contains('jumlah')) {
        stockIdx = i;
      }
    }

    // Fallback if exact names weren't matched but row length is standard (6 columns)
    if (barcodeIdx == -1 && nameIdx == -1) {
      if (headerRow.length >= 6) {
        barcodeIdx = 0;
        nameIdx = 1;
        categoryIdx = 2;
        costPriceIdx = 3;
        priceIdx = 4;
        stockIdx = 5;
      } else {
        return CsvParseResult(
          validProducts: [],
          totalRows: rawRows.length - 1,
          errors: [
            'Format kolom tidak valid. Pastikan header CSV memiliki kolom: Barcode, Nama Produk, Kategori, Harga Modal, Harga Jual, Stok.'
          ],
        );
      }
    }

    final List<Product> validProducts = [];
    final List<String> errors = [];
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    for (int i = 1; i < rawRows.length; i++) {
      final row = rawRows[i];
      if (row.isEmpty || (row.length == 1 && row[0].isEmpty)) {
        continue;
      }

      String barcode = barcodeIdx >= 0 && barcodeIdx < row.length
          ? row[barcodeIdx]
          : '';
      String name = nameIdx >= 0 && nameIdx < row.length
          ? row[nameIdx]
          : '';
      String category = categoryIdx >= 0 && categoryIdx < row.length
          ? row[categoryIdx]
          : 'Sembako';
      String costPriceStr = costPriceIdx >= 0 && costPriceIdx < row.length
          ? row[costPriceIdx]
          : '0';
      String priceStr = priceIdx >= 0 && priceIdx < row.length
          ? row[priceIdx]
          : '0';
      String stockStr = stockIdx >= 0 && stockIdx < row.length
          ? row[stockIdx]
          : '0';

      if (name.isEmpty) {
        errors.add('Baris ke-${i + 1}: Nama produk tidak boleh kosong.');
        continue;
      }

      if (barcode.isEmpty) {
        barcode = '899${(timestamp % 1000000000) + i}';
      }

      if (category.isEmpty) {
        category = 'Sembako';
      }

      final cleanCostPrice = _parsePrice(costPriceStr);
      final cleanPrice = _parsePrice(priceStr);
      final cleanStock = _parseStock(stockStr);

      final product = Product(
        remoteId: '${timestamp}_$i',
        name: name,
        category: category,
        price: cleanPrice,
        costPrice: cleanCostPrice,
        stock: cleanStock,
        barcode: barcode,
      );

      validProducts.add(product);
    }

    return CsvParseResult(
      validProducts: validProducts,
      totalRows: rawRows.length - 1,
      errors: errors,
    );
  }

  static double _parsePrice(String input) {
    if (input.isEmpty) return 0;
    String cleaned = input.replaceAll('Rp', '').replaceAll('rp', '').replaceAll(' ', '').trim();

    if (cleaned.contains('.') && cleaned.contains(',')) {
      if (cleaned.lastIndexOf(',') > cleaned.lastIndexOf('.')) {
        cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
      } else {
        cleaned = cleaned.replaceAll(',', '');
      }
    } else if (cleaned.contains('.')) {
      final parts = cleaned.split('.');
      if (parts.length > 2 || (parts.length == 2 && parts[1].length == 3)) {
        cleaned = cleaned.replaceAll('.', '');
      }
    } else if (cleaned.contains(',')) {
      final parts = cleaned.split(',');
      if (parts.length > 2 || (parts.length == 2 && parts[1].length == 3)) {
        cleaned = cleaned.replaceAll(',', '');
      } else {
        cleaned = cleaned.replaceAll(',', '.');
      }
    }

    return double.tryParse(cleaned) ?? 0;
  }

  static int _parseStock(String input) {
    if (input.isEmpty) return 0;
    String cleaned = input.replaceAll(RegExp(r'[^0-9\-]'), '');
    return int.tryParse(cleaned) ?? 0;
  }
}
