import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:provider/provider.dart';
import '../../providers/inventory_provider.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_widgets.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final _categoryController = TextEditingController();

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  void _addCategory() {
    final name = _categoryController.text.trim();
    if (name.isNotEmpty) {
      context.read<InventoryProvider>().addCategory(name);
      _categoryController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  void _confirmDelete(String category) {
    final inventory = context.read<InventoryProvider>();
    final productCount = inventory.getProductCountByCategory(category);

    if (productCount > 0) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLG)),
          child: Container(
            padding: const EdgeInsets.all(32),
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: AppTheme.warningColor, size: 40),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Kategori Tidak Kosong",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  "Kategori \"$category\" masih memiliki $productCount produk. Anda tidak dapat menghapus kategori yang masih berisi produk.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 32),
                ShadButton(
                  onPressed: () => Navigator.pop(context),
                  width: double.infinity,
                  child: const Text("MENGERTI", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLG)),
          child: Container(
            padding: const EdgeInsets.all(32),
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_forever_rounded, color: AppTheme.errorColor, size: 40),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Hapus Kategori?",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  "Anda yakin ingin menghapus kategori \"$category\"?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: ShadButton.outline(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("BATAL", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ShadButton.destructive(
                        onPressed: () {
                          inventory.removeCategory(category);
                          Navigator.pop(context);
                        },
                        child: const Text("HAPUS", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryProvider>();
    final categories = inventory.categories.where((c) => c != 'All').toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const AppHeader(
            badgeLabel: "Inventory",
            title: "Kelola Kategori",
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppInputLabel(label: "Tambah Kategori"),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ShadInput(
                          controller: _categoryController,
                          placeholder: const Text('Nama Kategori Baru'),
                          onSubmitted: (_) => _addCategory(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ShadButton(
                        onPressed: _addCategory,
                        child: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  const AppSectionTitle(title: "Daftar Kategori"),
                  const SizedBox(height: 24),
                  Expanded(
                    child: categories.isEmpty
                        ? Center(child: Text("Belum ada kategori", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))))
                        : ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: categories.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final cat = categories[index];
                              final count = inventory.getProductCountByCategory(cat);
                              return AppCard(
                                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                                radius: AppTheme.radiusMD,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.category_rounded,
                                        color: Theme.of(context).colorScheme.primary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cat,
                                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                          ),
                                          Text(
                                            '$count Produk',
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ShadButton.ghost(
                                      width: 44,
                                      height: 44,
                                      padding: EdgeInsets.zero,
                                      onPressed: () => _confirmDelete(cat),
                                      child: Icon(
                                        Icons.delete_outline_rounded,
                                        color: Theme.of(context).colorScheme.error,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
