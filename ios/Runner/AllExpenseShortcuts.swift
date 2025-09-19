import AppIntents

// Simplified AppShortcuts provider - easier for Siri to discover
@available(iOS 16.0, *)
struct AllExpenseShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    return [
      AppShortcut(
        intent: SimpleExpenseIntent(),
        phrases: [
          "Add expense",
          "Log expense",
          "Add an expense",
          "Log an expense",
          "Record expense",
          "Add expense to ledger",
          "Log expense in ledger"
        ]
      )
    ]
  }
}