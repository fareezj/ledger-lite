import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerlite/models/expense_model.dart';
import 'package:ledgerlite/features/dashboard/dashboard_provider.dart';
import 'package:ledgerlite/services/pending_expense_service.dart';
import 'package:ledgerlite/widgets/siri_shortcut_setup_widget.dart';
import 'package:fl_chart/fl_chart.dart';

// Method channel for URL scheme handling
const platform = MethodChannel('com.wolf.ledgerlite/url_handler');

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => DashboardPageState();
}

class DashboardPageState extends ConsumerState<DashboardPage>
    with WidgetsBindingObserver {
  static String _lastShortcutData = 'No shortcut data received yet';
  static final ValueNotifier<String> _shortcutNotifier = ValueNotifier(
    _lastShortcutData,
  );

  static WidgetRef? _globalRef;

  final bool _isDialogShowing = false;
  DateTime _lastTap = DateTime(0);

  final colorList = <Color>[
    const Color(0xfffdcb6e),
    const Color(0xff0984e3),
    const Color(0xfffd79a8),
    const Color(0xffe17055),
    const Color(0xff6c5ce7),
  ];

  @override
  void initState() {
    super.initState();
    _globalRef = ref;
    WidgetsBinding.instance.addObserver(this);

    // Load expenses when the page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardNotifierProvider.notifier).loadExpenses();
      _syncSiriExpenses(); // Check for Siri expenses
    });
  }

  // Check for expenses added via Siri
  void _syncSiriExpenses() async {
    const platform = MethodChannel('ledgerlite/siri');
    try {
      final List<dynamic>? siriExpenses = await platform.invokeMethod(
        'getSiriExpenses',
      );
      if (siriExpenses != null && siriExpenses.isNotEmpty) {
        print('Found ${siriExpenses.length} Siri expenses to sync');

        for (final expenseData in siriExpenses) {
          final Map<String, dynamic> data = Map<String, dynamic>.from(
            expenseData,
          );
          final expense = ExpenseModel(
            id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            amount: data['amount'] ?? '0',
            category: data['category'] ?? 'Unknown',
            date: data['date'] ?? DateTime.now().toIso8601String(),
          );

          await ref
              .read(dashboardNotifierProvider.notifier)
              .addExpense(expense);
        }

        // Clear processed expenses
        await platform.invokeMethod('clearSiriExpenses');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Synced ${siriExpenses.length} expenses from Siri!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Error syncing Siri expenses: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Sync pending expenses when app becomes active
    if (state == AppLifecycleState.resumed) {
      _syncPendingExpenses();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 45,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Total Expense Today',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              Text(
                                '\$${dashboardState.totalExpenseToday.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Card(
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 45,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Total Expense This Month',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              Text(
                                '\$${dashboardState.totalExpenseMonth.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 300,
                  child: PieChart(
                    PieChartData(
                      sections: dashboardState.chartData.entries.map((entry) {
                        int index = dashboardState.chartData.keys
                            .toList()
                            .indexOf(entry.key);
                        return PieChartSectionData(
                          value: entry.value,
                          color: colorList[index % colorList.length],
                          title: entry.value.toStringAsFixed(1),
                          radius: MediaQuery.of(context).size.width / 6.4,
                        );
                      }).toList(),
                      centerSpaceRadius: 50,
                      sectionsSpace: 2,
                      pieTouchData: PieTouchData(
                        touchCallback:
                            (FlTouchEvent event, PieTouchResponse? response) {
                              if (DateTime.now()
                                          .difference(_lastTap)
                                          .inMilliseconds >
                                      300 &&
                                  response != null &&
                                  response.touchedSection != null) {
                                _lastTap = DateTime.now();
                                int index = response
                                    .touchedSection!
                                    .touchedSectionIndex;
                                String category = dashboardState.chartData.keys
                                    .elementAt(index);
                                double value = dashboardState.chartData.values
                                    .elementAt(index);
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(category),
                                    content: Text(
                                      'Amount: \$${value.toStringAsFixed(2)}',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                      ),
                    ),
                  ),
                ),
                const SiriShortcutSetupWidget(),
                const SizedBox(height: 20),
                const Text(
                  'Recent Expenses:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 10),
                dashboardState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : dashboardState.expenses.isEmpty
                    ? const Center(
                        child: Text(
                          'No expenses yet. Tap + to add one!',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: dashboardState.expenses.length,
                        itemBuilder: (context, index) {
                          final expense = dashboardState.expenses[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: const Icon(Icons.receipt),
                              title: Text(
                                '\$${double.parse(expense.amount).toStringAsFixed(2)}',
                              ),
                              subtitle: Text(expense.category),
                              trailing: Text(
                                DateTime.parse(
                                  expense.date,
                                ).toString().substring(0, 10),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExpenseDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddExpenseDialog(
    BuildContext context, {
    String? prefilledAmount,
    String? prefilledCategory,
  }) {
    final amountController = TextEditingController(text: prefilledAmount ?? '');
    final categoryController = TextEditingController(
      text: prefilledCategory ?? '',
    );
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Expense'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  hintText: 'e.g., Food, Transport, Shopping',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                final category = categoryController.text.trim();

                if (amount != null && amount > 0 && category.isNotEmpty) {
                  final expense = ExpenseModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    category: category,
                    amount: amount.toString(),
                    date: DateTime.now().toIso8601String(),
                  );

                  await ref
                      .read(dashboardNotifierProvider.notifier)
                      .addExpense(expense);

                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Expense added successfully!'),
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter valid amount and category'),
                    ),
                  );
                }
              },
              child: const Text('Add Expense'),
            ),
          ],
        );
      },
    );
  }

  static void updateShortcutData(String data, ExpenseModel expenseModel) {
    try {
      _lastShortcutData = data;
      _shortcutNotifier.value = data;

      // Add the expense using the provider
      if (_globalRef != null) {
        _globalRef!
            .read(dashboardNotifierProvider.notifier)
            .addExpense(expenseModel);
        print('Successfully added expense via Siri shortcut');
      } else {
        print('Global ref is null, cannot add expense to provider');
      }
    } catch (e) {
      print('Error in updateShortcutData: $e');
    }
  }

  Future<void> _syncPendingExpenses() async {
    try {
      final pendingService = ref.read(pendingExpenseServiceProvider);
      final syncedCount = await pendingService.syncPendingExpenses();

      if (syncedCount > 0) {
        // Refresh the expense list to show newly synced expenses
        ref.read(dashboardNotifierProvider.notifier).loadExpenses();

        // Show a snackbar to inform user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Synced $syncedCount expenses from Siri shortcuts!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
      // Don't show message for no pending expenses to avoid spam
    } catch (e) {
      print('Error syncing pending expenses: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error syncing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
