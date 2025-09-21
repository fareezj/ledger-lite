import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerlite/db/expense_dao.dart';
import 'package:ledgerlite/models/expense_model.dart';

class DashboardPageState {
  final bool isLoading;
  final List<ExpenseModel> expenses;
  final double totalExpenseToday;
  final double totalExpenseMonth;

  const DashboardPageState({
    this.isLoading = false,
    this.expenses = const [],
    this.totalExpenseToday = 0.0,
    this.totalExpenseMonth = 0.0,
  });

  DashboardPageState copyWith({
    bool? isLoading,
    List<ExpenseModel>? expenses,
    double? totalExpenseToday,
    double? totalExpenseMonth,
  }) {
    return DashboardPageState(
      isLoading: isLoading ?? this.isLoading,
      expenses: expenses ?? this.expenses,
      totalExpenseToday: totalExpenseToday ?? this.totalExpenseToday,
      totalExpenseMonth: totalExpenseMonth ?? this.totalExpenseMonth,
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

  Future<void> addExpense(ExpenseModel expense) async {
    state = state.copyWith(isLoading: true);

    try {
      await expenseDao.addExpense(expense);
      // Refresh the expenses list after adding
      await loadExpenses();
    } catch (e) {
      // Handle error
      print('Error adding expense: $e');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadExpenses() async {
    state = state.copyWith(isLoading: true);

    try {
      final expenses = await expenseDao.getAllExpenses();
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
      final expensesThisMonth = expenses.where(
        (e) =>
            DateTime.parse(e.date).month == now.month &&
            DateTime.parse(e.date).year == now.year,
      );
      final totalExpenseMonth = expensesThisMonth.fold(
        0.0,
        (a, b) => a + double.parse(b.amount),
      );

      state = state.copyWith(
        expenses: expenses,
        totalExpenseToday: totalExpenseToday,
        totalExpenseMonth: totalExpenseMonth,
        isLoading: false,
      );

      print('state: ${state.totalExpenseMonth}');
      print('state: ${state.totalExpenseToday}');
      state = state.copyWith(expenses: expenses, isLoading: false);
    } catch (e) {
      print('Error loading expenses: $e');
      state = state.copyWith(isLoading: false);
    }
  }
}
