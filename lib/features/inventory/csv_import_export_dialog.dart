import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../providers/inventory_provider.dart';
import '../../services/inventory_csv_service.dart';

class CsvImportExportDialog extends StatefulWidget {
  const CsvImportExportDialog({super.key});

  @override
  State<CsvImportExportDialog> createState() => _CsvImportExportDialogState();
}

class _CsvImportExportDialogState extends State<CsvImportExportDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _updateExisting = true;
  bool _isExporting = false;
  bool _isImporting = false;

  String? _selectedFileName;
  CsvParseResult? _parseResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<String?> _saveCsvFile(String defaultFileName, String content) async {
    try {
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan Berkas CSV',
        fileName: defaultFileName,
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (outputPath == null) {
        return null;
      }

      if (!outputPath.toLowerCase().endsWith('.csv')) {
        outputPath = '$outputPath.csv';
      }

      final file = File(outputPath);
      await file.writeAsString(content);
      return outputPath;
    } catch (e) {
      final dir = await getApplicationDocumentsDirectory();
      final fallbackPath = p.join(dir.path, defaultFileName);
      final file = File(fallbackPath);
      await file.writeAsString(content);
      return fallbackPath;
    }
  }

  Future<void> _exportProducts() async {
    setState(() => _isExporting = true);
    try {
      final inventory = context.read<InventoryProvider>();
      final products = inventory.products;

      if (products.isEmpty) {
        if (!mounted) return;
        ShadSonner.of(context).show(
          const ShadToast.destructive(
            title: Text('Katalog Kosong'),
            description: Text('Tidak ada data produk yang dapat diekspor.'),
          ),
        );
        return;
      }

      final csvData = InventoryCsvService.exportProductsToCsv(products);
      final now = DateTime.now();
      final dateStr = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}";
      final fileName = 'katalog_produk_$dateStr.csv';

      final savedPath = await _saveCsvFile(fileName, csvData);

      if (!mounted) return;
      if (savedPath != null) {
        ShadSonner.of(context).show(
          ShadToast(
            title: const Text('Ekspor Berhasil!'),
            description: Text('Sebanyak ${products.length} produk berhasil diekspor ke "$fileName".'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ShadSonner.of(context).show(
        ShadToast.destructive(
          title: const Text('Ekspor Gagal'),
          description: Text('Terjadi kesalahan: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _downloadTemplate() async {
    try {
      final templateData = InventoryCsvService.generateSampleCsvTemplate();
      const fileName = 'template_import_produk.csv';

      final savedPath = await _saveCsvFile(fileName, templateData);

      if (!mounted) return;
      if (savedPath != null) {
        ShadSonner.of(context).show(
          const ShadToast(
            title: Text('Template Berhasil Diunduh!'),
            description: Text('Template "$fileName" siap diisi dengan data barang Anda.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ShadSonner.of(context).show(
        ShadToast.destructive(
          title: const Text('Gagal Mengunduh Template'),
          description: Text('Terjadi kesalahan: $e'),
        ),
      );
    }
  }

  Future<void> _pickCsvFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final picked = result.files.first;
        String content = '';

        if (picked.bytes != null) {
          content = utf8.decode(picked.bytes!);
        } else if (picked.path != null) {
          content = await File(picked.path!).readAsString();
        }

        if (content.isNotEmpty) {
          final parseResult = InventoryCsvService.parseCsv(content);
          setState(() {
            _selectedFileName = picked.name;
            _parseResult = parseResult;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ShadSonner.of(context).show(
        ShadToast.destructive(
          title: const Text('Gagal Membaca Berkas'),
          description: Text('Pastikan berkas CSV valid: $e'),
        ),
      );
    }
  }

  Future<void> _executeImport() async {
    if (_parseResult == null || !_parseResult!.hasValidData) return;

    setState(() => _isImporting = true);

    try {
      final inventory = context.read<InventoryProvider>();
      final stats = await inventory.importProducts(
        _parseResult!.validProducts,
        updateExisting: _updateExisting,
      );

      if (!mounted) return;
      Navigator.of(context).pop();

      _showImportSuccessDialog(context, stats);
    } catch (e) {
      if (!mounted) return;
      ShadSonner.of(context).show(
        ShadToast.destructive(
          title: const Text('Impor Gagal'),
          description: Text('Gagal menyimpan data ke database: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  void _showImportSuccessDialog(BuildContext context, Map<String, int> stats) {
    final added = stats['added'] ?? 0;
    final updated = stats['updated'] ?? 0;
    final skipped = stats['skipped'] ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLG)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppTheme.successColor, size: 24),
            ),
            const SizedBox(width: 12),
            const Text("Impor Selesai!", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Proses impor data barang telah berhasil dilakukan:", style: TextStyle(fontSize: 13)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.05)),
              ),
              child: Column(
                children: [
                  _buildStatRow("Produk Baru Ditambahkan:", "$added Produk", AppTheme.successColor),
                  const SizedBox(height: 8),
                  _buildStatRow("Produk Diperbarui:", "$updated Produk", Theme.of(context).primaryColor),
                  if (skipped > 0) ...[
                    const SizedBox(height: 8),
                    _buildStatRow("Produk Dilewati:", "$skipped Produk", Colors.orange),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          ShadButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("TUTUP", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 14),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLG)),
      child: Container(
        width: 680,
        height: 640,
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppBadge(label: "BULK DATA MANAGEMENT"),
                    SizedBox(height: 8),
                    Text(
                      "Ekspor & Impor Produk",
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -1),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 22),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.scaffoldBackgroundColor,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Tab Bar Switcher
            Container(
              height: 46,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.05)),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: theme.primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 1),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: "IMPOR DATA (CSV)"),
                  Tab(text: "EKSPOR & TEMPLATE"),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildImportTab(theme),
                  _buildExportTab(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportTab(ThemeData theme) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag/Picker Area
          InkWell(
            onTap: _pickCsvFile,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedFileName != null
                      ? theme.primaryColor
                      : theme.colorScheme.outline.withValues(alpha: 0.1),
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _selectedFileName != null ? Icons.description_rounded : Icons.file_upload_outlined,
                      size: 32,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _selectedFileName ?? "Pilih Berkas CSV Produk",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _selectedFileName != null
                        ? "Klik untuk mengganti berkas"
                        : "Format yang didukung: .csv dengan pemisah koma atau titik koma",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // File Summary / Validation Feedback
          if (_parseResult != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _parseResult!.hasValidData
                    ? AppTheme.successColor.withValues(alpha: 0.05)
                    : AppTheme.errorColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _parseResult!.hasValidData
                      ? AppTheme.successColor.withValues(alpha: 0.2)
                      : AppTheme.errorColor.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _parseResult!.hasValidData ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                        size: 20,
                        color: _parseResult!.hasValidData ? AppTheme.successColor : AppTheme.errorColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${_parseResult!.validProducts.length} Produk Valid Ditemukan",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: _parseResult!.hasValidData ? AppTheme.successColor : AppTheme.errorColor,
                        ),
                      ),
                    ],
                  ),
                  if (_parseResult!.errors.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      "Peringatan (${_parseResult!.errors.length} baris dilewati):",
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.errorColor),
                    ),
                    const SizedBox(height: 4),
                    ..._parseResult!.errors.take(3).map((err) => Text(
                          "• $err",
                          style: const TextStyle(fontSize: 11, color: AppTheme.errorColor),
                        )),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Duplicate Handling Options
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Perbarui Data Duplikat",
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Jika barcode sudah ada di database, update nama, harga, dan stok.",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ShadSwitch(
                    value: _updateExisting,
                    onChanged: (val) => setState(() => _updateExisting = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Execute Import Button
            ShadButton(
              onPressed: (_isImporting || !_parseResult!.hasValidData) ? null : _executeImport,
              width: double.infinity,
              size: ShadButtonSize.lg,
              decoration: ShadDecoration(
                border: ShadBorder.all(radius: BorderRadius.circular(100), width: 0, color: Colors.transparent),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isImporting)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  else
                    const Icon(Icons.file_download_done_rounded, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    _isImporting ? "MENYIMPAN KE DATABASE..." : "IMPOR ${_parseResult!.validProducts.length} PRODUK SEKARANG",
                    style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExportTab(ThemeData theme) {
    final inventory = context.watch<InventoryProvider>();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Export Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.file_download_outlined, color: theme.primaryColor, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Ekspor Seluruh Katalog Produk", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                          const SizedBox(height: 2),
                          Text(
                            "Simpan ${inventory.products.length} produk aktif ke file spreadsheet CSV.",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ShadButton(
                  onPressed: _isExporting ? null : _exportProducts,
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isExporting)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      else
                        const Icon(Icons.download_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        _isExporting ? "MENGEKSPOR DATA..." : "EKSPOR DATA PRODUK (CSV)",
                        style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Download Template Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.table_chart_outlined, color: theme.colorScheme.onSurface, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Unduh Template CSV Standar", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                          const SizedBox(height: 2),
                          Text(
                            "Gunakan template ini untuk mengisi data produk dari Excel / Spreadsheet sebelum diimpor.",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ShadButton.outline(
                  onPressed: _downloadTemplate,
                  width: double.infinity,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.download_outlined, size: 18),
                      SizedBox(width: 8),
                      Text("UNDUH TEMPLATE PRODUK (CSV)", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
