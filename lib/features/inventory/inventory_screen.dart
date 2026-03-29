import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import '../../models/product.dart';
import '../../providers/inventory_provider.dart';
import 'product_editor_screen.dart';
import 'category_management_screen.dart';
import '../../core/widgets/app_widgets.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  void _showAddForm() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ProductEditorScreen()));
  }

  void _showEditForm(Product product) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => ProductEditorScreen(productToEdit: product)));
  }

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryProvider>();
    final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Premium Header
          SliverToBoxAdapter(
            child: AppHeader(
              badgeLabel: "SYSTEM INVENTORY",
              title: "Kelola Stok",
              actions: [
                _buildManageCategoryButton().animate().fadeIn(delay: 200.ms).scale(),
                const SizedBox(width: 12),
                _buildBulkStockButton().animate().fadeIn(delay: 250.ms).scale(),
                const SizedBox(width: 12),
                _buildAddButton().animate().fadeIn(delay: 300.ms).scale(),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.screenPaddingH, AppTheme.contentPaddingTop, AppTheme.screenPaddingH, AppTheme.itemGap),
              child: AppSearchField(
                controller: _searchController,
                placeholder: 'Cari produk berdasarkan nama atau barcode...',
                onChanged: (val) => context.read<InventoryProvider>().searchProduct(val),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
            ),
          ),

          // Filters and Sorting
          SliverToBoxAdapter(
            child: _buildFilterSection(context).animate().fadeIn(delay: 350.ms),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // Inventory Main Section
          SliverPadding(
            padding: AppTheme.screenPadding,
            sliver: SliverToBoxAdapter(
              child: AppCard(
                padding: const EdgeInsets.all(0),
                radius: AppTheme.radiusLG,
                child: Column(
                  children: [
                    // Table Header
                    _buildTableHeader().animate().fadeIn(delay: 400.ms),
                    Divider(height: 1, color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.05)),
                    const SizedBox(height: 8),

                    // List of Products
                    inventory.products.isEmpty
                        ? _buildEmptyState().animate().fadeIn()
                        : ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.all(12),
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: inventory.products.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 4),
                            itemBuilder: (context, index) =>
                                _buildProductItem(inventory.products[index], currencyFormatter)
                                .animate(delay: (500 + index * 30).ms)
                                .fadeIn()
                                .slideX(begin: 0.05),
                          ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 48)),
        ],
      ),
    );
  }



  Widget _buildManageCategoryButton() {
    return ShadButton.outline(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CategoryManagementScreen()),
        );
      },
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: ShadDecoration(
        border: ShadBorder.all(radius: BorderRadius.circular(100), width: 1, color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.category_rounded, size: 20),
          SizedBox(width: 8),
          Text('Kategori', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
  Widget _buildBulkStockButton() {
    return ShadButton.outline(
      onPressed: _showBulkStockDialog,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: ShadDecoration(
        border: ShadBorder.all(radius: BorderRadius.circular(100), width: 1, color: Theme.of(context).primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.barcode_reader, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          const Text('INPUT STOK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  void _showBulkStockDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const BulkStockDialog(),
    );
  }

  Widget _buildAddButton() {
    return ShadButton(
      onPressed: _showAddForm,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: ShadDecoration(
        border: ShadBorder.all(radius: BorderRadius.circular(100), width: 0, color: Colors.transparent),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_rounded, size: 20),
          SizedBox(width: 8),
          Text("PRODUK BARU", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 13)),
        ],
      ),
    );
  }
  Widget _buildFilterSection(BuildContext context) {
    final inventory = context.watch<InventoryProvider>();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.screenPaddingH),
      child: Row(
        children: [
          // Sort Options
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.05)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sort_rounded, size: 16, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: inventory.sortBy,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                  style: TextStyle(
                    fontSize: 12, 
                    fontWeight: FontWeight.w600, 
                    color: Theme.of(context).colorScheme.onSurface
                  ),
                  items: [
                    'Name (A-Z)', 'Name (Z-A)',
                    'Price (Low-High)', 'Price (High-Low)',
                    'Stock (Low-High)', 'Stock (High-Low)'
                  ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) => inventory.setSortBy(val!),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Category Chips
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: inventory.categories.map((cat) {
                  final isSelected = inventory.selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) inventory.filterByCategory(cat);
                      },
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                      ),
                      selectedColor: Theme.of(context).primaryColor,
                      backgroundColor: Theme.of(context).cardTheme.color,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                        side: BorderSide(
                          color: isSelected ? Colors.transparent : Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                        ),
                      ),
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildTableHeader() {
    final headerStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 10,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
      letterSpacing: 1,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.screenPaddingH, 20, AppTheme.screenPaddingH, 16),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text("PRODUK", style: headerStyle)),
          Expanded(flex: 2, child: Text("KATEGORI", style: headerStyle)),
          Expanded(flex: 2, child: Text("HARGA JUAL", style: headerStyle)),
          Expanded(flex: 1, child: Text("STOK", textAlign: TextAlign.center, style: headerStyle)),
          Expanded(flex: 2, child: Text("STATUS", textAlign: TextAlign.center, style: headerStyle)),
          Expanded(flex: 1, child: Text("AKSI", textAlign: TextAlign.center, style: headerStyle)),
        ],
      ),
    );
  }

  Widget _buildProductItem(Product product, NumberFormat formatter) {
    bool isLowStock = product.stock < 5 && product.stock > 0;
    bool isOut = product.stock <= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isOut ? AppTheme.errorColor.withValues(alpha: 0.02) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
      ),
      child: Row(
        children: [
          // Product Name & Barcode
          Expanded(
            flex: 3,
            child: Row(
              children: [
                AppProductImage(imagePath: product.imagePath),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                      Text(
                        product.barcode,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), 
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Category
          Expanded(
            flex: 2,
            child: Text(
              product.category,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),

          // Price
          Expanded(
            flex: 2,
            child: Text(
              formatter.format(product.price),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: Theme.of(context).primaryColor,
                letterSpacing: -0.2,
              ),
            ),
          ),

          // Stock
          Expanded(
            flex: 1,
            child: Text(
              "${product.stock}",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: isOut
                      ? AppTheme.errorColor
                      : (isLowStock
                          ? AppTheme.warningColor
                          : Theme.of(context).colorScheme.onSurface),
              ),
            ),
          ),

          // Status
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isOut
                      ? AppTheme.errorColor.withValues(alpha: 0.1)
                      : (isLowStock ? AppTheme.warningColor.withValues(alpha: 0.1) : AppTheme.successColor.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  isOut ? 'HABIS' : (isLowStock ? 'LOW' : 'STOK AMAN'),
                  style: TextStyle(
                    color: isOut ? AppTheme.errorColor : (isLowStock ? AppTheme.warningColor : AppTheme.successColor),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),

          // Actions
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(
                  Icons.edit_rounded,
                  Theme.of(context).primaryColor,
                  () => _showEditForm(product),
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  Icons.delete_outline_rounded,
                  AppTheme.errorColor,
                  () => _confirmDelete(product),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onPressed) {
    return ShadButton.ghost(
      onPressed: onPressed,
      padding: const EdgeInsets.all(8),
      child: Icon(icon, color: color, size: 16),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Icon(Icons.inventory_2_outlined, size: 64, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text(
            "Belum ada produk",
            style: TextStyle(
              fontWeight: FontWeight.w800, 
              fontSize: 16, 
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  void _confirmDelete(Product product) {
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
                "Hapus Produk?",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
              ),
              const SizedBox(height: 12),
              Text(
                "Anda yakin ingin menghapus \"${product.name}\"? Tindakan ini tidak dapat dibatalkan.",
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
                        context.read<InventoryProvider>().deleteProduct(product.id);
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
class BulkStockDialog extends StatefulWidget {
  const BulkStockDialog({super.key});

  @override
  State<BulkStockDialog> createState() => _BulkStockDialogState();
}

class _BulkStockDialogState extends State<BulkStockDialog> {
  final Map<int, int> _scannedItems = {}; // productId -> addedQuantity
  final TextEditingController _barcodeController = TextEditingController();
  final FocusNode _barcodeFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _barcodeFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _barcodeFocus.dispose();
    super.dispose();
  }

  void _onBarcodeScanned(String barcode) {
    if (barcode.trim().isEmpty) return;
    
    final inventory = context.read<InventoryProvider>();
    final product = inventory.findByBarcode(barcode.trim());
    
    if (product != null) {
      setState(() {
        _scannedItems[product.id] = (_scannedItems[product.id] ?? 0) + 1;
      });
      _barcodeController.clear();
      _barcodeFocus.requestFocus();
    } else {
      ShadSonner.of(context).show(
        ShadToast.destructive(title: Text('Produk dengan barcode $barcode tidak ditemukan')),
      );
      _barcodeController.clear();
      _barcodeFocus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryProvider>();
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLG)),
      child: Container(
        width: 600,
        height: 700,
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppBadge(label: "STOCK MANAGEMENT"),
                    SizedBox(height: 12),
                    Text(
                      "Input Stok Masal",
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.scaffoldBackgroundColor,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Scanner Input
            AppSearchField(
              controller: _barcodeController,
              focusNode: _barcodeFocus,
              placeholder: "Scan barcode produk di sini...",
              onSubmitted: _onBarcodeScanned,
              onChanged: (val) {
                // Some scanners send 'Enter', some don't. 
                // We'll rely on onSubmitted for explicit scans.
              },
            ),
            const SizedBox(height: 24),
            
            Expanded(
              child: _scannedItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_scanner_rounded, size: 48, color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                          const SizedBox(height: 16),
                          Text(
                            "Belum ada produk yang di-scan",
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: _scannedItems.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final productId = _scannedItems.keys.elementAt(index);
                        final addedQty = _scannedItems[productId];
                        final product = inventory.products.firstWhere((p) => p.id == productId);
                        
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.05)),
                          ),
                          child: Row(
                            children: [
                              AppProductImage(imagePath: product.imagePath, size: 44),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(product.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                    Text(
                                      "Stok Saat Ini: ${product.stock}",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.remove_circle_outline_rounded, size: 20, color: AppTheme.errorColor),
                                    onPressed: () {
                                      setState(() {
                                        if (_scannedItems[productId]! > 1) {
                                          _scannedItems[productId] = _scannedItems[productId]! - 1;
                                        } else {
                                          _scannedItems.remove(productId);
                                        }
                                      });
                                    },
                                  ),
                                  SizedBox(
                                    width: 40,
                                    child: Center(
                                      child: Text(
                                        "+$addedQty",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                          color: theme.primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.add_circle_outline_rounded, size: 20, color: AppTheme.successColor),
                                    onPressed: () {
                                      setState(() {
                                        _scannedItems[productId] = _scannedItems[productId]! + 1;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ).animate(delay: (index * 30).ms).fadeIn().slideX(begin: 0.1);
                      },
                    ),
            ),
            
            const SizedBox(height: 24),
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
                  child: ShadButton(
                    onPressed: _scannedItems.isEmpty ? null : _saveRestock,
                    child: const Text("SIMPAN STOK", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveRestock() async {
    final inventory = context.read<InventoryProvider>();
    int totalAdded = 0;
    
    for (var entry in _scannedItems.entries) {
      await inventory.addStock(entry.key, entry.value);
      totalAdded += entry.value;
    }
    
    if (mounted) {
      Navigator.pop(context);
      ShadSonner.of(context).show(
        ShadToast(
          title: const Text('Berhasil!'),
          description: Text('$totalAdded item stok telah ditambahkan ke gudang.'),
        ),
      );
    }
  }
}
