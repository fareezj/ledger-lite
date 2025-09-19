import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerlite/db/app_database.dart';
import 'package:ledgerlite/models/expense_model.dart';

final expenseDaoProvider = Provider<ExpenseDao>((ref) {
  return ExpenseDao(ref.watch(databaseProvider));
});

class ExpenseDao {
  final AppDatabase dbHelper;
  ExpenseDao(this.dbHelper);

  /// Inserts a mailing address if none exists.
  /// If an address already exists, it updates that record.
  Future<int> addExpense(ExpenseModel expense) async {
    final db = await dbHelper.database;
    return await db.insert('expenses', expense.toJson());
  }

  /// Retrieve all expenses.
  Future<List<ExpenseModel>> getAllExpenses() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      orderBy: 'id DESC',
    );
    return maps.map((map) => ExpenseModel.fromJson(map)).toList();
  }

  /// Retrieve a single expense (keeping for compatibility).
  Future<ExpenseModel?> getExpenses() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('expenses');
    if (maps.isNotEmpty) {
      return ExpenseModel.fromJson(maps.first);
    }
    return null;
  }

  // Update an existing expense
  Future<int> updateExpense(ExpenseModel expense, int id) async {
    final db = await dbHelper.database;
    return await db.update(
      'expenses',
      expense.toJson(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete a expense
  Future<int> deleteExpense(int id) async {
    final db = await dbHelper.database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearExpenses() async {
    final db = await dbHelper.database;
    // Remove all rows without dropping the table schema
    await db.delete('expenses');
  }
}
