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
          "Add healthcare expense",
          "Log healthcare expense",
          "Add education expense",
          "Log education expense",
          "Add travel expense",
          "Log travel expense",
          "Add personal expense",
          "Log personal expense",
          "Add business expense",
          "Log business expense",
          
          // Combined examples
          "Add $15 food expense",
          "Log $20 transport expense",
          "Spend $25 on shopping",
          "Spent $30 on entertainment",
          "Add 12 dollar utilities expense",
          "Add $45 healthcare expense",
          "Log $150 education expense",
          "Spend $200 on travel",
          "Spent $35 on personal",
          "Add $75 business expense",
          
          // Natural language patterns
          "I spent $40 on food",
          "Just bought transport for $15",
          "Paid $25 for shopping",
          "Expense of $30 in entertainment",
          "Spent $100 on healthcare",
          "Paid $200 for education",
          "Travel expense of $300",
          "Personal expense $50",
          "Business expense $75",
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