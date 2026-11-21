import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';
import '../services/drive_backup_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;

  final nameController = TextEditingController();
  final passwordController = TextEditingController();

  String email = '';
  String role = 'member';
  bool isLoading = true;
  bool isSaving = false;
  bool hidePassword = true;
  bool isBackupBusy = false;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> loadProfile() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('Please login first.');
      }

      final data = await supabase
          .from('profiles')
          .select('full_name, email, role')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        nameController.text =
            data?['full_name'] ?? user.userMetadata?['full_name'] ?? '';
        email = user.email ?? data?['email'] ?? '';
        role = data?['role'] ??
            user.userMetadata?['role'] ??
            (user.email == 'admin@pocketvault.com' ? 'admin' : 'member');
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => isLoading = false);
      showMessage('Could not load profile: $error');
    }
  }

  Future<void> updateProfile() async {
    final name = nameController.text.trim();

    if (name.isEmpty) {
      showMessage('Please enter your full name.');
      return;
    }

    setState(() => isSaving = true);

    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('Please login again.');
      }

      await supabase
          .from('profiles')
          .update({'full_name': name}).eq('id', user.id);

      await supabase.auth.updateUser(
        UserAttributes(
          data: {'full_name': name},
        ),
      );

      if (!mounted) return;

      showMessage('Profile updated successfully.');
    } catch (error) {
      showMessage('Profile update failed: $error');
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> updatePassword() async {
    final password = passwordController.text.trim();

    if (password.length < 6) {
      showMessage('Password must contain at least 6 characters.');
      return;
    }

    setState(() => isSaving = true);

    try {
      await supabase.auth.updateUser(
        UserAttributes(password: password),
      );

      if (!mounted) return;

      passwordController.clear();
      showMessage('Password updated successfully.');
    } catch (error) {
      showMessage('Password update failed: $error');
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> backupToGoogleDrive() async {
    setState(() => isBackupBusy = true);
    try {
      final fileName = await DriveBackupService.instance.createBackup();
      if (!mounted) return;
      showMessage('Backup saved to Google Drive: $fileName');
    } catch (error) {
      if (mounted) showMessage('Backup failed: $error');
    } finally {
      if (mounted) setState(() => isBackupBusy = false);
    }
  }

  Future<void> restoreFromGoogleDrive() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restore PocketVault backup?'),
        content: const Text(
          'The latest backup will be merged into your current Supabase data. '
          'Existing rows with matching IDs will be updated; other rows will remain.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => isBackupBusy = true);
    try {
      final fileName = await DriveBackupService.instance.restoreLatestBackup();
      if (!mounted) return;
      showMessage('Restore completed from: $fileName');
    } catch (error) {
      if (mounted) showMessage('Restore failed: $error');
    } finally {
      if (mounted) setState(() => isBackupBusy = false);
    }
  }

  Future<void> logout() async {
    await supabase.auth.signOut();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  Widget inputField({
    required String label,
    required TextEditingController controller,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        suffixIcon: suffix,
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF176B50);
    final isDarkMode = themeNotifier.value == ThemeMode.dark;

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: green,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: green.withValues(alpha: 0.12),
              child: const Icon(
                Icons.person,
                size: 55,
                color: green,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              email,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Chip(
              avatar: Icon(
                role == 'admin' ? Icons.admin_panel_settings : Icons.person,
                color: green,
                size: 18,
              ),
              label: Text(
                role.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: green.withValues(alpha: 0.10),
            ),
          ),
          const SizedBox(height: 24),

          // App Theme Selector Section
          sectionTitle('App Appearance & Theme'),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1A2420) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: green.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(
                  isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: isDarkMode ? Colors.amber : green,
                  size: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDarkMode
                            ? 'Dark Mode Enabled'
                            : 'Bright Mode Enabled',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        isDarkMode
                            ? 'Sleek dark theme for night viewing'
                            : 'Clean bright theme for day viewing',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isDarkMode,
                  activeThumbColor: green,
                  onChanged: (bool val) {
                    setState(() {
                      themeNotifier.value =
                          val ? ThemeMode.dark : ThemeMode.light;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          sectionTitle('Personal Information'),
          inputField(
            label: 'Full Name',
            controller: nameController,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: TextEditingController(text: email),
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Email Address',
              helperText: 'Email changes are managed through authentication.',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: isSaving ? null : updateProfile,
              icon: const Icon(Icons.save),
              label: const Text('Save Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 30),
          const Divider(),
          sectionTitle('Change Password'),
          inputField(
            label: 'New Password',
            controller: passwordController,
            obscure: hidePassword,
            suffix: IconButton(
              onPressed: () {
                setState(() => hidePassword = !hidePassword);
              },
              icon: Icon(
                hidePassword ? Icons.visibility : Icons.visibility_off,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: isSaving ? null : updatePassword,
              icon: const Icon(Icons.lock_reset),
              label: const Text('Update Password'),
            ),
          ),

          const SizedBox(height: 30),
          const Divider(),
          sectionTitle('Google Drive Backup'),
          const Text(
            'Save your PocketVault data to Google Drive or restore the latest backup.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: isBackupBusy ? null : backupToGoogleDrive,
              icon: isBackupBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              label: const Text('Backup to Google Drive'),
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: isBackupBusy ? null : restoreFromGoogleDrive,
              icon: const Icon(Icons.cloud_download_outlined),
              label: const Text('Restore Latest Backup'),
            ),
          ),
          const SizedBox(height: 30),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
            onTap: logout,
          ),
        ],
      ),
    );
  }
}
