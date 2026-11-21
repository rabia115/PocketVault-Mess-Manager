import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme.dart';
import '../services/supabase_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/food_carousel.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  static const Color primaryGreen = Color(0xFF176B50);
  static const Color darkGreen = Color(0xFF0F4C3A);

  Map<String, dynamic> metrics = {
    'totalMembers': 0,
    'activeMembers': 0,
    'totalExpenses': 0.0,
    'totalPayments': 0.0,
    'pendingDues': 0.0,
    'costPerMember': 0.0,
  };

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadMetrics();
  }

  Future<void> loadMetrics() async {
    final data = await SupabaseService.getDashboardMetrics();
    if (!mounted) return;
    setState(() {
      metrics = data;
      isLoading = false;
    });
  }

  Future<void> logout(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();

      if (!context.mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
            (route) => false,
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    final double totalIncome = (metrics['totalPayments'] as double? ?? 0.0);
    final double totalExpenses = (metrics['totalExpenses'] as double? ?? 0.0);
    final double rawBalance = totalIncome - totalExpenses;
    final double netBalance = rawBalance < 0 ? 0.0 : rawBalance;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.shield, size: 20),
            SizedBox(width: 8),
            Text(
              'PocketVault Admin',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (context, mode, child) {
              final isDark = mode == ThemeMode.dark;
              return IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode : Icons.dark_mode,
                  color: isDark ? Colors.amber : Colors.white,
                ),
                tooltip: isDark ? 'Switch to Bright Mode' : 'Switch to Dark Mode',
                onPressed: () {
                  themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Dashboard',
            onPressed: loadMetrics,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => logout(context),
          ),
        ],
      ),

      drawer: const AppDrawer(role: 'admin'),

      body: RefreshIndicator(
        onRefresh: loadMetrics,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Admin Header Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [darkGreen, primaryGreen, Color(0xFF23834A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: primaryGreen.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              CircleAvatar(radius: 4, backgroundColor: Colors.greenAccent),
                              SizedBox(width: 6),
                              Text(
                                'ADMIN CONTROL CENTER',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${metrics['activeMembers']} Active Members',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome, ${user?.userMetadata?['full_name'] ?? 'Mess Administrator'}!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? 'admin@pocketvault.com',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),

                    const SizedBox(height: 20),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _headerStat('Net Vault Balance', 'Rs. ${netBalance.toStringAsFixed(0)}', netBalance >= 0 ? Colors.greenAccent : Colors.redAccent),
                        _headerStat('Per-Member Share', 'Rs. ${(metrics['costPerMember'] as double).toStringAsFixed(0)}', Colors.white),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Food Carousel Showcase Banner
              const Text(
                'Mess Food Showcase',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E2923),
                ),
              ),

              const SizedBox(height: 12),

              const FoodCarousel(),

              const SizedBox(height: 24),

              // KPI Analytics Cards
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Mess Financial KPIs',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E2923),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/reports'),
                    icon: const Icon(Icons.analytics, size: 16, color: primaryGreen),
                    label: const Text('Reports', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _kpiCard(
                      'Active Members',
                      '${metrics['activeMembers']}',
                      'Out of ${metrics['totalMembers']} total',
                      Icons.people_alt,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _kpiCard(
                      'Cost / Member',
                      'Rs. ${(metrics['costPerMember'] as double).toStringAsFixed(0)}',
                      'Monthly estimate',
                      Icons.calculate,
                      Colors.teal,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _kpiCard(
                      'Total Expenses',
                      'Rs. ${(metrics['totalExpenses'] as double).toStringAsFixed(0)}',
                      'Mess operating costs',
                      Icons.receipt_long,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _kpiCard(
                      'Pending Dues',
                      'Rs. ${(metrics['pendingDues'] as double).toStringAsFixed(0)}',
                      'Uncollected payments',
                      Icons.warning_amber_rounded,
                      Colors.redAccent,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 26),

              // Quick Action Bar
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E2923),
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _actionBtn(
                      context,
                      'Add Member',
                      Icons.person_add,
                      Colors.blue,
                          () => Navigator.pushNamed(context, '/members').then((_) => loadMetrics()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _actionBtn(
                      context,
                      'Add Menu',
                      Icons.restaurant_menu,
                      Colors.orange,
                          () => Navigator.pushNamed(context, '/menu'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _actionBtn(
                      context,
                      'Record Payment',
                      Icons.add_card,
                      Colors.green,
                          () => Navigator.pushNamed(context, '/payments').then((_) => loadMetrics()),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 26),

              // Full Management Modules with Background Wallpaper Images
              const Text(
                'Management Modules',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E2923),
                ),
              ),

              const SizedBox(height: 14),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.1,
                children: [
                  DashboardCard(
                    title: 'Food Menu',
                    subtitle: 'Weekly meal timetable',
                    icon: Icons.restaurant_menu,
                    color: Colors.orange,
                    badgeText: 'SCHEDULE',
                    imageUrl: 'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?auto=format&fit=crop&w=1000&q=80',
                    onTap: () => Navigator.pushNamed(context, '/menu'),
                  ),
                  DashboardCard(
                    title: 'Members',
                    subtitle: 'Manage accounts & rooms',
                    icon: Icons.people,
                    color: Colors.blue,
                    badgeText: 'COMMUNITY',
                    imageUrl: 'https://images.unsplash.com/photo-1511632765486-a01980e01a18?auto=format&fit=crop&w=1000&q=80',
                    onTap: () => Navigator.pushNamed(context, '/members').then((_) => loadMetrics()),
                  ),
                  DashboardCard(
                    title: 'Payments',
                    subtitle: 'Collect fees & track dues',
                    icon: Icons.payments,
                    color: Colors.green,
                    badgeText: 'FINANCE',
                    imageUrl: 'https://images.unsplash.com/photo-1580519542036-c47de6196ba5?auto=format&fit=crop&w=1000&q=80',
                    onTap: () => Navigator.pushNamed(context, '/payments').then((_) => loadMetrics()),
                  ),
                  DashboardCard(
                    title: 'Expenses',
                    subtitle: 'Grocery & utility costs',
                    icon: Icons.receipt_long,
                    color: Colors.redAccent,
                    badgeText: 'EXPENSES',
                    imageUrl: 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1000&q=80',
                    onTap: () => Navigator.pushNamed(context, '/expenses').then((_) => loadMetrics()),
                  ),
                  DashboardCard(
                    title: 'Reports',
                    subtitle: 'Charts & analytics',
                    icon: Icons.analytics,
                    color: Colors.purple,
                    badgeText: 'ANALYTICS',
                    imageUrl: 'https://images.unsplash.com/photo-1551836022-d5d88e9218df?auto=format&fit=crop&w=1000&q=80',
                    onTap: () => Navigator.pushNamed(context, '/reports'),
                  ),
                  DashboardCard(
                    title: 'Profile',
                    subtitle: 'Admin settings',
                    icon: Icons.person_pin,
                    color: Colors.teal,
                    badgeText: 'ADMIN',
                    imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=1000&q=80',
                    onTap: () => Navigator.pushNamed(context, '/profile'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _kpiCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Icon(Icons.trending_up, color: color.withValues(alpha: 0.5), size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2C3E35)),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
