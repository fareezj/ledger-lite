import 'package:flutter/services.dart';

class SiriDebugHelper {
  static const platform = MethodChannel('com.wolf.ledgerlite/shortcut');

  static Future<void> testSiriStorage() async {
    try {
      // Test if we can read from UserDefaults
      final result = await platform.invokeMethod('getPendingExpenses');
      print('Pending expenses from iOS: $result');

      // Test writing to UserDefaults
      await platform.invokeMethod('testWrite');
      print('Test write completed');
    } catch (e) {
      print('Siri debug error: $e');
    }
  }
}
