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
          "Track expense",
          
          // Direct amount commands
          "Add $150 expense",
          "Log $150 expense",
          "Record $150 expense",
          "Add 150 dollar expense",
          "Log 150 dollar expense",
          
          // Amount variations for learning
          "Add $25 expense",
          "Log $25 expense",
          "Add $50 expense",
          "Log $50 expense",
          "Add $100 expense",
          "Log $100 expense",
          "Add $200 expense",
          "Log $200 expense",
          "Add $500 expense",
          "Log $500 expense",
          
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
          
          // Combined examples - exact matches for common patterns
          "Add $150 shopping expense",
          "Log $150 shopping expense",
          "Record $150 shopping expense",
          "Add $25 food expense",
          "Log $25 food expense",
          "Add $50 transport expense",
          "Log $50 transport expense",
          "Add $30 entertainment expense",
          "Log $30 entertainment expense",
          "Add $100 utilities expense",
          "Log $100 utilities expense",
          "Add $200 healthcare expense",
          "Log $200 healthcare expense",
          "Add $150 education expense",
          "Log $150 education expense",
          "Add $300 travel expense",
          "Log $300 travel expense",
          "Add $75 personal expense",
          "Log $75 personal expense",
          "Add $500 business expense",
          "Log $500 business expense",
          
          // More combined examples with different amounts
          "Add $15 food expense",
          "Log $20 transport expense",
          "Spend $25 on shopping",
          "Spent $30 on entertainment",
          "Add 12 dollar utilities expense",
          "Add $45 healthcare expense",
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
          
          // Alternative phrasings
          "Log an expense of $150 for shopping",
          "Add expense $150 shopping",
          "Record $150 expense in shopping",
          "Track $150 shopping expense",
          "Log expense $150 shopping category",
          "Add $150 to shopping expenses",
          "Spent $150 on shopping",
          "Shopping expense $150",
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