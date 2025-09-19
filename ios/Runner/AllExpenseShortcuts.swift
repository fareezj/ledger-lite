import AppIntents

// Enhanced AppShortcuts provider for better Siri discovery
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
          "Log expense in ledger",
          "Add $5 expense",
          "Log $5 expense",
          "Record $5 expense",
          "Add five dollar expense",
          "Log five dollar expense"
        ],
        shortTitle: "Add Expense",
        systemImageName: "plus.circle.fill"
      )
    ]
  }

  // This helps Siri discover the shortcuts
  static var shortcutTileColor: ShortcutTileColor {
    return .blue
  }
}