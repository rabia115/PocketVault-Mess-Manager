import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/food_carousel.dart';

class MemberDashboard extends StatefulWidget {
  const MemberDashboard({super.key});

  @override
  State<MemberDashboard> createState() => _MemberDashboardState();
}

class _MemberDashboardState extends State<MemberDashboard> {
  static const Color primaryGreen = Color(0xFF176B50);
  static const Color darkGreen = Color(0xFF0F4C3A);

  final supabase = Supabase.instance.client;

  String memberName = 'Mess Member';
  String memberEmail = '';
  String roomNumber = '101';
  double pendingDues = 0.0;
  List<Map<String, dynamic>> todayMeals = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadMemberInfo();
  }

  Future<void> loadMemberInfo() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        memberName = user.userMetadata?['full_name'] ?? 'Mess Member';
        memberEmail = user.email ?? '';

        final memberRes = await supabase
            .from('members')
            .select()
            .eq('email', user.email ?? '')
            .maybeSingle();

        if (memberRes != null) {
          roomNumber = memberRes['room_number'] ?? '101';
        }

        final paymentsRes = await supabase
            .from('payments')
            .select('amount, status')
            .eq('status', 'pending');

        pendingDues = paymentsRes.fold<double>(
          0.0,
              (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0),
        );

        final mealsRes = await supabase
            .from('meals')
            .select()
            .order('meal_type')
            .limit(3);

        todayMeals = List<Map<String, dynamic>>.from(mealsRes);
      }
    } catch (_) {}

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> logout(BuildContext context) async {
    try {
      await supabase.auth.signOut();

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
    final bool hasDues = pendingDues > 0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.restaurant, size: 20),
            SizedBox(width: 8),
            Text('PocketVault Mess', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19)),
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
            tooltip: 'Refresh',
            onPressed: loadMemberInfo,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => logout(context),
          ),
        ],
      ),

      drawer: const AppDrawer(role: 'member'),

      body: RefreshIndicator(
        onRefresh: loadMemberInfo,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Member Greeting Banner
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
                      color: primaryGreen.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
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
                          child: Row(
                            children: [
                              const Icon(Icons.meeting_room, color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'ROOM $roomNumber',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'ACTIVE MEMBER',
                            style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: const Icon(Icons.person, color: Colors.white, size: 30),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, $memberName!',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                memberEmail.isNotEmpty ? memberEmail : 'member@pocketvault.com',
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Text(
                      'Track your daily meals, personal payments, and mess expenses.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Payment Dues Status Banner
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: hasDues ? Colors.orange.shade300 : Colors.green.shade300,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (hasDues ? Colors.orange : Colors.green).withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (hasDues ? Colors.orange : Colors.green).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        hasDues ? Icons.warning_amber_rounded : Icons.check_circle,
                        color: hasDues ? Colors.orange.shade800 : Colors.green.shade800,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasDues ? 'Mess Fee Pending' : 'All Dues Cleared!',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: hasDues ? Colors.orange.shade900 : Colors.green.shade900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hasDues
                                ? 'Pending Dues: Rs. ${pendingDues.toStringAsFixed(0)}'
                                : 'Your mess payments are up to date.',
                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: hasDues ? Colors.orange.shade900 : primaryGreen,
                        side: BorderSide(color: hasDues ? Colors.orange.shade400 : primaryGreen),
                      ),
                      onPressed: () => Navigator.pushNamed(context, '/payments'),
                      child: const Text('View Logs'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Food Showcase Wallpaper Carousel
              const Text(
                'Featured Food Special',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E2923),
                ),
              ),

              const SizedBox(height: 12),

              const FoodCarousel(),

              const SizedBox(height: 24),

              // Today's Food Menu Preview Widget
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Today's Mess Schedule",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E2923),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/menu'),
                    child: const Text('Full Menu ->', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              if (todayMeals.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text('No meal schedule loaded for today.', style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                Column(
                  children: todayMeals.map((meal) {
                    final mealType = (meal['meal_type'] ?? 'breakfast').toString();
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: primaryGreen.withValues(alpha: 0.1),
                          child: Icon(
                            mealType == 'breakfast'
                                ? Icons.free_breakfast
                                : mealType == 'lunch'
                                ? Icons.lunch_dining
                                : Icons.dinner_dining,
                            color: primaryGreen,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          mealType.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryGreen),
                        ),
                        subtitle: Text(
                          meal['menu_items'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87),
                        ),
                        trailing: Chip(
                          backgroundColor: Colors.green.shade50,
                          label: const Text('SERVED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                        ),
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 24),

              // Quick Mess Modules Grid with Wallpaper Images
              const Text(
                'My Mess Activities',
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
                    subtitle: 'Weekly timetable & opt-in',
                    icon: Icons.restaurant_menu,
                    color: Colors.orange,
                    badgeText: 'TIMETABLE',
                    imageUrl: 'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?auto=format&fit=crop&w=1000&q=80',
                    onTap: () => Navigator.pushNamed(context, '/menu'),
                  ),
                  DashboardCard(
                    title: 'My Payments',
                    subtitle: 'Receipts & due status',
                    icon: Icons.payments,
                    color: Colors.green,
                    badgeText: 'RECEIPTS',
                    imageUrl: 'https://images.unsplash.com/photo-1580519542036-c47de6196ba5?auto=format&fit=crop&w=1000&q=80',
                    onTap: () => Navigator.pushNamed(context, '/payments'),
                  ),
                  DashboardCard(
                    title: 'Mess Expenses',
                    subtitle: 'Total expenses breakdown',
                    icon: Icons.receipt_long,
                    color: Colors.redAccent,
                    badgeText: 'COST SHARE',
                    imageUrl: 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1000&q=80',
                    onTap: () => Navigator.pushNamed(context, '/expenses'),
                  ),
                  DashboardCard(
                    title: 'My Profile',
                    subtitle: 'Account & password',
                    icon: Icons.person_pin,
                    color: Colors.blue,
                    badgeText: 'PROFILE',
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
}
