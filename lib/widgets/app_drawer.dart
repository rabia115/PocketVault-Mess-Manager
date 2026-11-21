import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';

class AppDrawer extends StatelessWidget {
  final String role;

  const AppDrawer({
    super.key,
    required this.role,
  });

  Future<void> logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();

    if (!context.mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
          (route) => false,
    );
  }

  void openPage(BuildContext context, String route) {
    Navigator.pop(context);
    Navigator.pushNamed(context, route);
  }

  Widget menuItem(
      BuildContext context,
      IconData icon,
      String title,
      String route,
      ) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return ListTile(
      leading: Icon(icon, color: primaryColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: () => openPage(context, route),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final isAdmin = role == 'admin';

    return Drawer(
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (context, currentMode, child) {
          final isDarkMode = currentMode == ThemeMode.dark;
          final primaryColor = Theme.of(context).colorScheme.primary;

          return Column(
            children: [
              // Custom Overflow-Free Drawer Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  18,
                  MediaQuery.of(context).padding.top + 18,
                  18,
                  20,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F4C3A), Color(0xFF176B50)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            color: Color(0xFF176B50),
                            size: 34,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            isDarkMode ? Icons.light_mode : Icons.dark_mode,
                            color: isDarkMode ? Colors.amber : Colors.white,
                            size: 26,
                          ),
                          tooltip: isDarkMode ? 'Switch to Bright Theme' : 'Switch to Dark Theme',
                          onPressed: () {
                            themeNotifier.value = isDarkMode ? ThemeMode.light : ThemeMode.dark;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      user?.userMetadata?['full_name'] ?? (isAdmin ? 'Admin Administrator' : 'PocketVault Member'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.email ?? 'user@pocketvault.com',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable Navigation Menu
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    menuItem(
                      context,
                      Icons.dashboard,
                      'Dashboard',
                      isAdmin ? '/admin' : '/member',
                    ),

                    if (isAdmin)
                      menuItem(
                        context,
                        Icons.people,
                        'Members Management',
                        '/members',
                      ),

                    menuItem(
                      context,
                      Icons.restaurant_menu,
                      'Food Menu & Schedule',
                      '/menu',
                    ),

                    menuItem(
                      context,
                      Icons.payments,
                      'Payments & Dues',
                      '/payments',
                    ),

                    menuItem(
                      context,
                      Icons.receipt_long,
                      'Mess Expenses',
                      '/expenses',
                    ),

                    if (isAdmin)
                      menuItem(
                        context,
                        Icons.analytics,
                        'Reports & Analytics',
                        '/reports',
                      ),

                    menuItem(
                      context,
                      Icons.person,
                      'My Profile',
                      '/profile',
                    ),

                    const Divider(),

                    // Theme Switcher Tile
                    SwitchListTile(
                      secondary: Icon(
                        isDarkMode ? Icons.dark_mode : Icons.light_mode,
                        color: isDarkMode ? Colors.amber : primaryColor,
                      ),
                      title: Text(
                        isDarkMode ? 'Dark Theme' : 'Bright Theme',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Text(
                        isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      value: isDarkMode,
                      activeThumbColor: primaryColor,
                      onChanged: (bool value) {
                        themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
                      },
                    ),

                    const Divider(),

                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                      onTap: () => logout(context),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
