import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import '../pos/pos_screen.dart';
import '../inventory/inventory_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../membership/membership_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final ValueNotifier<int> selectedIndexNotifier = ValueNotifier<int>(0);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> screens = [
      const PosScreen(),
      const InventoryScreen(),
      const DashboardScreen(),
      const ReportsScreen(),
      const MembershipScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        children: [
          // Hyper-Modern Sidebar
          ValueListenableBuilder<int>(
            valueListenable: selectedIndexNotifier,
            builder: (context, selectedIndex, _) {
              return Container(
                width: 90, 
                height: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.backgroundDark : Colors.white,
                  border: Border(
                    right: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    // Logo with Glow
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient(Theme.of(context).primaryColor),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 28),
                    ).animate().scale(curve: Curves.elasticOut, duration: 1.seconds).shimmer(duration: 2.seconds),
                    const SizedBox(height: 54),

                    // Navigation Items
                    Expanded(
                      child: ListView.builder(
                        itemCount: 5,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final items = [
                            _NavItem(Icons.layers_rounded, "Kasir", 0),
                            _NavItem(Icons.inventory_2_rounded, "Stok", 1),
                            _NavItem(Icons.query_stats_rounded, "Data", 2),
                            _NavItem(Icons.summarize_rounded, "Laporan", 3),
                            _NavItem(Icons.face_retouching_natural_rounded, "Member", 4),
                          ];

                          final item = items[index];
                          return _buildNavItem(
                            item.icon,
                            item.label,
                            item.index,
                            selectedIndexNotifier,
                          ).animate(delay: (200 + index * 40).ms).fadeIn().slideY(begin: 0.2);
                        },
                      ),
                    ),

                    // Bottom Settings Item
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: _buildNavItem(
                        Icons.settings_suggest_rounded,
                        "Seting",
                        5,
                        selectedIndexNotifier,
                      ),
                    ).animate(delay: 600.ms).fadeIn(),
                    const SizedBox(height: 32),
                  ],
                ),
              );
            },
          ),
          
          // Main Content Area
          Expanded(
            child: ValueListenableBuilder<int>(
              valueListenable: selectedIndexNotifier,
              builder: (context, index, child) {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  switchInCurve: Curves.easeOutQuart,
                  switchOutCurve: Curves.easeInQuart,
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.02, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey<int>(index),
                    child: screens[index],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    int index,
    ValueNotifier<int> notifier,
  ) {
    return ValueListenableBuilder<int>(
      valueListenable: notifier,
      builder: (context, selectedIndex, child) {
        bool isSelected = selectedIndex == index;
        final theme = Theme.of(context);
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: InkWell(
            onTap: () => notifier.value = index,
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: isSelected 
                    ? theme.primaryColor.withValues(alpha: 0.08) 
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: isSelected 
                    ? Border.all(color: theme.primaryColor.withValues(alpha: 0.1), width: 1)
                    : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    icon,
                    color: isSelected 
                        ? theme.primaryColor 
                        : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    size: 26,
                  ).animate(target: isSelected ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
                  
                  if (isSelected) 
                    Positioned(
                      left: 0,
                      child: Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(4),
                            bottomRight: Radius.circular(4),
                          ),
                        ),
                      ).animate().scaleY(curve: Curves.elasticOut),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final int index;
  _NavItem(this.icon, this.label, this.index);
}
