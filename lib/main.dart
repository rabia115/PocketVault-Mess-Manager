import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/member_dashboard.dart';
import 'screens/members_screen.dart';
import 'screens/food_menu_screen.dart';
import 'screens/payments_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/role_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://buqqvudrvheitdhlkrmj.supabase.co',
    publishableKey: 'sb_publishable_gXsb3RNW_cRrRsk_bwJE_Q_BvBRkeXf',
  );

  runApp(const MessMateApp());
}

class MessMateApp extends StatelessWidget {
  const MessMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    Session? session;
    try {
      session = Supabase.instance.client.auth.currentSession;
    } catch (_) {
      session = null;
    }

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentThemeMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'PocketVault Mess Manager',
          theme: PVTheme.light,
          darkTheme: PVTheme.dark,
          themeMode: currentThemeMode,
          initialRoute: session != null ? '/home' : '/login',
          routes: {
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignupScreen(),
            '/home': (context) => const RoleRouter(),
            '/admin': (context) => const AdminDashboard(),
            '/member': (context) => const MemberDashboard(),
            '/members': (context) => const MembersScreen(),
            '/menu': (context) => const FoodMenuScreen(),
            '/payments': (context) => const PaymentsScreen(),
            '/expenses': (context) => const ExpensesScreen(),
            '/reports': (context) => const ReportsScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/router': (context) => const RoleRouter(),
          },
        );
      },
    );
  }
}
