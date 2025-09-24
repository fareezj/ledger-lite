import 'package:flutter/material.dart';
import 'package:ledgerlite/features/dashboard/dashboard_page.dart';
import 'package:ledgerlite/features/splash/splash_page.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/dashboard':
        return MaterialPageRoute(builder: (_) => const DashboardPage());
      default:
        return MaterialPageRoute(builder: (_) => SplashPage()); //
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) {
        return Scaffold(appBar: AppBar(title: const Text('Error')));
      },
    );
  }
}
