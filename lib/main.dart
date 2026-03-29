import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme.dart';
import 'features/shell/main_shell.dart';
import 'providers/inventory_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/member_provider.dart';
import 'providers/reports_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/gemini_provider.dart';
import 'providers/license_provider.dart';
import 'features/license/billing_screen.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id', null);
  await DatabaseService.init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => MemberProvider()),
        ChangeNotifierProvider(create: (_) => ReportsProvider()),
        ChangeNotifierProvider(create: (_) => GeminiProvider()),
        ChangeNotifierProvider(create: (_) => LicenseProvider()),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LicenseProvider>(
      builder: (context, themeProvider, licenseProvider, child) {
        if (!themeProvider.isInitialized || !licenseProvider.isInitialized) {
          return const ShadApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
        }
        
        return ShadApp(
          title: 'Sembako POS',
          themeMode: themeProvider.themeMode,
          theme: AppTheme.shadTheme(themeProvider.primaryColor, false),
          darkTheme: AppTheme.shadTheme(themeProvider.primaryColor, true),
          materialThemeBuilder: (context, theme) => AppTheme.themeData(
            themeProvider.primaryColor, 
            theme.brightness == Brightness.dark,
          ),
          debugShowCheckedModeBanner: false,
          home: licenseProvider.isBlocked 
              ? const BillingScreen() 
              : const MainShell(),
        );
      },
    );
  }
}
