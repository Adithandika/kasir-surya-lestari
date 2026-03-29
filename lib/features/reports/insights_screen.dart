import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import '../../providers/dashboard_provider.dart';
import 'chatbot_screen.dart';
import '../../core/widgets/app_widgets.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();
    final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: dashboard.totalTransactions == 0
          ? _buildEmptyState(context)
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: AppHeader(
                    badgeLabel: "Asisten Bisnis",
                    title: "Wawasan Performa",
                    subtitle: "Dihitung berdasarkan riwayat ${dashboard.totalTransactions} transaksi Anda.",
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(28),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const AppSectionTitle(title: "Ringkasan & Saran Performa"),
                      const SizedBox(height: 24),
                      _buildInsightSection(
                        context,
                        title: "Analisis Produk",
                        value: "Produk terlaris: ${dashboard.topSellingProduct}",
                        advice: "Produk ini menyumbang penjualan tertinggi. Pastikan Anda memiliki alat manajemen stok yang baik agar barang ini tidak pernah kosong (out-of-stock).",
                        icon: Icons.trending_up,
                        color: Theme.of(context).primaryColor,
                        delayMs: 200,
                      ),
                      _buildInsightSection(
                        context,
                        title: "Kategori Terlaris",
                        value: "Kategori paling laku: ${dashboard.topCategory}",
                        advice: "Pertimbangkan untuk memberikan porsi ruang displai yang lebih besar untuk kategori ini di toko fisik Anda untuk menarik perhatian lebih banyak pelanggan.",
                        icon: Icons.category_rounded,
                        color: AppTheme.warningColor,
                        delayMs: 300,
                      ),
                      _buildInsightSection(
                        context,
                        title: "Loyalitas Pelanggan",
                        value: "${dashboard.memberTransactionPercentage.toStringAsFixed(0)}% transaksi dari member",
                        advice: dashboard.memberTransactionPercentage < 20
                            ? "Porsi member Anda masih rendah (< 20%). Cobalah membuat promosi khusus atau diskon poin khusus member baru untuk meningkatkan loyalitas."
                            : "Porsi member Anda sudah baik. Pelanggan ini lebih cenderung kembali ke toko Anda. Terus jaga kualitas pelayanan.",
                        icon: Icons.people_alt,
                        color: AppTheme.accentColor,
                        delayMs: 400,
                      ),
                      _buildInsightSection(
                        context,
                        title: "Waktu Tersibuk",
                        value: "Toko paling ramai jam: ${dashboard.busiestHour}",
                        advice: dashboard.busiestHour == 'Belum ada data'
                            ? "Belum ada rekomendasi jam."
                            : "Siapkan staf kasir atau inventaris tambahan pada rentang jam ini agar layanan tetap cepat saat jam sibuk.",
                        icon: Icons.access_time_filled_rounded,
                        color: Colors.orange,
                        delayMs: 500,
                      ),
                      _buildInsightSection(
                        context,
                        title: "Rata-rata Transaksi",
                        value: "Nilai belanja rata-rata: ${currencyFormatter.format(dashboard.averageTransactionValue)}",
                        advice: "Untuk menaikkan angka ini, tawarkan produk pendamping kasir (cross-selling) seperti permen, kantong belanja, atau promo tebus murah.",
                        icon: Icons.receipt_long_rounded,
                        color: AppTheme.successColor,
                        delayMs: 600,
                      ),
                      _buildInsightSection(
                        context,
                        title: "Kesehatan Finansial",
                        value: "Estimasi margin kotor: ${dashboard.profitMarginPercentage.toStringAsFixed(1)}%",
                        advice: dashboard.profitMarginPercentage < 15
                            ? "Margin Anda agak rendah (<15%). Cobalah negosiasi ulang dengan pemasok barang atau sedikit naikkan harga untuk kategori non-pokok."
                            : "Margin Anda terlihat sehat. Pastikan Anda juga memperhitungkan biaya operasional (listrik, gaji staf) untuk mengetahui laba bersih yang sesungguhnya.",
                        icon: Icons.percent_rounded,
                        color: Colors.teal,
                        delayMs: 700,
                      ),
                      const SizedBox(height: 32),
                      const AppSectionTitle(title: "Strategi Pertumbuhan"),
                      const SizedBox(height: 24),
                      _buildInsightSection(
                        context,
                        title: "Promo Diskon",
                        value: "Produk paling lambat laku: ${dashboard.slowestMovingProduct}",
                        advice: dashboard.slowestMovingProduct == 'Belum ada data'
                            ? "Belum ada rekomendasi diskon."
                            : "Berikan diskon khusus (clearance sale) atau tawarkan sebagai bonus untuk produk ini agar stok tidak menumpuk di gudang.",
                        icon: Icons.local_offer_rounded,
                        color: Colors.redAccent,
                        delayMs: 800,
                      ),
                      _buildInsightSection(
                        context,
                        title: "Ide Bundling",
                        value: "Saran kombinasi: ${dashboard.suggestedBundle}",
                        advice: dashboard.suggestedBundle == 'Data transaksi masih kurang' || dashboard.suggestedBundle == 'Belum ada kombinasi yang cocok'
                            ? "Tunggu lebih banyak transaksi untuk melihat pola pembelian kombinasi."
                            : "Buatlah paket hemat (bundle) yang menggabungkan produk terlaris dengan produk lambat laku ini untuk mendongkrak omset keseluruhan.",
                        icon: Icons.inventory_rounded,
                        color: Colors.blueGrey,
                        delayMs: 900,
                      ),
                      _buildInsightSection(
                        context,
                        title: "Promo Hari Ramai",
                        value: "Hari tersibuk: ${dashboard.peakDayOfWeek}",
                        advice: dashboard.peakDayOfWeek == 'Belum ada data'
                            ? "Pantau transaksi beberapa hari lagi untuk mendeteksi keramaian."
                            : "Siapkan Flash Sale atau Event Khusus pada hari ${dashboard.peakDayOfWeek} karena terbukti memiliki trafik pembeli paling tinggi.",
                        icon: Icons.event_available_rounded,
                        color: Colors.blueAccent,
                        delayMs: 1000,
                      ),
                      const SizedBox(height: 48),
                    ]),
                  ),
                ),
              ],
            ),
      floatingActionButton: ShadButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatbotScreen()),
          );
        },
        decoration: ShadDecoration(
          border: ShadBorder.all(radius: BorderRadius.circular(100), width: 0, color: Colors.transparent),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded, size: 20),
            SizedBox(width: 12),
            Text("TANYA KONSULTAN AI", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
          ],
        ),
      ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.5),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            "Belum Ada Data Transaksi",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Wawasan dan saran bisnis akan muncul di sini setelah Anda melakukan penjualan.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 600.ms),
    );
  }

  Widget _buildInsightSection(
    BuildContext context, {
    required String title,
    required String value,
    required String advice,
    required IconData icon,
    required Color color,
    required int delayMs,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: AppCard(
        padding: const EdgeInsets.all(20),
        radius: AppTheme.radiusMD,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        value,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                border: Border(left: BorderSide(color: color, width: 4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      advice,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delayMs.ms).slideY(begin: 0.1);
  }
}
