import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/theme_provider.dart';
import 'payment_modal.dart';
import '../../core/widgets/app_widgets.dart';
import '../../models/product.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final TextEditingController _barcodeController = TextEditingController();
  final FocusNode _barcodeFocus = FocusNode();
  double? _customCartWidth;
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _barcodeFocus.requestFocus();
      // Initialize cart width from saved preferences
      setState(() {
        _customCartWidth = context.read<ThemeProvider>().posCartWidth;
      });
    });
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _barcodeFocus.dispose();
    super.dispose();
  }

  void _onBarcodeSubmitted(String barcode) {
    final trimmedBarcode = barcode.trim();
    if (trimmedBarcode.isEmpty) return;

    final inventory = context.read<InventoryProvider>();
    final product = inventory.findByBarcode(trimmedBarcode);
    
    if (product != null) {
      _addProductToCartAndClear(product);
    } else {
      ShadSonner.of(context).show(
        const ShadToast.destructive(title: Text('Produk tidak ditemukan')),
      );
      _barcodeController.clear();
      _barcodeFocus.requestFocus();
    }
  }

  void _addProductToCartAndClear(dynamic product) {
    final cart = context.read<CartProvider>();
    final added = cart.addProduct(product);
    if (!added) {
      ShadSonner.of(context).show(
        ShadToast.destructive(
          title: const Text('Stok tidak mencukupi'),
          description: Text(product.stock <= 0
              ? 'Stok produk "${product.name}" habis.'
              : 'Stok produk "${product.name}" sudah maksimal (${product.stock}).'),
        ),
      );
    }
    _barcodeController.clear();
    _barcodeFocus.requestFocus(); // Keep focus for next scan
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 1000;
          double defaultCartWidth = isWide ? 320 : constraints.maxWidth * 0.3;
          if (defaultCartWidth < 280) defaultCartWidth = 280;
          
          double currentCartWidth = (_customCartWidth ?? defaultCartWidth).clamp(280.0, constraints.maxWidth * 0.5);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Side: Product Grid Area
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: AppTheme.contentPaddingTop),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      const AppHeader(
                        badgeLabel: "CASHIERYA POS",
                        title: "Pilih Produk",
                      ),
                      const SizedBox(height: 24),

                      // Toolbar: Search + View Toggle
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.screenPaddingH),
                        child: Row(
                          children: [
                            Expanded(
                              child: AppSearchField(
                                controller: _barcodeController,
                                focusNode: _barcodeFocus,
                                placeholder: 'Cari produk atau scan barcode...',
                                onSubmitted: _onBarcodeSubmitted,
                                onChanged: (val) {
                                  final inventory = context.read<InventoryProvider>();
                                  inventory.searchProduct(val);
                                  final trimmedVal = val.trim();
                                  if (trimmedVal.isNotEmpty) {
                                    final product = inventory.findByBarcode(trimmedVal);
                                    if (product != null) {
                                      _addProductToCartAndClear(product);
                                    }
                                  }
                                },
                              ).animate().fadeIn(delay: 200.ms),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                                border: Border.all(
                                  color: theme.colorScheme.outline.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Row(
                                children: [
                                  _buildViewToggleBtn(Icons.grid_view_rounded, _isGridView, () => setState(() => _isGridView = true)),
                                  _buildViewToggleBtn(Icons.view_list_rounded, !_isGridView, () => setState(() => _isGridView = false)),
                                ],
                              ),
                            ).animate().fadeIn(delay: 250.ms),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.contentPaddingTop),

                      // Categories Scroller
                      Padding(
                        padding: const EdgeInsets.only(left: AppTheme.screenPaddingH),
                        child: _buildCategoryScroller().animate().fadeIn(delay: 300.ms),
                      ),
                      const SizedBox(height: 24),

                      // Product Display
                      Expanded(child: _isGridView ? _buildProductGrid() : _buildProductList()),
                    ],
                  ),
                ),
              ),

              // Draggable Divider
              MouseRegion(
                cursor: SystemMouseCursors.resizeLeftRight,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _customCartWidth = (_customCartWidth ?? defaultCartWidth) - details.delta.dx;
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_customCartWidth != null) {
                      context.read<ThemeProvider>().setPosCartWidth(_customCartWidth!);
                    }
                  },
                  child: Container(
                    width: 4,
                    height: double.infinity,
                    color: Colors.transparent,
                    child: Center(
                      child: Container(
                        width: 1,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Right Side: Cart Panel
              Container(
                width: currentCartWidth,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  border: Border(
                    left: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cart Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient(theme.primaryColor),
                              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                            ),
                            child: const Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Keranjang",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Theme.of(context).colorScheme.onSurface,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Text(
                                  "Pesanan Aktif",
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
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

                    const SizedBox(height: 8),

                    // Active Items List
                    Expanded(child: _buildCartItemsList()),

                    // Cart Footer / Totals
                    _buildCartFooter(constraints.maxHeight),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.1, duration: 400.ms),
            ],
          );
        },
      ),
    );
  }

  Widget _buildViewToggleBtn(IconData icon, bool isActive, VoidCallback onTap) {
    return _HoverToggleBtn(icon: icon, isActive: isActive, onTap: onTap);
  }



  Widget _buildCategoryScroller() {
    return Consumer<InventoryProvider>(
      builder: (context, inventory, child) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: inventory.categories.map((cat) {
              bool isSelected = inventory.selectedCategory == cat;
              return              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    inventory.filterByCategory(cat);
                    _barcodeFocus.requestFocus();
                  },
                  child: _CategoryChip(
                    cat: cat,
                    isSelected: isSelected,
                    onTap: () {
                      inventory.filterByCategory(cat);
                      _barcodeFocus.requestFocus();
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }



  Widget _buildProductList() {
    final theme = Theme.of(context);
    
    return Consumer<InventoryProvider>(
      builder: (context, inventory, child) {
        if (inventory.products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_rounded, size: 48, color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                const SizedBox(height: 16),
                Text(
                  "Produk tidak ditemukan",
                  style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }

        final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0);

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.screenPaddingH, vertical: 12),
          itemCount: inventory.products.length,
          itemBuilder: (context, index) {
            final product = inventory.products[index];
            
            return _ProductListItem(
              product: product, 
              index: index, 
              currencyFormatter: currencyFormatter,
              onTap: () {
                final cart = context.read<CartProvider>();
                final added = cart.addProduct(product);
                if (!added) {
                  ShadSonner.of(context).show(
                    ShadToast.destructive(
                      title: const Text('Stok tidak mencukupi'),
                      description: Text(product.stock <= 0
                          ? 'Stok produk "${product.name}" habis.'
                          : 'Stok produk "${product.name}" sudah maksimal (${product.stock}).'),
                    ),
                  );
                }
                _barcodeFocus.requestFocus();
              },
            );
          },
        );
      },
    );
  }

  Widget _buildProductGrid() {
    final theme = Theme.of(context);
    return Consumer<InventoryProvider>(
      builder: (context, inventory, child) {
        if (inventory.products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_rounded, size: 48, color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                const SizedBox(height: 16),
                Text(
                  "Produk tidak ditemukan",
                  style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }

        final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0);

        return GridView.builder(
          physics: const BouncingScrollPhysics(),
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.screenPaddingH, vertical: 16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 220,
            mainAxisExtent: 260,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: inventory.products.length,
          itemBuilder: (context, index) {
            final product = inventory.products[index];

            return _ProductGridItem(
              product: product, 
              index: index, 
              currencyFormatter: currencyFormatter,
              onTap: () {
                final cart = context.read<CartProvider>();
                final added = cart.addProduct(product);
                if (!added) {
                  ShadSonner.of(context).show(
                    ShadToast.destructive(
                      title: const Text('Stok tidak mencukupi'),
                      description: Text(product.stock <= 0
                          ? 'Stok produk "${product.name}" habis.'
                          : 'Stok produk "${product.name}" sudah maksimal (${product.stock}).'),
                    ),
                  );
                }
                _barcodeFocus.requestFocus();
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCartItemsList() {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        if (cart.items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.shopping_cart_outlined, size: 48, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
                ),
                const SizedBox(height: 16),
                Text(
                  "Keranjang Kosong",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Scann produk untuk mengisi",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2), 
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ).animate().fadeIn(),
          );
        }

        final currencyFormatter = NumberFormat.currency(
          locale: 'id',
          symbol: 'Rp',
          decimalDigits: 0,
        );

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${cart.totalItems} Produk",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.delete_sweep_rounded, size: 14),
                    label: const Text(
                      "Hapus Semua",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () {
                      _showClearCartConfirmationDialog(context, cart);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: cart.items.length,
                itemBuilder: (context, index) {
            final item = cart.items[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: isLocalFileValid(item.productImagePath)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(item.productImagePath!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.inventory_2_rounded,
                                size: 18,
                                color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                              ),
                            ),
                          )
                        : Icon(
                            Icons.inventory_2_rounded,
                            size: 18,
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              currencyFormatter.format(item.price),
                              style: TextStyle(
                                color: item.discount > 0 ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                decoration: item.discount > 0 ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            if (item.discount > 0) ...[
                              const SizedBox(width: 6),
                              Text(
                                currencyFormatter.format(item.price - item.discount),
                                style: TextStyle(
                                  color: AppTheme.errorColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.discount_rounded,
                      size: 16,
                      color: item.discount > 0 ? AppTheme.errorColor : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                    ),
                    onPressed: () => _showItemDiscountDialog(context, cart, item),
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 4),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.05)),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove_rounded, size: 14, color: AppTheme.errorColor),
                          onPressed: item.productId == null
                              ? null
                              : () => cart.updateQuantity(item.productId!, item.quantity - 1),
                          visualDensity: VisualDensity.compact,
                        ),
                        Text(
                          "${item.quantity}",
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                        ),
                        IconButton(
                          icon: Icon(Icons.add_rounded, size: 14, color: Theme.of(context).primaryColor),
                          onPressed: item.productId == null
                              ? null
                              : () {
                                  final inventory = context.read<InventoryProvider>();
                                  final prod = inventory.products.cast<Product?>().firstWhere(
                                    (p) => p?.id == item.productId,
                                    orElse: () => null,
                                  );
                                  final maxStock = prod?.stock ?? 9999;
                                  final updated = cart.updateQuantity(
                                    item.productId!,
                                    item.quantity + 1,
                                    maxStock: maxStock,
                                  );
                                  if (!updated) {
                                    ShadSonner.of(context).show(
                                      ShadToast.destructive(
                                        title: const Text('Stok tidak mencukupi'),
                                        description: Text('Stok produk "${item.productName}" sudah maksimal ($maxStock).'),
                                      ),
                                    );
                                  }
                                },
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: AppTheme.errorColor.withValues(alpha: 0.8),
                    ),
                    onPressed: item.productId == null
                        ? null
                        : () {
                            cart.removeProduct(item.productId!);
                            _barcodeFocus.requestFocus();
                          },
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack);
          },
        ),
      ),
    ],
  );
      },
    );
  }

  Widget _buildCartFooter(double maxHeight) {
    bool isShort = maxHeight < 700;
    final theme = Theme.of(context);
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        final currencyFormatter = NumberFormat.currency(
          locale: 'id',
          symbol: 'Rp',
          decimalDigits: 0,
        );

        return Container(
          padding: EdgeInsets.all(isShort ? 20 : 32),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(isShort ? AppTheme.radiusLG : AppTheme.radiusXL)),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                blurRadius: 40,
                offset: const Offset(0, -15),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFooterRow("Subtotal", currencyFormatter.format(cart.subtotal), isShort),
              const SizedBox(height: 10),
              _buildFooterRow("Diskon Member", "-${currencyFormatter.format(cart.memberDiscount)}", isShort, isDiscount: true),
              const SizedBox(height: 10),
              _buildFooterRow("Diskon Item", "-${currencyFormatter.format(cart.itemDiscount)}", isShort, isDiscount: true),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Divider(height: 1, color: theme.colorScheme.outline.withValues(alpha: 0.1)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Tagihan Total",
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        "Inc. PPN 11%",
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                  Text(
                    currencyFormatter.format(cart.total),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 32,
                      color: theme.primaryColor,
                      letterSpacing: -2,
                    ),
                  ),
                ],
              ).animate(target: cart.total > 0 ? 1 : 0).shimmer(duration: 1.seconds, color: theme.primaryColor.withValues(alpha: 0.2)),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: isShort ? 54 : 64,
                child: ShadButton(
                  onPressed: cart.items.isEmpty ? null : () => _showPaymentModal(context, cart),
                  decoration: ShadDecoration(
                    border: ShadBorder.all(
                      radius: BorderRadius.circular(100),
                      width: 0,
                      color: Colors.transparent,
                    ),
                    shadows: cart.items.isNotEmpty ? AppTheme.glowShadow(theme.primaryColor) : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.flash_on_rounded, size: 20, color: Colors.white),
                      const SizedBox(width: 12),
                      Text(
                        "PROSES PEMBAYARAN",
                        style: TextStyle(
                          fontSize: isShort ? 13 : 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate(target: cart.items.isNotEmpty ? 1 : 0).scale(begin: const Offset(0.98, 0.98), curve: Curves.easeOutBack),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooterRow(String label, String value, bool isShort, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            fontSize: isShort ? 11 : 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isDiscount ? AppTheme.errorColor : Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: isShort ? 11 : 12,
          ),
        ),
      ],
    );
  }

  void _showItemDiscountDialog(BuildContext context, CartProvider cart, dynamic item) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final TextEditingController controller = TextEditingController(text: item.discount.toInt().toString());

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMD)),
        child: Container(
          padding: const EdgeInsets.all(32),
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppBadge(label: "DISKON ITEM", color: AppTheme.errorColor),
                      const SizedBox(height: 12),
                      Text(
                        "Atur Potongan",
                        style: TextStyle(
                          fontSize: 24, 
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -1,
                        ),
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
              Text(
                item.productName ?? '', 
                style: TextStyle(
                  fontWeight: FontWeight.w800, 
                  fontSize: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                )
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                decoration: InputDecoration(
                  hintText: "0",
                  prefixIcon: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text("Rp ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                  fillColor: isDark ? AppTheme.slate900 : AppTheme.slate50,
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
                    child: ShadButton(
                      onPressed: () {
                        final discount = double.tryParse(controller.text) ?? 0;
                        cart.updateItemDiscount(item.productId, discount);
                        Navigator.pop(context);
                      },
                      child: const Text("SIMPAN", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
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

  void _showPaymentModal(BuildContext context, CartProvider cart) {
    showModalEffect(
      context,
      Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: const PaymentModal(),
      ),
    );
  }

  void showModalEffect(BuildContext context, Widget child) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => child,
      transitionBuilder: (context, anim1, anim2, child) {
        final curveValue = Curves.easeInOutBack.transform(anim1.value);
        return Transform.scale(
          scale: 0.8 + (curveValue * 0.2),
          child: Opacity(
            opacity: anim1.value,
            child: child,
          ),
        );
      },
    );
  }

  void _showClearCartConfirmationDialog(BuildContext context, CartProvider cart) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Hapus Semua Pesanan?',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text('Apakah Anda yakin ingin menghapus seluruh produk dari keranjang belanja ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            onPressed: () {
              cart.clearCart();
              Navigator.of(context).pop();
              _barcodeFocus.requestFocus();
            },
            child: const Text('Hapus Semua', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class _ProductGridItem extends StatefulWidget {
  final dynamic product;
  final int index;
  final NumberFormat currencyFormatter;
  final VoidCallback onTap;

  const _ProductGridItem({
    required this.product,
    required this.index,
    required this.currencyFormatter,
    required this.onTap,
  });

  @override
  State<_ProductGridItem> createState() => _ProductGridItemState();
}

class _ProductGridItemState extends State<_ProductGridItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stock = widget.product.stock ?? 0;
    final isOut = stock <= 0;
    final hasImage = isLocalFileValid(widget.product.imagePath);
    final productName = widget.product.name?.toString().isNotEmpty == true ? widget.product.name.toString() : 'Tanpa Nama';
    final productPrice = (widget.product.price is num) ? (widget.product.price as num).toDouble() : 0.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _isHovered ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            border: Border.all(
              color: _isHovered 
                  ? theme.primaryColor.withValues(alpha: 0.5)
                  : (isOut ? theme.colorScheme.error.withValues(alpha: 0.1) : theme.colorScheme.outline.withValues(alpha: 0.1)),
              width: _isHovered ? 2 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            child: InkWell(
              onTap: widget.onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
                          ),
                          child: hasImage
                              ? Image.file(
                                  File(widget.product.imagePath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Center(
                                    child: Icon(
                                      Icons.image_not_supported_rounded,
                                      size: 44,
                                      color: theme.primaryColor.withValues(alpha: 0.1),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Icon(
                                    Icons.image_not_supported_rounded,
                                    size: 44,
                                    color: theme.primaryColor.withValues(alpha: 0.1),
                                  ),
                                ),
                        ),
                        if (isOut)
                          Container(
                            color: Colors.black.withValues(alpha: 0.4),
                            child: const Center(
                              child: Text(
                                "HABIS",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (isOut ? theme.colorScheme.error : theme.primaryColor).withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              "$stock",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          productName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.currencyFormatter.format(productPrice),
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate(delay: (widget.index * 50).ms).fadeIn().slideY(begin: 0.05);
  }
}

class _ProductListItem extends StatefulWidget {
  final dynamic product;
  final int index;
  final NumberFormat currencyFormatter;
  final VoidCallback onTap;

  const _ProductListItem({
    required this.product,
    required this.index,
    required this.currencyFormatter,
    required this.onTap,
  });

  @override
  State<_ProductListItem> createState() => _ProductListItemState();
}

class _ProductListItemState extends State<_ProductListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stock = widget.product.stock ?? 0;
    final isOut = stock <= 0;
    final hasImage = isLocalFileValid(widget.product.imagePath);
    final productName = widget.product.name?.toString().isNotEmpty == true ? widget.product.name.toString() : 'Tanpa Nama';
    final productPrice = (widget.product.price is num) ? (widget.product.price as num).toDouble() : 0.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _isHovered ? 1.01 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            border: Border.all(
              color: _isHovered 
                  ? theme.primaryColor.withValues(alpha: 0.5)
                  : (isOut ? theme.colorScheme.error.withValues(alpha: 0.1) : theme.colorScheme.outline.withValues(alpha: 0.1)),
              width: _isHovered ? 2 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            child: InkWell(
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: hasImage
                          ? Image.file(
                              File(widget.product.imagePath!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.inventory_2_rounded,
                                color: theme.primaryColor.withValues(alpha: 0.2),
                              ),
                            )
                          : Icon(
                              Icons.inventory_2_rounded,
                              color: theme.primaryColor.withValues(alpha: 0.2),
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            productName,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.currencyFormatter.format(productPrice),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: theme.primaryColor,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isOut 
                              ? theme.colorScheme.error.withValues(alpha: 0.1)
                              : theme.primaryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            isOut ? "HABIS" : "$stock Stok",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: isOut ? theme.colorScheme.error : theme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ).animate(delay: (widget.index * 50).ms).fadeIn().slideX(begin: 0.05);
  }
}

class _HoverToggleBtn extends StatefulWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _HoverToggleBtn({required this.icon, required this.isActive, required this.onTap});

  @override
  State<_HoverToggleBtn> createState() => _HoverToggleBtnState();
}

class _HoverToggleBtnState extends State<_HoverToggleBtn> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.05 : 1.0,
        duration: AppTheme.fastDuration,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          child: AnimatedContainer(
            duration: AppTheme.fastDuration,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.isActive ? theme.primaryColor : (_isHovered ? theme.primaryColor.withValues(alpha: 0.1) : Colors.transparent),
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
            child: Icon(
              widget.icon,
              size: 20,
              color: widget.isActive ? Colors.white : ( _isHovered ? theme.primaryColor : theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatefulWidget {
  final String cat;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({required this.cat, required this.isSelected, required this.onTap});

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.03 : 1.0,
        duration: AppTheme.fastDuration,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutQuart,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: widget.isSelected ? theme.primaryColor : theme.cardTheme.color,
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              border: Border.all(
                color: widget.isSelected
                    ? Colors.transparent
                    : (_isHovered ? theme.primaryColor.withValues(alpha: 0.5) : theme.colorScheme.outline.withValues(alpha: 0.2)),
                width: widget.isSelected || _isHovered ? 1.5 : 1,
              ),
            ),
            child: Text(
              widget.cat,
              style: TextStyle(
                color: widget.isSelected ? Colors.white : ( _isHovered ? theme.primaryColor : theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}


