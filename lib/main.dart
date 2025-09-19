import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerlite/db/app_database.dart';
import 'package:ledgerlite/features/dashboard/dashboard_page.dart';
import 'package:ledgerlite/services/pending_expense_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ProviderScope(child: const MyApp()));
}

Future<void> initializeApp(WidgetRef ref) async {
  // Initialize database
  await AppDatabase().initDatabase();

  // Disable shortcut listener to prevent crashes
  // setupShortcutListener();

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
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await initializeApp(ref);
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ledgerlite',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: _isInitialized
          ? const DashboardPage()
          : const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Initializing ledgerlite...'),
                    SizedBox(height: 8),
                    Text(
                      'Syncing Siri shortcut expenses',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
