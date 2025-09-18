import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liteledger/db/expense_dao.dart';
import 'package:liteledger/models/expense_model.dart';

final pendingExpenseServiceProvider = Provider<PendingExpenseService>((ref) {
  return PendingExpenseService(ref.watch(expenseDaoProvider));
});

class PendingExpenseService {
  final ExpenseDao expenseDao;
  static const platform = MethodChannel('com.wolf.liteledger/shortcut');

  PendingExpenseService(this.expenseDao);

  /// Sync pending expenses from iOS UserDefaults to Flutter database
  Future<int> syncPendingExpenses() async {
    try {
      // Try shortcut helper method first (most stable)
      final List<dynamic>? shortcutExpensesRaw = await platform.invokeMethod(
        'getShortcutExpenses',
      );

      if (shortcutExpensesRaw != null && shortcutExpensesRaw.isNotEmpty) {
        return await _syncShortcutExpenses(shortcutExpensesRaw);
      }

      // Try URL-based expenses second
      final List<dynamic>? urlExpensesRaw = await platform.invokeMethod(
        'getUrlExpenses',
      );

      if (urlExpensesRaw != null && urlExpensesRaw.isNotEmpty) {
        return await _syncUrlExpenses(urlExpensesRaw);
      }

      // Try the simplified format third
      final List<dynamic>? simpleExpensesRaw = await platform.invokeMethod(
        'getSimpleExpenses',
      );

      if (simpleExpensesRaw != null && simpleExpensesRaw.isNotEmpty) {
        return await _syncSimpleExpenses(simpleExpensesRaw);
      } // Fallback to old format
      final List<dynamic>? pendingExpensesRaw = await platform.invokeMethod(
        'getPendingExpenses',
      );

      if (pendingExpensesRaw == null || pendingExpensesRaw.isEmpty) {
        print('No pending expenses found');
        return 0;
      }

      int syncedCount = 0;

      // Process each pending expense
      for (final expenseData in pendingExpensesRaw) {
        try {
          final Map<String, dynamic> expenseMap = Map<String, dynamic>.from(
            expenseData,
          );

          // Create ExpenseModel from the data
          final expense = ExpenseModel(
            id:
                expenseMap['id'] ??
                DateTime.now().millisecondsSinceEpoch.toString(),
            category: expenseMap['category'] ?? 'Unknown',
            amount: expenseMap['amount'] ?? '0.00',
            date: expenseMap['date'] ?? DateTime.now().toIso8601String(),
          );

          // Save to database
          await expenseDao.addExpense(expense);
          syncedCount++;

          print('Synced expense: ${expense.category} - \$${expense.amount}');
        } catch (e) {
          print('Error processing expense: $e');
        }
      }

      // Clear pending expenses from iOS after successful sync
      if (syncedCount > 0) {
        await platform.invokeMethod('clearPendingExpenses');
        print('Successfully synced $syncedCount pending expenses');
      }

      return syncedCount;
    } catch (e) {
      print('Error syncing pending expenses: $e');
      return 0;
    }
  }

  /// Sync shortcut helper expenses (most stable method)
  Future<int> _syncShortcutExpenses(List<dynamic> shortcutExpensesRaw) async {
    int syncedCount = 0;

    for (final expenseMap in shortcutExpensesRaw) {
      try {
        if (expenseMap is Map<String, dynamic>) {
          final expense = ExpenseModel(
            id:
                expenseMap['id']?.toString() ??
                DateTime.now().millisecondsSinceEpoch.toString(),
            amount: expenseMap['amount']?.toString() ?? '0.00',
            category: expenseMap['category']?.toString() ?? 'Unknown',
            date:
                expenseMap['date']?.toString() ??
                DateTime.now().toIso8601String(),
          );

          await expenseDao.addExpense(expense);
          syncedCount++;
          print(
            'Synced shortcut expense: ${expense.category} - \$${expense.amount}',
          );
        }
      } catch (e) {
        print('Error processing shortcut expense: $e');
      }
    }

    // Clear shortcut expenses after sync
    if (syncedCount > 0) {
      await platform.invokeMethod('clearShortcutExpenses');
    }

    return syncedCount;
  }

  /// Sync URL-based expenses (most reliable method)
  Future<int> _syncUrlExpenses(List<dynamic> urlExpensesRaw) async {
    int syncedCount = 0;

    for (final expenseString in urlExpensesRaw) {
      try {
        final parts = expenseString.toString().split('|');
        if (parts.length >= 4) {
          final expense = ExpenseModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            amount: parts[0],
            category: parts[1],
            date: parts[3].isNotEmpty
                ? parts[3]
                : DateTime.now().toIso8601String(),
          );

          await expenseDao.addExpense(expense);
          syncedCount++;
          print(
            'Synced URL expense: ${expense.category} - \$${expense.amount}',
          );
        }
      } catch (e) {
        print('Error processing URL expense: $e');
      }
    }

    // Clear URL expenses after sync
    if (syncedCount > 0) {
      await platform.invokeMethod('clearUrlExpenses');
    }

    return syncedCount;
  }

  /// Sync simple string-based expenses
  Future<int> _syncSimpleExpenses(List<dynamic> simpleExpensesRaw) async {
    int syncedCount = 0;

    for (final expenseString in simpleExpensesRaw) {
      try {
        final parts = expenseString.toString().split('|');
        if (parts.length >= 4) {
          final expense = ExpenseModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            amount: parts[0],
            category: parts[1],
            date: parts[3].isNotEmpty
                ? parts[3]
                : DateTime.now().toIso8601String(),
          );

          await expenseDao.addExpense(expense);
          syncedCount++;
          print(
            'Synced simple expense: ${expense.category} - \$${expense.amount}',
          );
        }
      } catch (e) {
        print('Error processing simple expense: $e');
      }
    }

    // Clear simple expenses after sync
    if (syncedCount > 0) {
      await platform.invokeMethod('clearSimpleExpenses');
    }

    return syncedCount;
  }

  /// Check if there are any pending expenses
  Future<bool> hasPendingExpenses() async {
    try {
      final List<dynamic>? pendingExpenses = await platform.invokeMethod(
        'getPendingExpenses',
      );
      return pendingExpenses != null && pendingExpenses.isNotEmpty;
    } catch (e) {
      print('Error checking pending expenses: $e');
      return false;
    }
  }
}
