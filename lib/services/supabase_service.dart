
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient get client =>
      Supabase.instance.client;

  // LOGIN
  static Future<AuthResponse> signIn(
      String email,
      String password,
      ) async {
    final response = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Login unsuccessful');
    }

    return response;
  }

  // SIGN UP
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
      },
    );

    return response;
  }

  // LOGOUT
  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  // PASSWORD RECOVERY
  static Future<void> resetPassword(
      String email,
      ) async {
    await client.auth.resetPasswordForEmail(email);
  }

  // CURRENT USER
  static User? get currentUser {
    return client.auth.currentUser;
  }

  // USER PROFILE
  static Future<Map<String, dynamic>?> getProfile() async {
    final user = currentUser;

    if (user == null) return null;

    final result = await client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    return result;
  }

  // CURRENT USER ROLE
  static Future<String> getUserRole() async {
    try {
      final user = currentUser;
      if (user == null) return 'member';

      // Default Admin Check
      if (user.email != null && user.email!.toLowerCase() == 'admin@pocketvault.com') {
        return 'admin';
      }

      final String? metaRole = user.userMetadata?['role'];
      if (metaRole != null && metaRole.isNotEmpty) {
        return metaRole;
      }

      final profile = await getProfile().timeout(const Duration(milliseconds: 1200));
      if (profile != null && profile['role'] != null) {
        return profile['role'].toString();
      }
    } catch (_) {
      // Safe fallback if profile fetch fails or times out
    }

    return 'member';
  }

  // CREATE MEMBER WITH AUTH CREDENTIALS (ADMIN)
  static Future<void> createMember({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String roomNumber,
  }) async {
    // 1. Insert into members table
    await client.from('members').insert({
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'room_number': roomNumber,
      'status': 'active',
    });

    // 2. Try creating auth user if password provided
    if (password.isNotEmpty) {
      try {
        await client.auth.signUp(
          email: email,
          password: password,
          data: {
            'full_name': fullName,
            'role': 'member',
            'room_number': roomNumber,
          },
        );
      } catch (e) {
        // If auth user creation needs confirmation or admin rights
      }
    }
  }

  // DASHBOARD METRICS SUMMARY
  static Future<Map<String, dynamic>> getDashboardMetrics() async {
    try {
      final membersRes = await client.from('members').select('id, status').timeout(const Duration(seconds: 2));
      final expensesRes = await client.from('expenses').select('amount').timeout(const Duration(seconds: 2));
      final paymentsRes = await client.from('payments').select('amount, status').timeout(const Duration(seconds: 2));

      final totalMembers = membersRes.length;
      final activeMembers = membersRes.where((m) => m['status'] == 'active').length;

      final totalExpenses = expensesRes.fold<double>(
        0.0, (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0),
      );

      final totalPayments = paymentsRes
          .where((p) => p['status'] == 'paid')
          .fold<double>(0.0, (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0));

      final pendingDues = paymentsRes
          .where((p) => p['status'] == 'pending')
          .fold<double>(0.0, (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0));

      final costPerMember = activeMembers > 0 ? (totalExpenses / activeMembers) : 0.0;

      final rawBalance = totalPayments - totalExpenses;
      final netBalance = rawBalance < 0 ? 0.0 : rawBalance;

      return {
        'totalMembers': totalMembers,
        'activeMembers': activeMembers,
        'totalExpenses': totalExpenses,
        'totalPayments': totalPayments,
        'pendingDues': pendingDues,
        'costPerMember': costPerMember,
        'netBalance': netBalance,
      };
    } catch (e) {
      return {
        'totalMembers': 0,
        'activeMembers': 0,
        'totalExpenses': 0.0,
        'totalPayments': 0.0,
        'pendingDues': 0.0,
        'costPerMember': 0.0,
      };
    }
  }
}
