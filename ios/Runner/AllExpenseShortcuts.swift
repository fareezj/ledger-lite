import AppIntents

// Enhanced AppShortcuts provider for better Siri discovery
@available(iOS 16.0, *)
struct AllExpenseShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    return [
      AppShortcut(
        intent: SimpleExpenseIntent(),
        phrases: [
          // Basic commands
          "Add expense",
          "Log expense",
          "Add an expense",
          "Log an expense",
          "Record expense",
          
          // Static examples to help Siri learn patterns
          "Add $5 expense",
          "Log $10 expense",
          "Record $25 expense",
          "Add 15 dollar expense",
          "Log 20 dollar expense",
          "Spend $30",
          "Spent $50",
          
          // Category examples
          "Add food expense",
          "Log food expense",
          "Add transport expense",
          "Log transport expense",
          "Add shopping expense",
          "Log shopping expense",
          "Add entertainment expense",
          "Log entertainment expense",
          "Add utilities expense",
          "Log utilities expense",
          
          // Combined examples
          "Add $15 food expense",
          "Log $20 transport expense",
          "Spend $25 on shopping",
          "Spent $30 on entertainment",
          "Add 12 dollar utilities expense",
          
          // Natural language patterns
          "I spent $40 on food",
          "Just bought transport for $15",
          "Paid $25 for shopping",
          "Expense of $30 in entertainment"
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