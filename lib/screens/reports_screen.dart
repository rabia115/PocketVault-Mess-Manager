
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> payments = [];
  List<Map<String, dynamic>> expenses = [];

  bool isLoading = true;
  bool isAdmin = false;

  final Color primaryColor = const Color(0xFF176B50);
  final Color expenseColor = const Color(0xFFE28B35);

  @override
  void initState() {
    super.initState();
    loadReports();
  }

  Future<void> loadReports() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('Please login first.');
      }

      final profile = await supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      if (profile['role'] != 'admin') {
        if (!mounted) return;
        setState(() {
          isAdmin = false;
          isLoading = false;
        });
        return;
      }

      final paymentData = await supabase
          .from('payments')
          .select('amount, status, payment_date');

      final expenseData = await supabase
          .from('expenses')
          .select('amount, expense_date');

      if (!mounted) return;

      setState(() {
        isAdmin = true;
        payments = List<Map<String, dynamic>>.from(paymentData);
        expenses = List<Map<String, dynamic>>.from(expenseData);
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report loading failed: $error')),
      );
    }
  }

  double get totalIncome {
    return payments
        .where((p) => p['status'] == 'paid')
        .fold<double>(
      0.0,
          (total, p) => total + ((p['amount'] as num?)?.toDouble() ?? 0.0),
    );
  }

  double get pendingPayments {
    return payments
        .where((p) => p['status'] == 'pending' || p['status'] == 'overdue')
        .fold<double>(
      0.0,
          (total, p) => total + ((p['amount'] as num?)?.toDouble() ?? 0.0),
    );
  }

  double get totalExpenses {
    return expenses.fold<double>(
      0.0,
          (total, e) => total + ((e['amount'] as num?)?.toDouble() ?? 0.0),
    );
  }

  double get balance {
    final raw = totalIncome - totalExpenses;
    return raw < 0 ? 0.0 : raw;
  }

  String money(double amount) {
    return 'Rs. ${NumberFormat('#,##0.00').format(amount)}';
  }

  DateTime? parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  List<DateTime> get lastSixMonths {
    final now = DateTime.now();

    return List.generate(
      6,
          (index) => DateTime(now.year, now.month - 5 + index, 1),
    );
  }

  double monthlyIncome(DateTime month) {
    return payments
        .where((payment) {
      final date = parseDate(payment['payment_date']);
      if (date == null) return false;

      return (payment['status'] ?? 'paid') == 'paid' &&
          date.year == month.year &&
          date.month == month.month;
    })
        .fold<double>(
      0.0,
          (total, p) => total + ((p['amount'] as num?)?.toDouble() ?? 0.0),
    );
  }

  double monthlyExpenses(DateTime month) {
    return expenses
        .where((expense) {
      final date = parseDate(expense['expense_date']);
      if (date == null) return false;

      return date.year == month.year &&
          date.month == month.month;
    })
        .fold<double>(
      0.0,
          (total, e) => total + ((e['amount'] as num?)?.toDouble() ?? 0.0),
    );
  }

  Widget summaryCard(
      String title,
      double amount,
      IconData icon,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 25),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            money(amount),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMonthlyChart() {
    final months = lastSixMonths;

    double maximum = 0;

    for (final month in months) {
      final income = monthlyIncome(month);
      final expense = monthlyExpenses(month);

      if (income > maximum) maximum = income;
      if (expense > maximum) maximum = expense;
    }

    final double chartMaximum = maximum == 0 ? 100.0 : maximum * 1.25;

    return SizedBox(
      height: 270,
      child: BarChart(
        BarChartData(
          maxY: chartMaximum,
          minY: 0,
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final label = rodIndex == 0 ? 'Income' : 'Expenses';

                return BarTooltipItem(
                  '$label\n${money(rod.toY)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 55,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value == 0
                        ? '0'
                        : NumberFormat.compact().format(value),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();

                  if (index < 0 || index >= months.length) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('MMM').format(months[index]),
                      style: const TextStyle(fontSize: 11),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(months.length, (index) {
            final month = months[index];

            return BarChartGroupData(
              x: index,
              barsSpace: 5,
              barRods: [
                BarChartRodData(
                  toY: monthlyIncome(month),
                  color: primaryColor,
                  width: 11,
                  borderRadius: BorderRadius.circular(4),
                ),
                BarChartRodData(
                  toY: monthlyExpenses(month),
                  color: expenseColor,
                  width: 11,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget chartLegend(String title, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 7),
        Text(title, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget buildPaymentChart() {
    final paid = payments.where((p) => p['status'] == 'paid').length;
    final pending = payments.where((p) => p['status'] == 'pending').length;
    final total = paid + pending;

    return Column(
      children: [
        SizedBox(
          height: 190,
          child: total == 0
              ? const Center(child: Text('No payment records yet.'))
              : PieChart(
            PieChartData(
              centerSpaceRadius: 42,
              sectionsSpace: 4,
              sections: [
                if (paid > 0)
                  PieChartSectionData(
                    value: paid.toDouble(),
                    title: '$paid',
                    color: primaryColor,
                    radius: 55,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (pending > 0)
                  PieChartSectionData(
                    value: pending.toDouble(),
                    title: '$pending',
                    color: expenseColor,
                    radius: 55,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 22,
          children: [
            chartLegend('Paid ($paid)', primaryColor),
            chartLegend('Pending ($pending)', expenseColor),
          ],
        ),
      ],
    );
  }

  Widget sectionCard(String title, Widget child) {
    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reports')),
        body: const Center(
          child: Text('Reports are available to admins only.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              setState(() => isLoading = true);
              loadReports();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadReports,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Financial Overview',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Updated ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 18),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.25,
              children: [
                summaryCard(
                  'Total Income',
                  totalIncome,
                  Icons.account_balance_wallet,
                  primaryColor,
                ),
                summaryCard(
                  'Total Expenses',
                  totalExpenses,
                  Icons.receipt_long,
                  expenseColor,
                ),
                summaryCard(
                  'Pending Payments',
                  pendingPayments,
                  Icons.pending_actions,
                  Colors.orange,
                ),
                summaryCard(
                  'Net Balance',
                  balance,
                  Icons.trending_up,
                  balance >= 0 ? Colors.green : Colors.red,
                ),
              ],
            ),

            sectionCard(
              'Monthly Income vs Expenses',
              Column(
                children: [
                  Wrap(
                    spacing: 20,
                    children: [
                      chartLegend('Income', primaryColor),
                      chartLegend('Expenses', expenseColor),
                    ],
                  ),
                  const SizedBox(height: 18),
                  buildMonthlyChart(),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Comparison of the last six months',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            sectionCard(
              'Payment Status',
              buildPaymentChart(),
            ),

            sectionCard(
              'Financial Summary',
              Column(
                children: [
                  _summaryRow('Total payment records', '${payments.length}'),
                  _summaryRow('Paid payments',
                      '${payments.where((p) => p['status'] == 'paid').length}'),
                  _summaryRow('Pending payments',
                      '${payments.where((p) => p['status'] == 'pending').length}'),
                  _summaryRow('Expense records', '${expenses.length}'),
                  const Divider(height: 24),
                  _summaryRow('Net balance', money(balance), bold: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(
      String title,
      String value, {
        bool bold = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(title)),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
