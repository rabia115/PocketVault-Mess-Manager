import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final supabase = Supabase.instance.client;

  final amountController = TextEditingController();
  final descriptionController = TextEditingController();

  List<Map<String, dynamic>> payments = [];
  List<Map<String, dynamic>> members = [];

  String userRole = 'member';
  String searchText = '';
  String paymentMethod = 'cash';
  String paymentStatus = 'paid';
  String monthYear = 'March 2025';

  int? selectedMemberId;
  DateTime selectedDate = DateTime.now();

  bool isLoading = true;
  bool isSaving = false;

  final Color primaryColor = const Color(0xFF176B50);

  @override
  void initState() {
    super.initState();
    loadPayments();
  }

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
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

  Future<void> loadPayments() async {
    try {
      final user = supabase.auth.currentUser;

      String role = 'member';
      if (user != null) {
        final profile = await supabase
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .maybeSingle();

        role = profile?['role'] ?? user.userMetadata?['role'] ?? 'member';
      }

      final memberData = await supabase
          .from('members')
          .select('id, full_name, room_number')
          .order('full_name');

      final paymentData = await supabase
          .from('payments')
          .select('*, members(full_name, room_number)')
          .order('payment_date', ascending: false);

      if (!mounted) return;

      setState(() {
        userRole = role;
        members = List<Map<String, dynamic>>.from(memberData);
        payments = List<Map<String, dynamic>>.from(paymentData);
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => isLoading = false);
      showMessage('Unable to load payments: $error');
    }
  }

  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> chooseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (date != null) {
      setState(() => selectedDate = date);
    }
  }

  void clearFields() {
    amountController.clear();
    descriptionController.clear();
    selectedMemberId = null;
    paymentMethod = 'cash';
    paymentStatus = 'paid';
    selectedDate = DateTime.now();
  }

  Future<void> savePayment({int? paymentId}) async {
    final amount = double.tryParse(amountController.text.trim());

    if (selectedMemberId == null) {
      showMessage('Please select a member.', isError: true);
      return;
    }

    if (amount == null || amount <= 0) {
      showMessage('Enter a valid payment amount.', isError: true);
      return;
    }

    setState(() => isSaving = true);

    try {
      final values = {
        'member_id': selectedMemberId,
        'amount': amount,
        'payment_date': '${selectedDate.year}-'
            '${selectedDate.month.toString().padLeft(2, '0')}-'
            '${selectedDate.day.toString().padLeft(2, '0')}',
        'payment_method': paymentMethod,
        'status': paymentStatus,
        'month_year': monthYear,
        'description': descriptionController.text.trim(),
      };

      if (paymentId == null) {
        await supabase.from('payments').insert(values);
        showMessage('Payment recorded successfully.');
      } else {
        await supabase.from('payments').update(values).eq('id', paymentId);
        showMessage('Payment details updated.');
      }

      if (!mounted) return;
      Navigator.pop(context);
      clearFields();
      await loadPayments();
    } catch (error) {
      showMessage('Unable to save payment: $error', isError: true);
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  void openPaymentForm({Map<String, dynamic>? payment}) {
    final paymentId = payment?['id'] as int?;

    selectedMemberId = payment?['member_id'];
    amountController.text = payment?['amount']?.toString() ?? '';
    descriptionController.text = payment?['description'] ?? '';
    paymentMethod = payment?['payment_method'] ?? 'cash';
    paymentStatus = payment?['status'] ?? 'paid';
    monthYear = payment?['month_year'] ?? 'March 2025';

    selectedDate = payment == null
        ? DateTime.now()
        : DateTime.parse(payment['payment_date']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, updateSheet) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                24,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
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
                          payment == null ? 'Record New Payment' : 'Edit Payment',
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    DropdownButtonFormField<int>(
                      initialValue: selectedMemberId,
                      decoration: const InputDecoration(
                        labelText: 'Select Mess Member',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      items: members.map((member) {
                        return DropdownMenuItem<int>(
                          value: member['id'] as int,
                          child: Text('${member['full_name']} (Room ${member['room_number'] ?? 'N/A'})'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        updateSheet(() => selectedMemberId = value);
                      },
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Payment Amount (Rs.)',
                        prefixIcon: Icon(Icons.currency_rupee),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      initialValue: paymentMethod,
                      decoration: const InputDecoration(
                        labelText: 'Payment Method',
                        prefixIcon: Icon(Icons.payment),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('Cash')),
                        DropdownMenuItem(value: 'bank transfer', child: Text('Bank Transfer')),
                        DropdownMenuItem(value: 'online', child: Text('Online / UPI / Easypaisa')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          updateSheet(() => paymentMethod = value);
                        }
                      },
                    ),

                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      initialValue: paymentStatus,
                      decoration: const InputDecoration(
                        labelText: 'Payment Status',
                        prefixIcon: Icon(Icons.info_outline),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'paid', child: Text('Paid')),
                        DropdownMenuItem(value: 'pending', child: Text('Pending')),
                        DropdownMenuItem(value: 'overdue', child: Text('Overdue')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          updateSheet(() => paymentStatus = value);
                        }
                      },
                    ),

                    const SizedBox(height: 14),

                    OutlinedButton.icon(
                      onPressed: () async {
                        await chooseDate();
                        updateSheet(() {});
                      },
                      icon: const Icon(Icons.calendar_month),
                      label: Text('Payment Date: ${formatDate(selectedDate)}'),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Transaction Note / Reference',
                        hintText: 'e.g., Paid via Easypaisa ref #1029',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: primaryColor),
                        onPressed: isSaving ? null : () => savePayment(paymentId: paymentId),
                        child: Text(
                          isSaving
                              ? 'Saving...'
                              : (payment == null ? 'Record Payment' : 'Save Changes'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> deletePayment(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment Record?'),
        content: const Text('Are you sure you want to delete this payment record?'),
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
      await supabase.from('payments').delete().eq('id', id);
      showMessage('Payment record deleted.');
      await loadPayments();
    } catch (error) {
      showMessage('Unable to delete payment: $error', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = userRole == 'admin';

    final filteredPayments = payments.where((payment) {
      final memberName = payment['members']?['full_name']?.toString().toLowerCase() ?? '';
      final room = payment['members']?['room_number']?.toString().toLowerCase() ?? '';
      final status = payment['status']?.toString().toLowerCase() ?? '';

      return memberName.contains(searchText.toLowerCase()) ||
          room.contains(searchText.toLowerCase()) ||
          status.contains(searchText.toLowerCase());
    }).toList();

    final paidTotal = filteredPayments
        .where((p) => p['status'] == 'paid')
        .fold<double>(0, (total, p) => total + ((p['amount'] as num?)?.toDouble() ?? 0.0));

    final pendingTotal = filteredPayments
        .where((p) => p['status'] == 'pending' || p['status'] == 'overdue')
        .fold<double>(0, (total, p) => total + ((p['amount'] as num?)?.toDouble() ?? 0.0));

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Member Payments & Dues' : 'My Mess Payments'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: loadPayments,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
        onPressed: () {
          clearFields();
          openPaymentForm();
        },
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_card),
        label: const Text('Record Payment'),
      )
          : null,

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Summary Banner
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _summaryCard('Total Collected', paidTotal, Colors.green, Icons.check_circle),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _summaryCard('Pending / Dues', pendingTotal, Colors.orange, Icons.warning_amber),
                ),
              ],
            ),
          ),

          // Search Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (value) => setState(() => searchText = value),
              decoration: InputDecoration(
                hintText: 'Search member name, room, or status',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: filteredPayments.isEmpty
                ? const Center(
              child: Text(
                'No payment records found.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
                : RefreshIndicator(
              onRefresh: loadPayments,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                itemCount: filteredPayments.length,
                itemBuilder: (context, index) {
                  final payment = filteredPayments[index];
                  final memberName = payment['members']?['full_name'] ?? 'Member';
                  final roomNumber = payment['members']?['room_number'] ?? 'N/A';

                  final amount = ((payment['amount'] as num?)?.toDouble() ?? 0.0);
                  final status = (payment['status'] ?? 'paid').toString().toLowerCase();
                  final isPaid = status == 'paid';

                  return Card(
                    elevation: 1.5,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: isPaid ? Colors.green.shade50 : Colors.orange.shade50,
                        child: Icon(
                          isPaid ? Icons.check_circle : Icons.pending,
                          color: isPaid ? Colors.green : Colors.orange,
                        ),
                      ),
                      title: Text(
                        memberName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Room $roomNumber • ${payment['payment_method'] ?? 'Cash'}'
                              '\nDate: ${payment['payment_date'] ?? ''}'
                              '${payment['description'] != null && payment['description'].isNotEmpty ? '\nNote: ${payment['description']}' : ''}',
                          style: const TextStyle(height: 1.3),
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Rs. ${amount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isPaid ? primaryColor : Colors.orange.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isPaid ? Colors.green.shade100 : Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isPaid ? Colors.green.shade900 : Colors.orange.shade900,
                              ),
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

  Widget _summaryCard(String title, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Rs. ${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
