import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerlite/db/expense_dao.dart';
import 'package:ledgerlite/models/expense_model.dart';

class DashboardPageState {
  final bool isLoading;
  final List<ExpenseModel> expenses;
  final double totalExpenseToday;
  final double totalExpenseMonth;
  final Map<String, double> chartData;

  const DashboardPageState({
    this.isLoading = false,
    this.expenses = const [],
    this.totalExpenseToday = 0.0,
    this.totalExpenseMonth = 0.0,
    this.chartData = const {},
  });
  DashboardPageState copyWith({
    bool? isLoading,
    List<ExpenseModel>? expenses,
    double? totalExpenseToday,
    double? totalExpenseMonth,
    Map<String, double>? chartData,
  }) {
    return DashboardPageState(
      isLoading: isLoading ?? this.isLoading,
      expenses: expenses ?? this.expenses,
      totalExpenseToday: totalExpenseToday ?? this.totalExpenseToday,
      totalExpenseMonth: totalExpenseMonth ?? this.totalExpenseMonth,
      chartData: chartData ?? this.chartData,
    );
  }
}

final dashboardNotifierProvider =
    NotifierProvider<DashboardNotifier, DashboardPageState>(
      DashboardNotifier.new,
    );

class DashboardNotifier extends Notifier<DashboardPageState> {
  ExpenseDao get expenseDao => ref.watch(expenseDaoProvider);

  @override
  DashboardPageState build() {
    return const DashboardPageState();
  }

  Future<void> addExpense(ExpenseModel expense, [int? month, int? year]) async {
    state = state.copyWith(isLoading: true);

    try {
      await expenseDao.addExpense(expense);
      // Refresh the expenses list after adding
      await loadExpenses(
        month ?? DateTime.now().month,
        year ?? DateTime.now().year,
      );
    } catch (e) {
      // Handle error
      print('Error adding expense: $e');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> updateExpense(
    ExpenseModel newExpense,
    int expenseId,
    int month,
    int year,
  ) async {
    try {
      await expenseDao.updateExpense(newExpense, expenseId);
      await loadExpenses(month, year);
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<void> deleteExpense(int expenseId, int month, int year) async {
    state = state.copyWith(isLoading: true);

    try {
      await expenseDao.deleteExpense(expenseId);
      // Refresh the expenses list after deleting
      await loadExpenses(month, year);
    } catch (e) {
      print('Error deleting expense: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadExpenses(int month, [int? year]) async {
    state = state.copyWith(isLoading: true);

    try {
      final expenses = await expenseDao.getAllExpenses();

      final selectedYear = year ?? DateTime.now().year;

      /* Get total expenses */
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final expensesToday = expenses.where(
        (e) =>
            DateTime.parse(e.date).isAtSameMomentAs(today) ||
            (DateTime.parse(e.date).isAfter(today) &&
                DateTime.parse(
                  e.date,
                ).isBefore(today.add(const Duration(days: 1)))),
      );
      final totalExpenseToday = expensesToday.fold(
        0.0,
        (a, b) => a + double.parse(b.amount),
      );
      final expensesSelectedMonth = expenses.where(
        (e) =>
            DateTime.parse(e.date).month == month &&
            DateTime.parse(e.date).year == selectedYear,
      );
      final totalExpenseMonth = expensesSelectedMonth.fold(
        0.0,
        (a, b) => a + double.parse(b.amount),
      );

      /* Get category total */
      final Map<String, double> chartData = {};
      final categories = [
        'food',
        'transport',
        'shopping',
        'entertainment',
        'utilities',
        'healthcare',
        'education',
        'travel',
        'personal',
        'business',
        'other',
      ];
      for (final category in categories) {
        final categoryExpenses = expenses
            .where(
              (e) =>
                  e.category == category &&
                  DateTime.parse(e.date).month == month &&
                  DateTime.parse(e.date).year == selectedYear,
            )
            .toList()
            .fold(0.0, (a, b) => a + double.parse(b.amount));
        chartData[category] = categoryExpenses;
      }

      // Filter expenses to show only selected month and year
      final filteredExpenses = expenses
          .where(
            (e) =>
                DateTime.parse(e.date).month == month &&
                DateTime.parse(e.date).year == selectedYear,
          )
          .toList();

      state = state.copyWith(
        expenses: filteredExpenses,
        totalExpenseToday: totalExpenseToday,
        totalExpenseMonth: totalExpenseMonth,
        chartData: chartData,
        isLoading: false,
      );
    } catch (e) {
      print('Error loading expenses: $e');
      state = state.copyWith(isLoading: false);
    }
  }
}
