import AppIntents
import Foundation

// Enhanced intent with parameters for Siri discovery
@available(iOS 16.0, *)
struct SimpleExpenseIntent: AppIntent {
  static var title: LocalizedStringResource = "Add Expense"
  static var description: LocalizedStringResource = "Add an expense to your ledger with custom amount and category"
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

  // Define expense categories
  enum ExpenseCategory: String, AppEnum {
    case food = "food"
    case transport = "transport"
    case shopping = "shopping"
    case entertainment = "entertainment"
    case utilities = "utilities"
    case healthcare = "healthcare"
    case education = "education"
    case travel = "travel"
    case personal = "personal"
    case business = "business"
    case other = "other"

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
      TypeDisplayRepresentation(name: "Category")
    }

    static var caseDisplayRepresentations: [ExpenseCategory: DisplayRepresentation] {
      [
        .food: DisplayRepresentation(title: "🍕 Food & Dining", subtitle: "Restaurants, groceries, takeout"),
        .transport: DisplayRepresentation(title: "🚗 Transport", subtitle: "Gas, parking, rideshare, public transit"),
        .shopping: DisplayRepresentation(title: "🛍️ Shopping", subtitle: "Clothes, electronics, household items"),
        .entertainment: DisplayRepresentation(title: "🎬 Entertainment", subtitle: "Movies, games, hobbies, events"),
        .utilities: DisplayRepresentation(title: "⚡ Utilities", subtitle: "Electricity, water, internet, phone"),
        .healthcare: DisplayRepresentation(title: "🏥 Healthcare", subtitle: "Medical, dental, pharmacy, insurance"),
        .education: DisplayRepresentation(title: "📚 Education", subtitle: "Books, courses, tuition, supplies"),
        .travel: DisplayRepresentation(title: "✈️ Travel", subtitle: "Flights, hotels, vacation expenses"),
        .personal: DisplayRepresentation(title: "👤 Personal", subtitle: "Haircuts, toiletries, personal care"),
        .business: DisplayRepresentation(title: "💼 Business", subtitle: "Work expenses, office supplies"),
        .other: DisplayRepresentation(title: "📝 Other", subtitle: "Miscellaneous expenses")
      ]
    }
  }

  // Intent parameters
  @Parameter(
    title: "Amount", 
    description: "The expense amount (e.g., 25.50)"
  )
  var amount: Double

  @Parameter(
    title: "Category", 
    description: "Choose the expense category",
    requestValueDialog: IntentDialog("What category is this expense for?")
  )
  var category: ExpenseCategory

  // Add parameter summary for better Siri understanding
  static var parameterSummary: some ParameterSummary {
    Summary("Add an expense")
  }

  // Add authentication policy if needed
  static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

  @MainActor
  func perform() async throws -> some IntentResult {
    print("🎯 SIRI INTENT CALLED: perform() method started")
    
    // Debug: Log the raw parameter values
    print("Siri Intent: Raw amount parameter: \(amount)")
    print("Siri Intent: Raw category parameter: \(category.rawValue)")
    
    // Use provided parameters
    let expenseAmount = amount
    let expenseCategory = category.rawValue
    
    print("Siri Intent: Final amount: $\(expenseAmount)")
    print("Siri Intent: Final category: \(expenseCategory)")
    print("🎯 SIRI INTENT: About to store expense data")

    // Store expense data in UserDefaults - this is the most reliable approach
    let expenseData: [String: Any] = [
      "amount": String(format: "%.2f", expenseAmount),
      "category": expenseCategory,
      "note": "Added via Siri Intent",
      "timestamp": Date().timeIntervalSince1970,
      "id": UUID().uuidString
    ]

    // Store in UserDefaults
    var pendingExpenses = UserDefaults.standard.array(forKey: "pendingSiriExpenses") as? [[String: Any]] ?? []
    pendingExpenses.append(expenseData)
    UserDefaults.standard.set(pendingExpenses, forKey: "pendingSiriExpenses")

    print("Siri Intent: Stored expense in UserDefaults: \(expenseData)")
    print("Siri Intent: Amount: $\(expenseAmount), Category: \(expenseCategory)")
    print("Siri Intent: Total pending expenses: \(pendingExpenses.count)")

    // Try to send immediately if method channel is available and app is running
    if let methodChannel = AppDelegate.methodChannel {
      print("Siri Intent: Method channel available, attempting immediate sync")

      let args: [String: Any] = [
        "amount": String(format: "%.2f", expenseAmount),
        "category": expenseCategory,
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