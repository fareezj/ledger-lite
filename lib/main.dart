import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerlite/db/app_database.dart';
import 'package:ledgerlite/features/dashboard/dashboard_page.dart';
import 'package:ledgerlite/features/splash/splash_page.dart';
import 'package:ledgerlite/router/route_generator.dart';
import 'package:ledgerlite/services/pending_expense_service.dart';
import 'package:ledgerlite/services/siri_shortcut_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ProviderScope(child: const MyApp()));
}

Future<void> initializeApp(WidgetRef ref) async {
  // Initialize database
  await AppDatabase().initDatabase();

  // Set up Siri shortcut listener
  initializeSiriShortcutListener();

  // Sync any pending expenses from Siri shortcuts
  final pendingService = ref.read(pendingExpenseServiceProvider);
  final syncedCount = await pendingService.syncPendingExpenses();

  if (syncedCount > 0) {
    print(
      'App startup: Synced $syncedCount pending expenses from Siri shortcuts',
    );
  }
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await initializeApp(ref);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ledgerlite',
      onGenerateRoute: RouteGenerator.generateRoute,
      debugShowCheckedModeBanner: false,
      color: Color(0xFFF9F6F1),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: FutureBuilder<bool>(
        future: SharedPreferences.getInstance().then(
          (prefs) => prefs.getBool('first_time_login') ?? true,
        ),
        builder: (context, snapshot) {
          print(snapshot.data);
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          final firstTimeLogin = snapshot.data ?? false;
          return firstTimeLogin ? SplashPage() : const DashboardPage();
        },
      ),
    );
  }
}
