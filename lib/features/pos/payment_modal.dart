import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/order.dart';
import '../../providers/cart_provider.dart';
import '../../providers/license_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/member_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/printer_service.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

class PaymentModalProvider with ChangeNotifier {
  double cashReceived = 0;
  bool printReceipt = true;
  String paymentMethod = 'Cash';

  void addCash(double amount) {
    if (paymentMethod == 'QRIS') return;
    cashReceived += amount;
    notifyListeners();
  }

  void exactCash(double total) {
    cashReceived = total;
    notifyListeners();
  }

  void setCash(double amount) {
    cashReceived = amount;
    notifyListeners();
  }

  void clearCash() {
    cashReceived = 0;
    notifyListeners();
  }

  void togglePrintReceipt(bool value) {
    printReceipt = value;
    notifyListeners();
  }

  void setPaymentMethod(String method, double total) {
    paymentMethod = method;
    if (method == 'QRIS') {
      cashReceived = total;
    }
    notifyListeners();
  }
}

class PaymentModal extends StatelessWidget {
  const PaymentModal({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PaymentModalProvider(),
      child: const _PaymentModalContent(),
    );
  }
}

class _PaymentModalContent extends StatefulWidget {
  const _PaymentModalContent();

  @override
  State<_PaymentModalContent> createState() => _PaymentModalContentState();
}

class _PaymentModalContentState extends State<_PaymentModalContent> {
  final TextEditingController _cashController = TextEditingController();

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  void _processPayment(
    double total,
    double cashReceived,
    bool printReceipt,
  ) async {
    if (cashReceived < total) {
      if (!mounted) return;
      ShadSonner.of(context).show(
        const ShadToast.destructive(
          title: Text('Uang tidak cukup!'),
        ),
      );
      return;
    }

    final cart = context.read<CartProvider>();
    final inventory = context.read<InventoryProvider>();
    final memberProvider = context.read<MemberProvider>();
    final license = context.read<LicenseProvider>();
    final dashboard = context.read<DashboardProvider>();

    double change = cashReceived - total;

    // Add Commission (0.7%)
    license.addCommission(total);

    final themeProvider = context.read<ThemeProvider>();

    // Process stock reduction
    for (var item in cart.items) {
      if (item.productId != null) {
        inventory.reduceStock(item.productId!, item.quantity);
      }
    }

    // Save Order History
    final order = OrderModel(
      items: List.from(cart.items),
      total: total,
      subtotal: cart.subtotal,
      globalDiscount: cart.globalDiscount,
      memberId: cart.selectedMember?.id,
      memberName: cart.selectedMember?.name,
      cashReceived: cashReceived,
      change: change,
      paymentMethod: context.read<PaymentModalProvider>().paymentMethod,
      date: DateTime.now(),
      totalProfit: cart.totalProfit,
    );
    await dashboard.addOrder(order);

    // Update Member Points (1 point for every 10.000 spent)
    if (cart.selectedMember != null) {
      int pointsToAdd = (total / 10000).floor();
      if (pointsToAdd > 0) {
        memberProvider.addPoints(cart.selectedMember!.id, pointsToAdd);
      }
    }

    // Hardware Trigger
    final printerService = PrinterService(
      connectionType: themeProvider.printerConnectionType,
      printerName: themeProvider.printerName,
      ipAddress: themeProvider.printerIp,
      port: themeProvider.printerPort,
      paperSize: themeProvider.printerPaperSize == '58mm' ? PaperSize.mm58 : PaperSize.mm80,
      shopName: themeProvider.shopName,
      shopAddress: themeProvider.shopAddress,
      shopPhone: themeProvider.shopPhone,
      cashierName: themeProvider.cashierName,
    );

    if (printReceipt) {
      printerService.printReceiptAndOpenDrawer(
        order.items,
        order.subtotal,
        order.globalDiscount,
        total,
        cashReceived,
        change,
        memberName: order.memberName,
        openDrawer: true,
        orderId: order.id,
        transactionDate: order.date,
      );
    } else {
      printerService.openCashDrawer();
    }

    // Clear Cart & Close
    cart.clearCart();

    // Show success & change
    final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0);

