import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerlite/models/expense_model.dart';
import 'package:ledgerlite/features/dashboard/dashboard_provider.dart';
import 'package:ledgerlite/services/pending_expense_service.dart';

// Method channel for URL scheme handling
const platform = MethodChannel('com.wolf.ledgerlit/url_handler');

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

  @override
  void initState() {
    super.initState();
    _globalRef = ref;
    WidgetsBinding.instance.addObserver(this);

    // Load expenses when the page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardNotifierProvider.notifier).loadExpenses();
      _handleInitialUrl(); // Check if app was launched via URL scheme
      _syncSiriExpenses(); // Check for Siri expenses
    });
  }

  // Check if app was launched with URL scheme to add expense
  void _handleInitialUrl() async {
    const platform = MethodChannel('ledgerlite/url');
    try {
      final String? url = await platform.invokeMethod('getInitialUrl');
      if (url != null && url.contains('addexpense')) {
        // Parse URL parameters
        final uri = Uri.parse(url);
        final amount = uri.queryParameters['amount'];
        final category = uri.queryParameters['category'];

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showAddExpenseDialog(
            context,
            prefilledAmount: amount,
            prefilledCategory: category,
          );
        });
      }
    } catch (e) {
      print('Error handling initial URL: $e');
    }
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

  Future<void> _testShortcutMethod() async {
    try {
      // Test the method channel directly
      await PendingExpenseService.platform.invokeMethod('addShortcutExpense', {
        'amount': 99.99,
        'category': 'Test Method Channel',
        'note': 'Direct test from Flutter',
      });

      // Then sync it
      await _syncPendingExpenses();
    } catch (e) {
      print('Test method error: $e');
    }
  }

  Future<void> _testSiriConnection() async {
    try {
      const platform = MethodChannel('com.wolf.ledgerlit/shortcut');

      // Test writing a dummy expense
      await platform.invokeMethod('testWrite');

      // Test reading it back
      final result = await platform.invokeMethod('getPendingExpenses');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'iOS Connection OK. Pending expenses: ${result?.length ?? 0}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('iOS connection test failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('iOS connection failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardNotifierProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ledgerlite - Shortcut Test',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text(
                'Last Siri Shortcut Data:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              ValueListenableBuilder<String>(
                valueListenable: _shortcutNotifier,
                builder: (context, value, child) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'monospace',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Try saying: "Hey Siri, log expense"',
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _syncPendingExpenses,
                      icon: const Icon(Icons.sync),
                      label: const Text('Sync Pending'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _testSiriConnection,
                      icon: const Icon(Icons.bug_report),
                      label: const Text('Test Siri'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const Text(
                'Recent Expenses:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: dashboardState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : dashboardState.expenses.isEmpty
                    ? const Center(
                        child: Text(
                          'No expenses yet. Tap + to add one!',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: dashboardState.expenses.length,
                        itemBuilder: (context, index) {
                          final expense = dashboardState.expenses[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: const Icon(Icons.receipt),
                              title: Text('\$${expense.amount}'),
                              subtitle: Text(
                                '${expense.category} • ${expense.date}',
                              ),
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
              ),
            ],
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
}

void setupShortcutListener() {
  const platform = MethodChannel('com.wolf.ledgerlit/shortcut');

  platform.setMethodCallHandler((call) async {
    try {
      if (call.method == 'logExpense') {
        final args = Map<String, dynamic>.from(call.arguments);
        final amount = args['amount'] as double;
        final category = args['category'] as String;
        final note = args['note'] as String;

        // Display in UI for testing
        final timestamp = DateTime.now().toString().substring(0, 19);
        final displayData =
            '''
        🎤 Siri Shortcut Received at $timestamp:
        💰 Amount: \$${amount.toStringAsFixed(2)}
        📂 Category: $category
        📝 Note: ${note.isEmpty ? '(empty)' : note}
      ''';

        DashboardPageState.updateShortcutData(
          displayData,
          ExpenseModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            category: category,
            amount: amount.toString(),
            date: DateTime.now().toIso8601String(),
          ),
        );

        print('Shortcut data: $amount $category $note');

        // Return success to iOS
        return 'success';
      }
    } catch (e) {
      print('Error in shortcut listener: $e');
      // Return error to iOS but don't crash
      return 'error: $e';
    }

    return null;
  });
}
