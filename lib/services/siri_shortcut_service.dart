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

/// Service class for managing Siri shortcut setup and interaction
class SiriShortcutService {
  static const MethodChannel _platform = MethodChannel('ledgerlite/siri');

  /// Shows the native iOS UI to add a Siri shortcut
  static Future<String> showAddShortcut() async {
    try {
      final result = await _platform.invokeMethod('showAddShortcut');
      return result as String;
    } on PlatformException catch (e) {
      print('Error showing add shortcut UI: ${e.message}');
      return 'Error: ${e.message}';
    }
  }

  /// Opens iOS Settings to Siri & Search section
  static Future<String> openSiriSettings() async {
    try {
      final result = await _platform.invokeMethod('openSiriSettings');
      return result as String;
    } on PlatformException catch (e) {
      print('Error opening Siri settings: ${e.message}');
      return 'Error: ${e.message}';
    }
  }

  /// Refreshes Siri shortcuts by clearing interactions and re-donating
  static Future<String> refreshSiriShortcuts() async {
    try {
      final result = await _platform.invokeMethod('refreshSiriShortcuts');
      return result as String;
    } on PlatformException catch (e) {
      print('Error refreshing Siri shortcuts: ${e.message}');
      return 'Error: ${e.message}';
    }
  }

  /// Checks if Siri is available on this device
  static Future<bool> checkSiriAvailability() async {
    try {
      final result = await _platform.invokeMethod('checkSiriAvailability');
      return result as bool;
    } on PlatformException catch (e) {
      print('Error checking Siri availability: ${e.message}');
      return false;
    }
  }
}
