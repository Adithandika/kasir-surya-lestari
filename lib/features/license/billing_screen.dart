import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import '../../providers/license_provider.dart';

class BillingScreen extends StatelessWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final license = context.watch<LicenseProvider>();
    final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0);
    
    // Get month name of the last activity
    final now = DateTime.now();
    final lastMonth = now.month == 1 ? 12 : now.month - 1;
    final lastMonthName = DateFormat('MMMM', 'id').format(DateTime(now.year, lastMonth));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo/Icon
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.errorColor.withValues(alpha: 0.1),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_person_rounded,
                  color: AppTheme.errorColor,
                  size: 80,
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack).shake(),
              
              const SizedBox(height: 48),

              // Title
              Text(
                "Aplikasi Terkunci",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -1.5,
                ),
              ).animate().fadeIn(delay: 200.ms),
              
              const SizedBox(height: 12),
              
              Text(
                "Masa aktif pemakaian bulan $lastMonthName telah berakhir.\nSilakan lakukan pembayaran biaya pemeliharaan untuk melanjutkan.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 56),

              // Billing Card
              Container(
                width: 450,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                  border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      "TOTAL TAGIHAN (0,7%)",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: theme.primaryColor.withValues(alpha: 0.6),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      currencyFormatter.format(license.unpaidCommission),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -2,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Divider(color: theme.colorScheme.outline.withValues(alpha: 0.05)),
                    const SizedBox(height: 32),
                    
                    // Simple Payment Instruction
                    _buildPaymentStep(
                      context, 
                      icon: Icons.account_balance_rounded,
                      title: "Bank Transfer",
                      subtitle: "BCA 1234567890 a/n Developer",
                    ),
                    const SizedBox(height: 20),
                    _buildPaymentStep(
                      context, 
                      icon: Icons.qr_code_2_rounded,
                      title: "QRIS / E-Wallet",
                      subtitle: "Hubungi admin untuk kode QRIS",
                    ),
                  ],
                ),
              ).animate().slideY(begin: 0.1, duration: 600.ms).fadeIn(),

              const SizedBox(height: 56),

              // Action Buttons
              SizedBox(
                width: 320,
                child: Column(
                  children: [
                    ShadButton(
                      size: ShadButtonSize.lg,
                      width: double.infinity,
                      onPressed: () {
                        // Secret Admin Bypass for testing or manual unlock by dev
                        _showUnlockDialog(context, license);
                      },
                      child: const Text(
                        "KONFIRMASI PEMBAYARAN",
                        style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ShadButton.outline(
                      size: ShadButtonSize.lg,
                      width: double.infinity,
                      onPressed: () {
                        // Should contact dev
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Email: support@cashierya.com")),
                        );
                      },
                      child: const Text("HUBUNGI DUKUNGAN"),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }

  void _showUnlockDialog(BuildContext context, LicenseProvider license) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Manual"),
        content: const Text("Apakah Anda sudah yakin melakukan pembayaran dan ingin mengaktifkan kembali aplikasi?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              license.markAsPaid();
              Navigator.pop(context);
            }, 
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStep(BuildContext context, {required IconData icon, required String title, required String subtitle}) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: theme.primaryColor, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11, 
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
