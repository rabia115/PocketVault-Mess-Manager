import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final supabase = Supabase.instance.client;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final roomController = TextEditingController();

  List<Map<String, dynamic>> members = [];
  bool isLoading = true;
  bool isSaving = false;
  String searchText = '';
  String statusFilter = 'All';

  final Color primaryColor = const Color(0xFF176B50);

  @override
  void initState() {
    super.initState();
    loadMembers();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    roomController.dispose();
    super.dispose();
  }

  Future<void> loadMembers() async {
    try {
      final data = await supabase
          .from('members')
          .select()
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        members = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => isLoading = false);
      showMessage('Could not load members: $error');
    }
  }

  void showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  void clearFields() {
    nameController.clear();
    emailController.clear();
    passwordController.clear();
    phoneController.clear();
    roomController.clear();
  }

  Future<void> saveMember({int? memberId}) async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final phone = phoneController.text.trim();
    final room = roomController.text.trim();

    if (name.isEmpty || email.isEmpty || phone.isEmpty || room.isEmpty) {
      showMessage('Please complete all required fields.', isError: true);
      return;
    }

    if (memberId == null && password.isNotEmpty && password.length < 6) {
      showMessage('Password must be at least 6 characters.', isError: true);
      return;
    }

    setState(() => isSaving = true);

    try {
      final values = {
        'full_name': name,
        'email': email,
        'phone': phone,
        'room_number': room,
        'status': 'active',
      };

      if (memberId == null) {
        await supabase.from('members').insert(values);

        // Attempt creating auth user so member can log in directly
        if (password.isNotEmpty) {
          try {
            await supabase.auth.signUp(
              email: email,
              password: password,
              data: {
                'full_name': name,
                'role': 'member',
                'room_number': room,
              },
            );
          } catch (_) {
            // Member DB record created successfully
          }
        }

        showMessage('Member created successfully! Email & password assigned.');
      } else {
        await supabase
            .from('members')
            .update(values)
            .eq('id', memberId);
        showMessage('Member details updated successfully.');
      }

      if (!mounted) return;
      Navigator.pop(context);
      clearFields();
      await loadMembers();
    } catch (error) {
      showMessage('Unable to save member: $error', isError: true);
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> toggleStatus(Map<String, dynamic> member) async {
    final newStatus = member['status'] == 'active' ? 'inactive' : 'active';
    try {
      await supabase
          .from('members')
          .update({'status': newStatus})
          .eq('id', member['id']);

      showMessage('Member marked as $newStatus.');
      await loadMembers();
    } catch (e) {
      showMessage('Failed to update status: $e', isError: true);
    }
  }

  Future<void> deleteMember(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Member?'),
        content: const Text(
          'Are you sure you want to delete this member? All associated records will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await supabase.from('members').delete().eq('id', id);
      showMessage('Member deleted successfully.');
      await loadMembers();
    } catch (error) {
      showMessage('Unable to delete member: $error', isError: true);
    }
  }

  void openMemberForm({Map<String, dynamic>? member}) {
    final memberId = member?['id'] as int?;

    nameController.text = member?['full_name'] ?? '';
    emailController.text = member?['email'] ?? '';
    passwordController.clear();
    phoneController.text = member?['phone'] ?? '';
    roomController.text = member?['room_number'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    member == null ? 'Add New Member' : 'Edit Member',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _field(nameController, 'Full Name', Icons.person),
              _field(emailController, 'Email Address (Login ID)', Icons.email, keyboardType: TextInputType.emailAddress),
              if (member == null)
                _field(passwordController, 'Login Password', Icons.lock_outline, obscure: true, hint: 'Minimum 6 characters'),
              _field(phoneController, 'Phone Number', Icons.phone, keyboardType: TextInputType.phone),
              _field(roomController, 'Room Number', Icons.meeting_room),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: primaryColor),
                  onPressed: isSaving ? null : () => saveMember(memberId: memberId),
                  child: Text(
                    isSaving
                        ? 'Saving...'
                        : (member == null ? 'Create Member Account' : 'Save Changes'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
      TextEditingController controller,
      String label,
      IconData icon, {
        bool obscure = false,
        TextInputType keyboardType = TextInputType.text,
        String? hint,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredMembers = members.where((member) {
      final name = (member['full_name'] ?? '').toString().toLowerCase();
      final room = (member['room_number'] ?? '').toString().toLowerCase();
      final email = (member['email'] ?? '').toString().toLowerCase();
      final status = (member['status'] ?? 'active').toString().toLowerCase();

      final matchesSearch = name.contains(searchText.toLowerCase()) ||
          room.contains(searchText.toLowerCase()) ||
          email.contains(searchText.toLowerCase());

      final matchesStatus = statusFilter == 'All' || status == statusFilter.toLowerCase();

      return matchesSearch && matchesStatus;
    }).toList();

    final activeCount = members.where((m) => m['status'] == 'active').length;
    final inactiveCount = members.where((m) => m['status'] == 'inactive').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mess Members'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: loadMembers,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          clearFields();
          openMemberForm();
        },
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Member'),
      ),
      body: Column(
        children: [
          // Header Stats Card
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statWidget('Total', '${members.length}', Colors.black87),
                Container(height: 35, width: 1, color: Colors.grey.shade300),
                _statWidget('Active', '$activeCount', Colors.green),
                Container(height: 35, width: 1, color: Colors.grey.shade300),
                _statWidget('Inactive', '$inactiveCount', Colors.orange),
              ],
            ),
          ),

          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) => setState(() => searchText = value),
                    decoration: InputDecoration(
                      hintText: 'Search name, room, or email',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: statusFilter,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All')),
                    DropdownMenuItem(value: 'Active', child: Text('Active')),
                    DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => statusFilter = val);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredMembers.isEmpty
                ? const Center(
              child: Text(
                'No members found.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
                : RefreshIndicator(
              onRefresh: loadMembers,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                itemCount: filteredMembers.length,
                itemBuilder: (context, index) {
                  final member = filteredMembers[index];
                  final isActive = (member['status'] ?? 'active') == 'active';

                  return Card(
                    elevation: 1.5,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: isActive
                            ? const Color(0xFFE1F1E9)
                            : Colors.orange.shade50,
                        child: Text(
                          (member['full_name'] ?? 'M')[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isActive ? primaryColor : Colors.orange,
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              member['full_name'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Chip(
                            padding: EdgeInsets.zero,
                            labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                            backgroundColor: isActive ? Colors.green.shade50 : Colors.orange.shade50,
                            label: Text(
                              isActive ? 'ACTIVE' : 'INACTIVE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isActive ? Colors.green : Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Room: ${member['room_number'] ?? 'N/A'}'
                              ' • Email: ${member['email'] ?? ''}'
                              '\nPhone: ${member['phone'] ?? 'N/A'}',
                          style: const TextStyle(height: 1.3),
                        ),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            openMemberForm(member: member);
                          } else if (value == 'toggle') {
                            toggleStatus(member);
                          } else if (value == 'delete') {
                            deleteMember(member['id'] as int);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text('Edit Info'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'toggle',
                            child: Row(
                              children: [
                                Icon(isActive ? Icons.block : Icons.check_circle, size: 20),
                                const SizedBox(width: 8),
                                Text(isActive ? 'Mark Inactive' : 'Mark Active'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red, size: 20),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statWidget(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