    if (!mounted) return;
    Navigator.of(context).pop(); // Close Payment Modal

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLG)),
        child: Container(
          padding: const EdgeInsets.all(40),
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppTheme.successColor, size: 64),
              ),
              const SizedBox(height: 32),
              Text(
                "Pembayaran Berhasil!",
                style: TextStyle(
                  fontSize: 28, 
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Transaksi telah selesai dan disimpan",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.05)),
                ),
                child: Column(
                  children: [
                    Text(
                      "KEMBALIAN",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currencyFormatter.format(change),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).primaryColor,
                        letterSpacing: -1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              ShadButton(
                onPressed: () => Navigator.of(context).pop(),
                width: double.infinity,
                size: ShadButtonSize.lg,
                child: const Text(
                  "PESANAN BARU",
                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final paymentState = context.watch<PaymentModalProvider>();

    final total = cart.total;
    final change = paymentState.cashReceived - total;
    final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ShadCard(
        width: 550,
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.surface,
                      Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1))),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient(Theme.of(context).primaryColor),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                        boxShadow: AppTheme.glowShadow(Theme.of(context).primaryColor),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Pembayaran",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.onSurface,
                            letterSpacing: -1,
                          ),
                        ),
                        Text(
                          "Selesaikan transaksi pesanan",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    ShadButton.ghost(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Amount Due Display
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                          border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "TOTAL TAGIHAN",
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor.withValues(alpha: 0.6),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Nominal harus dibayar",
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              currencyFormatter.format(total),
                              style: TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.w900,
                                color: Theme.of(context).primaryColor,
                                letterSpacing: -1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Member Info in Payment Modal
                      if (cart.selectedMember != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: ShadTheme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                            border: Border.all(color: ShadTheme.of(context).colorScheme.primary.withValues(alpha: 0.1)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.person_rounded, color: ShadTheme.of(context).colorScheme.primary, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                "Customer: ${cart.selectedMember!.name}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: ShadTheme.of(context).colorScheme.foreground,
                                ),
                               ),
                              const Spacer(),
                              Text(
                                "${cart.selectedMember!.points} Points",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: ShadTheme.of(context).colorScheme.primary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (cart.selectedMember != null) const SizedBox(height: 32),

                      // Payment Method Selector
                      const Text(
                        "METODE PEMBAYARAN",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textLight,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildPaymentMethodBtn(
                              icon: Icons.money_rounded,
                              label: "Tunai",
                              isSelected: paymentState.paymentMethod == 'Cash',
                              onTap: () => paymentState.setPaymentMethod('Cash', total),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildPaymentMethodBtn(
                              icon: Icons.qr_code_scanner_rounded,
                              label: "QRIS",
                              isSelected: paymentState.paymentMethod == 'QRIS',
                              onTap: () {
                                paymentState.setPaymentMethod('QRIS', total);
                                _cashController.text = total.toInt().toString();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Cash Input Section
                      const Text(
                        "UANG TUNAI DITERIMA",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textLight,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      IgnorePointer(
                        ignoring: paymentState.paymentMethod == 'QRIS',
                        child: Opacity(
                          opacity: paymentState.paymentMethod == 'QRIS' ? 0.5 : 1.0,
                          child: ShadInput(
                            controller: _cashController,
                            keyboardType: TextInputType.number,
                            autofocus: true,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            decoration: ShadDecoration(
                              border: ShadBorder.all(
                                radius: BorderRadius.circular(AppTheme.radiusMD),
                                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                width: 2,
                              ),
                              focusedBorder: ShadBorder.all(
                                radius: BorderRadius.circular(AppTheme.radiusMD),
                                color: Theme.of(context).primaryColor,
                                width: 2,
                              ),
                            ),
                            leading: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text('Rp ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                            ),
                            trailing: ShadButton.ghost(
                              padding: const EdgeInsets.all(12),
                              onPressed: () {
                                paymentState.clearCash();
                                _cashController.clear();
                              },
                              child: Icon(Icons.cancel_rounded, size: 22, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
                            ),
                            onChanged: (val) => paymentState.setCash(double.tryParse(val) ?? 0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Quick Cash Buttons
                      IgnorePointer(
                        ignoring: paymentState.paymentMethod == 'QRIS',
                        child: Opacity(
                          opacity: paymentState.paymentMethod == 'QRIS' ? 0.5 : 1.0,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildQuickCashBtn(context, "Uang Pas", () {
                                  paymentState.exactCash(total);
                                  _cashController.text = paymentState.cashReceived
                                      .toInt()
                                      .toString();
                                }, isPrimary: true),
                                const SizedBox(width: 12),
                                _buildQuickCashBtn(context, "+ 20rb", () {
                                  paymentState.addCash(20000);
                                  _cashController.text = paymentState.cashReceived
                                      .toInt()
                                      .toString();
                                }),
                                const SizedBox(width: 12),
                                _buildQuickCashBtn(context, "+ 50rb", () {
                                  paymentState.addCash(50000);
                                  _cashController.text = paymentState.cashReceived
                                      .toInt()
                                      .toString();
                                }),
                                const SizedBox(width: 12),
                                _buildQuickCashBtn(context, "+ 100rb", () {
                                  paymentState.addCash(100000);
                                  _cashController.text = paymentState.cashReceived
                                      .toInt()
                                      .toString();
                                }),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Footer Section: Change & Confirm
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "KEMBALIAN",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.textLight,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  change >= 0 ? currencyFormatter.format(change) : "Rp 0",
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: change >= 0 ? AppTheme.successColor : AppTheme.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 32),
                          Row(
                            children: [
                              Text(
                                "Cetak Struk",
                                style: TextStyle(
                                  color: ShadTheme.of(context).colorScheme.mutedForeground,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              ShadSwitch(
                                value: paymentState.printReceipt,
                                onChanged: (val) => paymentState.togglePrintReceipt(val),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Confirm Button
                      ShadButton(
                        onPressed: paymentState.cashReceived >= total
                            ? () => _processPayment(
                                total,
                                paymentState.cashReceived,
                                paymentState.printReceipt,
                              )
                            : null,
                        size: ShadButtonSize.lg,
                        width: double.infinity,
                        decoration: ShadDecoration(
                           border: ShadBorder.all(radius: BorderRadius.circular(100), width: 0, color: Colors.transparent),
                        ),
                        child: const Text(
                          "KONFIRMASI PEMBAYARAN",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.5,
                          ),
                        ),
                      ).animate(target: paymentState.cashReceived >= total ? 1 : 0).shimmer(duration: 1.seconds, color: Colors.white.withValues(alpha: 0.2)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickCashBtn(BuildContext context, String label, VoidCallback onPressed, {bool isPrimary = false}) {
    return ShadButton.outline(
      onPressed: onPressed,
      backgroundColor: isPrimary ? ShadTheme.of(context).colorScheme.primary.withValues(alpha: 0.05) : null,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: isPrimary ? ShadTheme.of(context).colorScheme.primary : ShadTheme.of(context).colorScheme.mutedForeground,
        ),
      ),
    );
  }

  Widget _buildPaymentMethodBtn({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Builder(
      builder: (context) {
        return GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isSelected ? ShadTheme.of(context).colorScheme.primary : ShadTheme.of(context).colorScheme.card,
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              border: Border.all(
                color: isSelected ? ShadTheme.of(context).colorScheme.primary : ShadTheme.of(context).colorScheme.border.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: isSelected
                  ? AppTheme.glowShadow(ShadTheme.of(context).colorScheme.primary)
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: isSelected ? ShadTheme.of(context).colorScheme.primaryForeground : ShadTheme.of(context).colorScheme.mutedForeground, size: 24),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? ShadTheme.of(context).colorScheme.primaryForeground : ShadTheme.of(context).colorScheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}
