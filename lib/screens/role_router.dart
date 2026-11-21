
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'admin_dashboard.dart';
import 'member_dashboard.dart';

class RoleRouter extends StatefulWidget {
  const RoleRouter({super.key});

  @override
  State<RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<RoleRouter> {
  late final Future<String> _roleFuture;

  @override
  void initState() {
    super.initState();
    _roleFuture = SupabaseService.getUserRole().timeout(
      const Duration(milliseconds: 1200),
      onTimeout: () => 'member',
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _roleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == 'admin') {
          return const AdminDashboard();
        }

        return const MemberDashboard();
      },
    );
  }
}
