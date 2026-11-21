import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final supabase = Supabase.instance.client;

  final titleController = TextEditingController();
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();

  List<Map<String, dynamic>> expenses = [];
  int activeMemberCount = 1;

  final List<String> categories = [
    'Food',
    'Grocery',
    'Electricity',
    'Gas',
    'Maintenance',
    'Rent',
    'Staff Salary',
    'Other',
  ];

  String selectedCategory = 'Food';
  String filterCategory = 'All';
  String searchText = '';

  DateTime selectedDate = DateTime.now();

  bool isLoading = true;
  bool isSaving = false;
  bool isAdmin = false;

  final Color primaryColor = const Color(0xFF176B50);

  @override
  void initState() {
    super.initState();
    loadExpenses();
  }

  @override
  void dispose() {
    titleController.dispose();
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

  Future<void> loadExpenses() async {
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

      final membersRes = await supabase.from('members').select('id, status');
      final activeCount = membersRes.where((m) => m['status'] == 'active').length;

      final data = await supabase
          .from('expenses')
          .select()
          .order('expense_date', ascending: false);

      if (!mounted) return;

      setState(() {
        isAdmin = role == 'admin';
        activeMemberCount = activeCount > 0 ? activeCount : 1;
        expenses = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => isLoading = false);
      showMessage('Unable to load expenses: $error');
    }
  }

  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String databaseDate(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
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
    titleController.clear();
    amountController.clear();
    descriptionController.clear();
    selectedCategory = 'Food';
    selectedDate = DateTime.now();
  }

  Future<void> saveExpense({int? expenseId}) async {
    final title = titleController.text.trim();
    final amount = double.tryParse(amountController.text.trim());

    if (title.isEmpty) {
      showMessage('Please enter expense title.', isError: true);
      return;
    }

    if (amount == null || amount <= 0) {
      showMessage('Enter a valid expense amount.', isError: true);
      return;
    }

    setState(() => isSaving = true);

    try {
      final values = {
        'title': title,
        'category': selectedCategory,
        'amount': amount,
        'expense_date': databaseDate(selectedDate),
        'description': descriptionController.text.trim(),
      };

      if (expenseId == null) {
        await supabase.from('expenses').insert(values);
        showMessage('Expense added successfully.');
      } else {
        await supabase
            .from('expenses')
            .update(values)
            .eq('id', expenseId);
        showMessage('Expense updated successfully.');
      }

      if (!mounted) return;

      Navigator.pop(context);
      clearFields();
      await loadExpenses();
    } catch (error) {
      showMessage('Unable to save expense: $error', isError: true);
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  void openExpenseForm({Map<String, dynamic>? expense}) {
    final expenseId = expense?['id'] as int?;

    titleController.text = expense?['title'] ?? '';
    amountController.text = expense?['amount']?.toString() ?? '';
    descriptionController.text = expense?['description'] ?? '';
    selectedCategory = expense?['category'] ?? 'Food';

    selectedDate = expense == null
        ? DateTime.now()
        : DateTime.parse(expense['expense_date']);

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
                          expense == null ? 'Add Mess Expense' : 'Edit Expense',
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

                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Expense Title',
                        hintText: 'e.g., Weekly Rice & Vegetable Grocery',
                        prefixIcon: Icon(Icons.receipt_long),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Amount (Rs.)',
                        prefixIcon: Icon(Icons.currency_rupee),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Expense Category',
                        prefixIcon: Icon(Icons.category),
                        border: OutlineInputBorder(),
                      ),
                      items: categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          updateSheet(() => selectedCategory = value);
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
                      label: Text('Date: ${formatDate(selectedDate)}'),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: descriptionController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Receipt Notes / Details',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: primaryColor),
                        onPressed: isSaving ? null : () => saveExpense(expenseId: expenseId),
                        child: Text(
                          isSaving
                              ? 'Saving...'
                              : (expense == null ? 'Add Mess Expense' : 'Save Changes'),
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

  Future<void> deleteExpense(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense Record?'),
        content: const Text('Are you sure you want to delete this expense entry?'),
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
      await supabase.from('expenses').delete().eq('id', id);
      showMessage('Expense entry deleted.');
      await loadExpenses();
    } catch (error) {
      showMessage('Unable to delete expense: $error', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredExpenses = expenses.where((expense) {
      final title = (expense['title'] ?? '').toString().toLowerCase();
      final category = (expense['category'] ?? '').toString().toLowerCase();

      final matchesSearch = title.contains(searchText.toLowerCase()) ||
          category.contains(searchText.toLowerCase());

      final matchesCategory = filterCategory == 'All' ||
          (expense['category'] ?? '') == filterCategory;

      return matchesSearch && matchesCategory;
    }).toList();

    final totalExpense = filteredExpenses.fold<double>(
      0,
          (total, expense) => total + ((expense['amount'] as num?)?.toDouble() ?? 0.0),
    );

    final perMemberCost = activeMemberCount > 0 ? (totalExpense / activeMemberCount) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mess Expenses'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: loadExpenses,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
        onPressed: () {
          clearFields();
          openExpenseForm();
        },
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      )
          : null,

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Total & Per-Member Expenses Card Banner
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Mess Expense',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rs. ${totalExpense.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text('Cost / Member', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(
                            'Rs. ${perMemberCost.toStringAsFixed(0)}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Calculated for $activeMemberCount active members',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (value) => setState(() => searchText = value),
              decoration: InputDecoration(
                hintText: 'Search expenses...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Category ChoiceChips
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: ['All', ...categories].map((category) {
                final selected = filterCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: selected,
                    selectedColor: primaryColor.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: selected ? primaryColor : Colors.black87,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) {
                      setState(() => filterCategory = category);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: filteredExpenses.isEmpty
                ? const Center(
              child: Text(
                'No expenses found.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
                : RefreshIndicator(
              onRefresh: loadExpenses,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                itemCount: filteredExpenses.length,
                itemBuilder: (context, index) {
                  final expense = filteredExpenses[index];
                  final amount = ((expense['amount'] as num?)?.toDouble() ?? 0.0);

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
                        backgroundColor: const Color(0xFFE1F1E9),
                        child: const Icon(
                          Icons.receipt_long,
                          color: Color(0xFF176B50),
                        ),
                      ),
                      title: Text(
                        expense['title'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Category: ${expense['category'] ?? 'General'}'
                              ' • Date: ${expense['expense_date'] ?? ''}'
                              '${expense['description'] != null && expense['description'].toString().isNotEmpty ? '\n${expense['description']}' : ''}',
                          style: const TextStyle(height: 1.3),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Rs. ${amount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: primaryColor,
                            ),
                          ),
                          if (isAdmin)
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  openExpenseForm(expense: expense);
                                } else if (value == 'delete') {
                                  deleteExpense(expense['id'] as int);
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(value: 'edit', child: Text('Edit')),
                                PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                              ],
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
}
