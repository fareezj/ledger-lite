import AppIntents
import Foundation

// Simple test intent with no parameters for easier Siri discovery
@available(iOS 16.0, *)
struct SimpleExpenseIntent: AppIntent, ProvidesDialog {
  static var title: LocalizedStringResource = "Add Expense"
  static var description: LocalizedStringResource = "Add a $5 expense to your ledger"
  static var openAppWhenRun: Bool = false // Don't open app, just run in background

  static var parameterSummary: some ParameterSummary {
    Summary("Add a $5 expense to your ledger")
  }

  @MainActor
  func perform() async throws -> some IntentResult {
    // Send expense to Flutter
    AppDelegate.sendExpenseToFlutter(
        category: "other",
        amount: "5.00",
        description: "Added via Siri"
    )

    return .result(
      dialog: IntentDialog("Added $5.00 expense to your ledger")
    )
  }
}