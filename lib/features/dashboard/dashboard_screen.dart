import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/theme_provider.dart';
import '../reports/insights_screen.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/order_details_dialog.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0);
    final dateFormatter = DateFormat('dd MMM yyyy, HH:mm');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Compact Header
          SliverToBoxAdapter(
            child: AppHeader(
              badgeLabel: DateFormat('EEEE, d MMM').format(DateTime.now()),
              title: themeProvider.shopName,
              subtitle: "Summary Dashboard",
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppTheme.contentPaddingTop)),

          // Main Content
          SliverPadding(
            padding: AppTheme.screenPadding,
            sliver: SliverToBoxAdapter(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 1000;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stat Cards Row
                      _buildStatCards(context, dashboard, currencyFormatter, themeProvider),
                      const SizedBox(height: AppTheme.sectionGap),

                      // Main Two-Column Layout
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: _buildHistorySection(context, dashboard, dateFormatter, currencyFormatter),
                            ),
                            const SizedBox(width: 32),
                            Expanded(
                              flex: 3,
                              child: _buildInsightsPanel(context, dashboard),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _buildHistorySection(context, dashboard, dateFormatter, currencyFormatter),
                            const SizedBox(height: 32),
                            _buildInsightsPanel(context, dashboard),
                          ],
                        ),
                    ],
                  );
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildStatCards(
    BuildContext context,
    DashboardProvider dashboard,
    NumberFormat currencyFormatter,
    ThemeProvider themeProvider,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          _StatData(
            title: "Pendapatan Total",
            value: currencyFormatter.format(dashboard.totalSales),
            icon: Icons.payments_rounded,
            gradient: [themeProvider.primaryColor, AppTheme.accentColor],
          ),
          _StatData(
            title: "Laba Bersih",
            value: currencyFormatter.format(dashboard.totalProfit),
            icon: Icons.auto_graph_rounded,
            gradient: [const Color(0xFF10B981), const Color(0xFF34D399)],
          ),
          _StatData(
            title: "Transaksi",
            value: dashboard.totalTransactions.toString(),
            icon: Icons.confirmation_number_rounded,
            gradient: [const Color(0xFFF59E0B), const Color(0xFFFB923C)],
          ),
          _StatData(
            title: "Rata-rata Transaksi",
            value: currencyFormatter.format(dashboard.averageTransactionValue),
            icon: Icons.analytics_rounded,
            gradient: const [Color(0xFF64748B), Color(0xFF475569)],
          ),
        ];

        int crossAxisCount = 4;
        if (constraints.maxWidth < 650) {
          crossAxisCount = 1;
        } else if (constraints.maxWidth < 1100) {
          crossAxisCount = 2;
        }

        if (crossAxisCount == 1) {
          return Column(
            children: cards
                .asMap()
                .entries
                .map((e) => Padding(
                      padding: EdgeInsets.only(bottom: e.key < cards.length - 1 ? 16 : 0),
                      child: _buildStatCard(context, e.value, e.key),
                    ))
                .toList(),
          );
        }

        if (crossAxisCount == 2) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildStatCard(context, cards[0], 0)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard(context, cards[1], 1)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildStatCard(context, cards[2], 2)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard(context, cards[3], 3)),
                ],
              ),
            ],
          );
        }

        return Row(
          children: cards
              .asMap()
              .entries
              .map((e) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: e.key < cards.length - 1 ? 16 : 0),
                      child: _buildStatCard(context, e.value, e.key),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildStatCard(BuildContext context, _StatData data, int index) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: data.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(data.icon, size: 110, color: Colors.white.withValues(alpha: 0.08)),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(data.icon, color: Colors.white, size: 20),
                ),
                const SizedBox(height: 20),
                Text(
                  data.title.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    data.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: (index * 80).ms).fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildHistorySection(
    BuildContext context,
    DashboardProvider dashboard,
    DateFormat dateFormatter,
    NumberFormat currencyFormatter,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "RIWAYAT TRANSAKSI",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
                letterSpacing: 2,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                "Lihat Semua",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.all(8),
          radius: AppTheme.radiusMD,
          child: dashboard.history.isEmpty
              ? _buildEmptyState(context)
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: dashboard.history.length > 7 ? 7 : dashboard.history.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    indent: 72,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
                  ),
                  itemBuilder: (context, index) {
                    final order = dashboard.history[index];
                    return _buildTransactionItem(context, order, dateFormatter, currencyFormatter, index);
                  },
                ),
        ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.05),
      ],
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    dynamic order,
    DateFormat dateFormatter,
    NumberFormat currencyFormatter,
    int index,
  ) {
    final payMethod = order.paymentMethod.toString().toUpperCase();
    Color methodColor;
    if (payMethod.contains('CASH')) {
      methodColor = AppTheme.successColor;
    } else if (payMethod.contains('QRIS')) {
      methodColor = AppTheme.accentColor;
    } else {
      methodColor = Theme.of(context).primaryColor;
    }

    return InkWell(
      onTap: () => OrderDetailsDialog.show(context, order),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.receipt_rounded, color: Theme.of(context).primaryColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Order #${order.id.toString().padLeft(4, '0')}",
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateFormatter.format(order.date),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormatter.format(order.total),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: methodColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    payMethod,
                    style: TextStyle(
                      color: methodColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (550 + index * 40).ms).slideX(begin: 0.03);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 40),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15)),
          const SizedBox(height: 12),
          Text(
            "Belum ada transaksi",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsPanel(BuildContext context, DashboardProvider dashboard) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "AI BUSINESS INSIGHTS",
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
            letterSpacing: 2,
          ),
        ).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [AppTheme.slate900, AppTheme.slate800]
                  : [Colors.white, AppTheme.slate50],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            border: Border.all(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI Icon + Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.auto_awesome_rounded, color: Theme.of(context).primaryColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Asisten Bisnis AI",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          "Didukung oleh Gemini AI",
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  "Saya telah menganalisis data penjualan Anda. Penjualan meningkat 12% dibandingkan minggu lalu. Ingin saran stok hari ini?",
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.65,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ShadButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InsightsScreen()),
                ),
                width: double.infinity,
                decoration: ShadDecoration(
                  border: ShadBorder.all(
                    radius: BorderRadius.circular(100),
                    width: 0,
                    color: Colors.transparent,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_rounded, size: 16),
                    SizedBox(width: 8),
                    Text(
                      "Tanya Asisten",
                      style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),

        const SizedBox(height: 24),

        // Quick Stats Row
        _buildQuickStatsGrid(context, dashboard),
      ],
    );
  }

  Widget _buildQuickStatsGrid(BuildContext context, DashboardProvider dashboard) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "STATISTIK CEPAT",
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
            letterSpacing: 2,
          ),
        ).animate().fadeIn(delay: 700.ms),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMiniStat(
                context,
                icon: Icons.trending_up_rounded,
                label: "Avg Order",
                value: dashboard.totalTransactions == 0
                    ? "Rp0"
                    : "Rp${(dashboard.totalSales / dashboard.totalTransactions).toStringAsFixed(0)}",
                color: AppTheme.successColor,
                delay: 750,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMiniStat(
                context,
                icon: Icons.percent_rounded,
                label: "Margin",
                value: dashboard.totalSales == 0
                    ? "0%"
                    : "${(dashboard.totalProfit / dashboard.totalSales * 100).toStringAsFixed(1)}%",
                color: AppTheme.accentColor,
                delay: 820,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniStat(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    int delay = 0,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    ).animate(delay: delay.ms).fadeIn().slideY(begin: 0.08);
  }
}

class _StatData {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradient;

  const _StatData({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
  });
}
