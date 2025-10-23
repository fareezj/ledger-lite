import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerlite/models/expense_model.dart';
import 'package:ledgerlite/features/dashboard/dashboard_provider.dart';
import 'package:ledgerlite/services/pending_expense_service.dart';
import 'package:ledgerlite/widgets/siri_shortcut_setup_dialog.dart';
import 'package:ledgerlite/widgets/expense_form_dialog.dart';
import 'package:ledgerlite/widgets/text_widgets.dart';
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
  int currentMonth = DateTime.now().month;
  int currentYear = DateTime.now().year;
  DateTime _lastTap = DateTime(0);

  // Generate random colors for categories with better saturation and brightness
  Color _generateRandomColor() {
    final Random random = Random();

    // Generate colors with higher saturation and appropriate brightness for better visibility
    final hue = random.nextDouble() * 360;
    final saturation = 0.6 + random.nextDouble() * 0.4; // 60-100% saturation
    final lightness = 0.4 + random.nextDouble() * 0.3; // 40-70% lightness

    return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
  }

  // Cache colors for categories to maintain consistency
  final Map<String, Color> _categoryColors = {};

  @override
  void initState() {
    super.initState();
    _globalRef = ref;
    WidgetsBinding.instance.addObserver(this);

    // Load expenses when the page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(dashboardNotifierProvider.notifier)
          .loadExpenses(currentMonth, currentYear);
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
              .addExpense(expense, currentMonth, currentYear);
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
      backgroundColor: Color(0xFFF9F6F1),
      appBar: AppBar(
        title: const Text(
          'LedgerLite',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFFF9F6F1),
        elevation: 0,
        actions: [
          if (Platform.isIOS)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => _showSiriSettingsDialog(context),
              tooltip: 'Siri Shortcuts Settings',
            ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month and Year Selection
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    children: [
                      Text(
                        'Viewing:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Month Dropdown
                      DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: currentMonth,
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          items: List.generate(12, (index) {
                            final month = index + 1;
                            return DropdownMenuItem<int>(
                              value: month,
                              child: Text(_getMonthName(month)),
                            );
                          }),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                currentMonth = value;
                              });
                              ref
                                  .read(dashboardNotifierProvider.notifier)
                                  .loadExpenses(currentMonth, currentYear);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Year Dropdown
                      DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: currentYear,
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          items: List.generate(5, (index) {
                            final year = DateTime.now().year - 2 + index;
                            return DropdownMenuItem<int>(
                              value: year,
                              child: Text(year.toString()),
                            );
                          }),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                currentYear = value;
                              });
                              ref
                                  .read(dashboardNotifierProvider.notifier)
                                  .loadExpenses(currentMonth, currentYear);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                if (dashboardState.expenses.isNotEmpty) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 45,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                TextWidgets.mainSemiBold(
                                  title: 'Total Expense Today',
                                  textAlign: TextAlign.center,
                                  fontSize: 18,
                                ),
                                TextWidgets.mainBold(
                                  title: dashboardState.expenses.isEmpty
                                      ? '\$0.00'
                                      : '\$${dashboardState.totalExpenseToday.toStringAsFixed(2)}',
                                  fontSize: 24,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 45,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                TextWidgets.mainSemiBold(
                                  title: 'Total expense this month',
                                  textAlign: TextAlign.center,
                                  fontSize: 18,
                                ),
                                TextWidgets.mainBold(
                                  title: dashboardState.expenses.isEmpty
                                      ? '\$0.00'
                                      : '\$${dashboardState.totalExpenseMonth.toStringAsFixed(2)}',
                                  fontSize: 24,
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
                    child: Builder(
                      builder: (context) {
                        // Filter out categories with zero values for the pie chart
                        final nonZeroData = dashboardState.chartData.entries
                            .where((entry) => entry.value > 0)
                            .toList();

                        if (nonZeroData.isEmpty) {
                          return const Center(
                            child: Text('No expense data to show'),
                          );
                        }

                        return PieChart(
                          PieChartData(
                            sections: nonZeroData.asMap().entries.map((
                              mapEntry,
                            ) {
                              final entry = mapEntry.value;
                              final categoryName = entry.key;

                              // Get or generate a color for this category
                              Color categoryColor =
                                  _categoryColors[categoryName] ??=
                                      _generateRandomColor();

                              return PieChartSectionData(
                                value: entry.value,
                                color: categoryColor,
                                title: '\$${entry.value.toStringAsFixed(0)}',
                                radius: MediaQuery.of(context).size.width / 6.4,
                              );
                            }).toList(),
                            centerSpaceRadius: 50,
                            sectionsSpace: 2,
                            pieTouchData: PieTouchData(
                              touchCallback:
                                  (
                                    FlTouchEvent event,
                                    PieTouchResponse? response,
                                  ) {
                                    if (DateTime.now()
                                                .difference(_lastTap)
                                                .inMilliseconds >
                                            300 &&
                                        response != null &&
                                        response.touchedSection != null) {
                                      _lastTap = DateTime.now();
                                      int touchedIndex = response
                                          .touchedSection!
                                          .touchedSectionIndex;

                                      // Get the correct category and value from filtered data
                                      if (touchedIndex < nonZeroData.length) {
                                        final touchedEntry =
                                            nonZeroData[touchedIndex];
                                        String category = touchedEntry.key;
                                        double value = touchedEntry.value;

                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text(category.toUpperCase()),
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
                                    }
                                  },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextWidgets.mainSemiBold(title: 'Recent Expenses:'),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: dashboardState.expenses.length,
                    itemBuilder: (context, index) {
                      final expense = dashboardState.expenses[index];
                      return Card(
                        color: Colors.white,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: const Icon(Icons.receipt),
                          title: TextWidgets.mainSemiBold(
                            title:
                                '\$${double.parse(expense.amount).toStringAsFixed(2)}',
                            textAlign: TextAlign.start,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextWidgets.mainRegular(title: expense.category),
                              TextWidgets.mainItalic(
                                title: DateTime.parse(
                                  expense.date,
                                ).toString().substring(0, 10),
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () =>
                                    _showEditExpenseDialog(context, expense),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _showDeleteConfirmationDialog(
                                  context,
                                  expense,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ] else ...[
                  _buildEmptyState(),
                ],
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () => _showAddExpenseFormDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 60,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome to LedgerLite!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Track your expenses effortlessly',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      color: Colors.blue.shade600,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tap the + button to add your first expense',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (Platform.isIOS)
                  Row(
                    children: [
                      Icon(
                        Icons.mic_outlined,
                        color: Colors.blue.shade600,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Use Siri shortcuts for quick expense logging',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.insights_outlined,
                      color: Colors.blue.shade600,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'View your spending patterns with charts',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showAddExpenseFormDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Expense'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseFormDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ExpenseFormDialog(
          onSave: (expense) async {
            try {
              await ref
                  .read(dashboardNotifierProvider.notifier)
                  .addExpense(expense, currentMonth, currentYear);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Expense added successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error adding expense: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        );
      },
    );
  }

  void _showEditExpenseDialog(BuildContext context, ExpenseModel expense) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ExpenseFormDialog(
          expense: expense,
          onSave: (updatedExpense) async {
            try {
              await ref
                  .read(dashboardNotifierProvider.notifier)
                  .updateExpense(
                    updatedExpense,
                    int.parse(expense.id),
                    currentMonth,
                    currentYear,
                  );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Expense updated successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating expense: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(
    BuildContext context,
    ExpenseModel expense,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Expense'),
          content: Text(
            'Are you sure you want to delete this expense?\n\n'
            'Amount: \$${double.parse(expense.amount).toStringAsFixed(2)}\n'
            'Category: ${expense.category.toUpperCase()}\n'
            'Date: ${DateTime.parse(expense.date).toString().substring(0, 10)}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                try {
                  await ref
                      .read(dashboardNotifierProvider.notifier)
                      .deleteExpense(
                        int.parse(expense.id),
                        currentMonth,
                        currentYear,
                      );

                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Expense deleted successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error deleting expense: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Delete'),
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
            .addExpense(
              expenseModel,
              DateTime.now().month,
              DateTime.now().year,
            );
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
        ref
            .read(dashboardNotifierProvider.notifier)
            .loadExpenses(currentMonth, currentYear);

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

  String _getMonthName(int month) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return monthNames[month - 1];
  }

  void _showSiriSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const SiriShortcutSetupDialog();
      },
    );
  }
}
