import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  static var methodChannel: FlutterMethodChannel?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Set up method channel for Siri integration
    guard let controller = window?.rootViewController as? FlutterViewController else {
      fatalError("rootViewController is not type FlutterViewController")
    }
    
    let methodChannel = FlutterMethodChannel(
      name: "com.wolf.ledgerlite/shortcut",
      binaryMessenger: controller.binaryMessenger
    )
    
    AppDelegate.methodChannel = methodChannel
    print("DEBUG: Method channel initialized successfully")
    
    // Set up method call handler for Flutter to iOS communication
    methodChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      switch call.method {
      case "logExpense":
        // Handle expense logging from Siri intents
        if let args = call.arguments as? [String: Any] {
          let amount = args["amount"] as? String ?? "0.00"
          let category = args["category"] as? String ?? "other"
          let note = args["note"] as? String ?? ""
          
          print("Received expense from Flutter: $\(amount) - \(category) - \(note)")
          
          // Add expense to database here if needed
          // For now, just acknowledge receipt
          result("Expense logged successfully")
        } else {
          result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid expense data", details: nil))
        }
      case "getShortcutExpenses", "getPendingExpenses", "getUrlExpenses", "getSimpleExpenses":
        let pendingExpenses = UserDefaults.standard.array(forKey: "pendingSiriExpenses") as? [[String: Any]] ?? []
        result(pendingExpenses)
      case "clearShortcutExpenses", "clearPendingExpenses", "clearUrlExpenses", "clearSimpleExpenses", "clearSiriExpenses":
        UserDefaults.standard.removeObject(forKey: "pendingSiriExpenses")
        result("Pending expenses cleared")
      case "testWrite":
        // Test writing to UserDefaults
        let testData: [String: Any] = [
          "amount": "10.00",
          "category": "test",
          "note": "Test expense",
          "timestamp": Date().timeIntervalSince1970
        ]
        var pendingExpenses = UserDefaults.standard.array(forKey: "pendingSiriExpenses") as? [[String: Any]] ?? []
        pendingExpenses.append(testData)
        UserDefaults.standard.set(pendingExpenses, forKey: "pendingSiriExpenses")
        result("Test expense written")
      case "getInitialUrl":
        // For URL scheme handling - return nil for now
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  static func sendExpenseToFlutter(category: String, amount: String, description: String? = nil) {
    guard let methodChannel = AppDelegate.methodChannel else {
      print("ERROR: Method channel not initialized! Storing expense for later processing")
      
      // Store the expense in UserDefaults as fallback
      let expenseData: [String: Any] = [
        "amount": amount,
        "category": category,
        "note": description ?? "",
        "timestamp": Date().timeIntervalSince1970
      ]
      
      var pendingExpenses = UserDefaults.standard.array(forKey: "pendingSiriExpenses") as? [[String: Any]] ?? []
      pendingExpenses.append(expenseData)
      UserDefaults.standard.set(pendingExpenses, forKey: "pendingSiriExpenses")
      
      print("Stored expense in UserDefaults: \(expenseData)")
      return
    }
    
    let args: [String: Any] = [
      "amount": amount,
      "category": category,
      "note": description ?? ""
    ]
    
    print("Sending expense to Flutter: \(args)")
    
    methodChannel.invokeMethod("logExpense", arguments: args) { result in
      if let error = result as? FlutterError {
        print("Error sending expense to Flutter: \(error.message ?? "Unknown error")")
      } else {
        print("Successfully sent expense to Flutter: \(result ?? "no result")")
      }
    }
  }
}
