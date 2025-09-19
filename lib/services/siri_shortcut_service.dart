import 'package:flutter/services.dart';
import 'package:ledgerlite/models/expense_model.dart';
import 'package:ledgerlite/features/dashboard/dashboard_page.dart';

void initializeSiriShortcutListener() {
  const platform = MethodChannel('ledgerlite/siri');

  platform.setMethodCallHandler((call) async {
    try {
      if (call.method == 'logExpense') {
        final args = Map<String, dynamic>.from(call.arguments);
        final amount = double.parse(args['amount'] as String);
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
