import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/reports_provider.dart';
import '../../models/order.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_widgets.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0);
  final dateFormatter = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Refresh data when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ReportsProvider>().refresh();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          AppHeader(
            badgeLabel: "INSIGHTS BI",
            title: "Analisis Laporan",
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.screenPaddingH, AppTheme.contentPaddingTop, AppTheme.screenPaddingH, 0),
            child: _buildTabToggle().animate().fadeIn(delay: 200.ms),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _ReportContentView(type: 'Mingguan'),
                _ReportContentView(type: 'Bulanan'),
                _ReportContentView(type: 'Tahunan'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabToggle() {
    return Container(
      height: 48,
      width: 300,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.05),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: false,
        indicator: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 1),
        dividerColor: Colors.transparent,
        labelPadding: EdgeInsets.zero,
        tabs: const [
          Tab(text: "MINGGUAN"),
          Tab(text: "BULANAN"),
          Tab(text: "TAHUNAN"),
        ],
      ),
    );
  }
}

class _ReportContentView extends StatelessWidget {
  final String type;
  const _ReportContentView({required this.type});

  @override
  Widget build(BuildContext context) {
    final reports = context.watch<ReportsProvider>();
    final List<OrderModel> orders;
    
    if (type == 'Mingguan') {
      orders = reports.weeklyOrders;
    } else if (type == 'Bulanan') {
      orders = reports.monthlyOrders;
    } else {
      orders = reports.yearlyOrders;
    }

    final totalSales = reports.calculateTotalSales(orders);
    final totalProfit = reports.calculateTotalProfit(orders);
    final totalTransactions = reports.calculateTotalTransactions(orders);
    final avgTransaction = reports.calculateAverageTransaction(orders);

    final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0);

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isNarrow = constraints.maxWidth < 1000;
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.screenPaddingH),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildStatsGrid(context, totalSales, totalProfit, totalTransactions, avgTransaction, currencyFormatter),
                    const SizedBox(height: 40),
                    _buildChartsSection(context, reports, orders, type, isNarrow),
                    const SizedBox(height: 48),
                    if (isNarrow)
                      Column(
                        children: [
                          _buildTopProductsSection(context, reports, orders),
                          const SizedBox(height: 24),
                          _buildCategoryDistributionSection(context, reports, orders, currencyFormatter),
                        ],
                      )
                    else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildTopProductsSection(context, reports, orders),
                          ),
                          const SizedBox(width: 32),
                          Expanded(
                            child: _buildCategoryDistributionSection(context, reports, orders, currencyFormatter),
                          ),
                        ],
                      ),
                    const SizedBox(height: 32),
                    _buildTransactionsTable(context, orders, currencyFormatter),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopProductsSection(BuildContext context, ReportsProvider reports, List<OrderModel> orders) {
    final topProducts = reports.getTopProducts(orders);
    return AppCard(
      padding: const EdgeInsets.all(24),
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.star_rounded, size: 20, color: Theme.of(context).primaryColor),
              ),
              const SizedBox(width: 16),
              Text(
                "Produk Terlaris",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (topProducts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text("Belum ada data produk", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), fontWeight: FontWeight.w600))),
            )
          else
            ...topProducts.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(100), // More premium round icon
                      border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.05)),
                    ),
                    child: Icon(Icons.inventory_2_rounded, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      e.key,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      "${e.value} unit",
                      style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).primaryColor, fontSize: 11),
                    ),
                  ),
                ],
              ),
            )),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1);
  }

  Widget _buildCategoryDistributionSection(BuildContext context, ReportsProvider reports, List<OrderModel> orders, NumberFormat formatter) {
    final distribution = reports.getCategoryDistribution(orders);
    final total = distribution.values.fold(0.0, (a, b) => a + b);

    return AppCard(
      padding: const EdgeInsets.all(24),
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: Icon(Icons.pie_chart_rounded, size: 18, color: AppTheme.accentColor),
              ),
              const SizedBox(width: 12),
              Text(
                "Distribusi Kategori",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (distribution.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text("Belum ada data kategori", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), fontWeight: FontWeight.w600))),
            )
          else
            ...distribution.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                      Text(formatter.format(e.value), style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: total == 0 ? 0 : e.value / total,
                      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                      valueColor: AlwaysStoppedAnimation(Theme.of(context).primaryColor.withValues(alpha: 0.6)),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            )),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1);
  }

  Widget _buildStatsGrid(BuildContext context, double sales, double profit, int trans, double avg, NumberFormat formatter) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 4;
        if (constraints.maxWidth < 600) {
          crossAxisCount = 1;
        } else if (constraints.maxWidth < 1100) {
          crossAxisCount = 2;
        }

        return GridView(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: crossAxisCount == 1 ? 2.8 : 2.2,
          ),
          children: [
            AppStatCard(
              title: "TOTAL PENJUALAN",
              value: formatter.format(sales),
              icon: Icons.payments_rounded,
              gradient: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withValues(alpha: 0.8)],
              index: 0,
              isPremium: true,
            ),
            AppStatCard(
              title: "TOTAL PROFIT",
              value: formatter.format(profit),
              icon: Icons.trending_up_rounded,
              gradient: [AppTheme.successColor, AppTheme.successColor.withValues(alpha: 0.8)],
              index: 1,
              isPremium: true,
            ),
            AppStatCard(
              title: "TRANSAKSI",
              value: trans.toString(),
              icon: Icons.receipt_long_rounded,
              gradient: [AppTheme.warningColor, AppTheme.warningColor.withValues(alpha: 0.8)],
              index: 2,
              isPremium: true,
            ),
            AppStatCard(
              title: "RATA-RATA",
              value: formatter.format(avg),
              icon: Icons.analytics_rounded,
              gradient: const [Color(0xFF64748B), Color(0xFF475569)], // Slate grey instead of Pink
              index: 3,
              isPremium: true,
            ),
          ],
        );
      },
    );
  }

  Widget _buildChartsSection(BuildContext context, ReportsProvider reports, List<OrderModel> orders, String type, bool isNarrow) {
    final dailySales = reports.getDailySales(orders);
    final sortedDates = dailySales.keys.toList()..sort();
    
    if (isNarrow) {
      return Column(
        children: [
          AppCard(
            padding: const EdgeInsets.all(24),
            radius: 32,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Tren Penjualan ($type)", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 32),
                SizedBox(
                  height: 300,
                  child: sortedDates.isEmpty 
                    ? Center(child: Text("Belum ada data grafik", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3))))
                    : LineChart(_getLineChartData(context, dailySales, sortedDates)),
                ),
              ],
            ),
          ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.05),
          const SizedBox(height: 24),
          AppCard(
             padding: const EdgeInsets.all(24),
            radius: 32,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type == 'Tahunan' ? "Profit per Bulan" : "Profit per Hari", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 32),
                SizedBox(
                  height: 300,
                  child: orders.isEmpty 
                    ? Center(child: Text("Belum ada data grafik", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3))))
                    : BarChart(_getBarChartData(context, orders, type)),
                ),
              ],
            ),
          ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.05),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: AppCard(
            padding: const EdgeInsets.all(24),
            radius: 32,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Tren Penjualan ($type)", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 32),
                SizedBox(
                  height: 300,
                  child: sortedDates.isEmpty 
                    ? Center(child: Text("Belum ada data grafik", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3))))
                    : LineChart(_getLineChartData(context, dailySales, sortedDates)),
                ),
              ],
            ),
          ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.05),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: AppCard(
            padding: const EdgeInsets.all(24),
            radius: 32,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type == 'Tahunan' ? "Profit per Bulan" : "Profit per Hari", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 32),
                SizedBox(
                  height: 300,
                  child: orders.isEmpty 
                    ? Center(child: Text("Belum ada data grafik", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3))))
                    : BarChart(_getBarChartData(context, orders, type)),
                ),
              ],
            ),
          ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.05),
        ),
      ],
    );
  }

  Widget _buildTransactionsTable(BuildContext context, List<OrderModel> orders, NumberFormat formatter) {
    final dateFormatter = DateFormat('dd MMM yyyy, HH:mm');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "DETAIL TRANSAKSI TERKAIT",
          style: TextStyle(
            fontSize: 10, 
            fontWeight: FontWeight.w800, 
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            letterSpacing: 1.5,
          ),
        ).animate().fadeIn(delay: 700.ms),
        const SizedBox(height: 20),
        if (orders.isEmpty)
          AppCard(
            padding: const EdgeInsets.all(80),
            radius: 24,
            child: Column(
              children: [
                Icon(Icons.receipt_long_rounded, size: 48, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
                const SizedBox(height: 24),
                Center(child: Text("Tidak ada transaksi untuk periode ini.", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), fontWeight: FontWeight.w700, fontSize: 13))),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: orders.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final order = orders[index];
              return AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                radius: 16,
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          "#${order.id.toString().padLeft(3, '0')}",
                          style: TextStyle(
                            fontWeight: FontWeight.w900, 
                            fontSize: 12,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateFormatter.format(order.date),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text("${order.items.length} Produk", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.w800)),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(order.paymentMethod.toUpperCase(), style: TextStyle(color: AppTheme.accentColor, fontSize: 10, fontWeight: FontWeight.w900)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatter.format(order.total),
                          style: TextStyle(
                            fontWeight: FontWeight.w900, 
                            fontSize: 18, 
                            color: Theme.of(context).colorScheme.onSurface,
                            letterSpacing: -1,
                          ),
                        ),
                        Text(
                          "Total Bayar",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1), size: 22),
                  ],
                ),
              ).animate(delay: (800 + index * 30).ms).fadeIn().slideX(begin: 0.05);
            },
          ),
      ],
    );
  }

  LineChartData _getLineChartData(BuildContext context, Map<DateTime, double> data, List<DateTime> sortedDates) {
    final List<FlSpot> spots = [];
    double maxY = 0;
    for (int i = 0; i < sortedDates.length; i++) {
      final val = data[sortedDates[i]]!;
      spots.add(FlSpot(i.toDouble(), val));
      if (val > maxY) maxY = val;
    }

    maxY = maxY == 0 ? 10000 : maxY * 1.2;
    final interval = (maxY / 5).roundToDouble();

    return LineChartData(
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => Colors.black.withValues(alpha: 0.8),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final date = sortedDates[spot.x.toInt()];
              return LineTooltipItem(
                "${DateFormat('dd MMM').format(date)}\n",
                const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                children: [
                  TextSpan(
                    text: NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0).format(spot.y),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: -0.5),
                  ),
                ],
              );
            }).toList();
          },
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: interval > 0 ? interval : 1000,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 42,
            getTitlesWidget: (value, meta) {
              if (value == 0) return const SizedBox();
              String text = '';
              if (value >= 1000000) {
                text = '${(value / 1000000).toStringAsFixed(1)}M';
              } else if (value >= 1000) {
                text = '${(value / 1000).toStringAsFixed(0)}k';
              } else {
                text = value.toInt().toString();
              }
              return SideTitleWidget(
                meta: meta,
                child: Text(text, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.bold, fontSize: 9)),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < sortedDates.length) {
                if (sortedDates.length > 7 && value.toInt() % 2 != 0) return const SizedBox();
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    DateFormat('dd/MM').format(sortedDates[value.toInt()]),
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.w700, fontSize: 9),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          gradient: LinearGradient(colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.6),
          ]),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
              radius: 3,
              color: Colors.white,
              strokeWidth: 2,
              strokeColor: Theme.of(context).primaryColor,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).primaryColor.withValues(alpha: 0.15),
                Theme.of(context).primaryColor.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ],
      minY: 0,
      maxY: maxY,
    );
  }

  BarChartData _getBarChartData(BuildContext context, List<OrderModel> orders, String type) {
    final Map<int, double> grouped = {};
    if (type == 'Tahunan') {
      for (var o in orders) {
        grouped[o.date.month] = (grouped[o.date.month] ?? 0) + o.totalProfit;
      }
    } else {
      for (var o in orders) {
        grouped[o.date.day] = (grouped[o.date.day] ?? 0) + o.totalProfit;
      }
    }

    double maxBarY = 0;
    final List<BarChartGroupData> groups = [];
    final keys = grouped.keys.toList()..sort();
    
    for (int i = 0; i < keys.length; i++) {
        final val = grouped[keys[i]]!;
        if (val > maxBarY) maxBarY = val;
        groups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: val,
                gradient: LinearGradient(
                  colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withValues(alpha: 0.6)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 14,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          ),
        );
    }

    maxBarY = maxBarY == 0 ? 5000 : maxBarY * 1.2;
    final interval = (maxBarY / 5).roundToDouble();

    return BarChartData(
      maxY: maxBarY,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: interval > 0 ? interval : 1000,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 42,
            getTitlesWidget: (value, meta) {
              if (value == 0) return const SizedBox();
              String text = '';
              if (value >= 1000000) {
                text = '${(value / 1000000).toStringAsFixed(1)}M';
              } else if (value >= 1000) {
                text = '${(value / 1000).toStringAsFixed(0)}k';
              } else {
                text = value.toInt().toString();
              }
              return SideTitleWidget(
                meta: meta,
                child: Text(text, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.bold, fontSize: 9)),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < keys.length) {
                String text = '';
                if (type == 'Tahunan') {
                  final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
                  text = months[keys[index] - 1];
                } else {
                  text = keys[index].toString();
                }
                
                if (keys.length > 10 && index % 2 != 0) return const SizedBox();

                return SideTitleWidget(
                  meta: meta,
                  child: Text(text, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.bold, fontSize: 9)),
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      barGroups: groups,
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => Colors.black.withValues(alpha: 0.8),
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            String label = '';
            if (type == 'Tahunan') {
              final months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
              label = months[keys[group.x.toInt()] - 1];
            } else {
              label = "Tanggal ${keys[group.x.toInt()]}";
            }
            return BarTooltipItem(
              "$label\n",
              const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
              children: [
                TextSpan(
                  text: NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0).format(rod.toY),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: -0.5),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}


