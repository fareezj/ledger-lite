import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerlite/db/expense_dao.dart';
import 'package:ledgerlite/models/expense_model.dart';

class DashboardPageState {
  final bool isLoading;
  final List<ExpenseModel> expenses;

  const DashboardPageState({this.isLoading = false, this.expenses = const []});

  DashboardPageState copyWith({bool? isLoading, List<ExpenseModel>? expenses}) {
    return DashboardPageState(
      isLoading: isLoading ?? this.isLoading,
      expenses: expenses ?? this.expenses,
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
      print('EXPENSES: $expenses');
      state = state.copyWith(expenses: expenses, isLoading: false);
    } catch (e) {
      print('Error loading expenses: $e');
      state = state.copyWith(isLoading: false);
    }
  }
}
