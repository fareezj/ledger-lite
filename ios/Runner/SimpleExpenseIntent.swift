import AppIntents
import Foundation

// Enhanced intent with better metadata for Siri discovery
@available(iOS 16.0, *)
struct SimpleExpenseIntent: AppIntent {
  static var title: LocalizedStringResource = "Add Expense"
  static var description: LocalizedStringResource = "Quickly add a $5 expense to your ledger"
  static var openAppWhenRun: Bool = true // Open app when run to ensure Flutter is available

  // Add keywords to help Siri discover this intent
  static var searchKeywords = [
    LocalizedStringResource("expense"),
    LocalizedStringResource("ledger"),
    LocalizedStringResource("money"),
    LocalizedStringResource("spending"),
    LocalizedStringResource("log"),
    LocalizedStringResource("record"),
    LocalizedStringResource("add"),
    LocalizedStringResource("track")
  ]

  // Add parameter summary for better Siri understanding
  static var parameterSummary: some ParameterSummary {
    Summary("Add a $5 expense to your ledger")
  }

  // Add authentication policy if needed
  static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

  @MainActor
  func perform() async throws -> some IntentResult {
    // Store expense data in UserDefaults - this is the most reliable approach
    let expenseData: [String: Any] = [
      "amount": "5.00",
      "category": "other",
      "note": "Added via Siri",
      "timestamp": Date().timeIntervalSince1970,
      "id": UUID().uuidString
    ]
    
    // Store in UserDefaults
    var pendingExpenses = UserDefaults.standard.array(forKey: "pendingSiriExpenses") as? [[String: Any]] ?? []
    pendingExpenses.append(expenseData)
    UserDefaults.standard.set(pendingExpenses, forKey: "pendingSiriExpenses")
    
    print("Siri Intent: Stored expense in UserDefaults: \(expenseData)")
    print("Siri Intent: Total pending expenses: \(pendingExpenses.count)")
    
    // Try to send immediately if method channel is available and app is running
    if let methodChannel = AppDelegate.methodChannel {
      print("Siri Intent: Method channel available, attempting immediate sync")
      
      let args: [String: Any] = [
        "amount": "5.00",
        "category": "other",
        "note": "Added via Siri"
      ]
      
      do {
        let result: Any? = try await methodChannel.invokeMethod("logExpense", arguments: args)
        print("Siri Intent: Immediate sync successful: \(result ?? "no result")")
        
        // Clear the stored expense since it was sent successfully
        UserDefaults.standard.removeObject(forKey: "pendingSiriExpenses")
        print("Siri Intent: Cleared UserDefaults after successful sync")
      } catch {
        print("Siri Intent: Immediate sync failed: \(error)")
        print("Siri Intent: Expense will be synced when app becomes active")
      }
    } else {
      print("Siri Intent: Method channel not available, will sync when app becomes active")
    }

    // Return success without value
    return .result()
  }
}