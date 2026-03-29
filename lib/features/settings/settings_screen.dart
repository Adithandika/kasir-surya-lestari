import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/license_provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _shopNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _shopNameController.text = context.read<ThemeProvider>().shopName;
    });
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    super.dispose();
  }

  final List<Color> themeColors = const [
    Color(0xFF0EA5E9), // Sky Blue
    Color(0xFF3B82F6), // Royal Blue
    Color(0xFF8B5CF6), // Violet
    Color(0xFFF43F5E), // Rose
    Color(0xFF10B981), // Emerald
    Color(0xFF06B6D4), // Cyan
    Color(0xFFF59E0B), // Amber
    Color(0xFF475569), // Slate
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final license = context.watch<LicenseProvider>();
    final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(
            child: AppHeader(
              badgeLabel: "APPLICATION CONFIG",
              title: "Pengaturan",
              subtitle: "Sesuaikan tampilan dan identitas toko Anda untuk pengalaman yang lebih profesional.",
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.screenPaddingH, 0, AppTheme.screenPaddingH, AppTheme.bottomSafeArea),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 24),
                AppCard(
                  padding: const EdgeInsets.all(32),
                  radius: AppTheme.radiusLG,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const AppInputLabel(label: "Akumulasi Biaya (0,7%)"),
                              const SizedBox(height: 4),
                              Text(
                                "Total yang harus dibayarkan ke pengembang",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            currencyFormatter.format(license.unpaidCommission),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Divider(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.05)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Total Terbayar Sebelumnya",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                          Text(
                            currencyFormatter.format(license.totalCommission - license.unpaidCommission),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.sectionGap),
                const AppSectionTitle(title: "IDENTITAS TOKO"),
                const SizedBox(height: 16),
                AppCard(
                  padding: const EdgeInsets.all(32),
                  radius: AppTheme.radiusLG,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: ShadTheme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.storefront_rounded, size: 20, color: ShadTheme.of(context).colorScheme.primary),
                          ),
                          const SizedBox(width: 12),
                          const AppInputLabel(label: "Nama Bisnis"),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ShadInput(
                        controller: _shopNameController,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        placeholder: const Text("Contoh: Toko Berkah Jaya"),
                        leading: Icon(Icons.edit_note_rounded, color: ShadTheme.of(context).colorScheme.mutedForeground, size: 20),
                        onChanged: (val) => themeProvider.setShopName(val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.sectionGap),
                const AppSectionTitle(title: "TEMA VISUAL"),
                const SizedBox(height: 16),
                AppCard(
                  padding: const EdgeInsets.all(8),
                  radius: 20,
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildThemeToggleBtn(
                          context,
                          label: "Terang",
                          isSelected: themeProvider.themeMode == ThemeMode.light,
                          icon: Icons.light_mode_rounded,
                          onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildThemeToggleBtn(
                          context,
                          label: "Gelap",
                          isSelected: themeProvider.themeMode == ThemeMode.dark,
                          icon: Icons.dark_mode_rounded,
                          onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildThemeToggleBtn(
                          context,
                          label: "Sistem",
                          isSelected: themeProvider.themeMode == ThemeMode.system,
                          icon: Icons.settings_brightness_rounded,
                          onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.sectionGap),
                const AppSectionTitle(title: "TATA LETAK KASIR"),
                const SizedBox(height: 16),
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  radius: AppTheme.radiusLG,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.view_sidebar_rounded, size: 18, color: ShadTheme.of(context).colorScheme.primary),
                          const SizedBox(width: 12),
                          const AppInputLabel(label: "Lebar Area Keranjang"),
                          const Spacer(),
                          Text(
                            "${themeProvider.posCartWidth.round()}px",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: ShadTheme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Slider(
                        value: themeProvider.posCartWidth.clamp(280, 800),
                        min: 280,
                        max: 800,
                        divisions: 26, // (800-280)/20 = 26 steps of ~20px
                        activeColor: ShadTheme.of(context).colorScheme.primary,
                        inactiveColor: ShadTheme.of(context).colorScheme.muted,
                        onChanged: (val) => themeProvider.setPosCartWidth(val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.sectionGap),
                const AppSectionTitle(title: "AKSEN WARNA UTAMA"),
                const SizedBox(height: 16),
                AppCard(
                  padding: const EdgeInsets.all(32),
                  radius: AppTheme.radiusLG,
                  child: Center(
                    child: Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      alignment: WrapAlignment.center,
                      children: themeColors.map((color) {
                        final isSelected = themeProvider.primaryColor.toARGB32() == color.toARGB32();
                        return GestureDetector(
                          onTap: () => themeProvider.setPrimaryColor(color),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedContainer(
                                duration: 400.ms,
                                curve: Curves.easeOutBack,
                                width: isSelected ? 56 : 48,
                                height: isSelected ? 56 : 48,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_rounded, color: Colors.white, size: 24)
                                    .animate()
                                    .scale(duration: 300.ms, curve: Curves.elasticOut),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 64),
                Center(
                  child: Column(
                    children: [
                      Text(
                        "Cashierya POS",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Versi 1.1.0 • Built with Passion",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeToggleBtn(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final primary = ShadTheme.of(context).colorScheme.primary;
    final primaryFg = ShadTheme.of(context).colorScheme.primaryForeground;
    
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: 300.ms,
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? primaryFg : ShadTheme.of(context).colorScheme.mutedForeground,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: isSelected ? primaryFg : ShadTheme.of(context).colorScheme.mutedForeground,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
