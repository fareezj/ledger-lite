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
    
    // Register App Intents for Siri discovery
    #if DEBUG
    print("DEBUG: Registering App Intents...")
    // Note: donate() is called automatically by the system when AppShortcutsProvider is defined
    print("DEBUG: App Intents registered via AppShortcutsProvider")
    #endif
    
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
    
    // Set up notification observer for syncing pending expenses
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(syncPendingExpenses),
      name: NSNotification.Name("SyncPendingExpenses"),
      object: nil
    )
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Handle URL schemes
  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    print("AppDelegate: Received URL: \(url)")
    
    // Handle Siri expense URLs
    if url.scheme == "ledgerlite" && url.host == "add-expense" {
      print("AppDelegate: Handling Siri expense URL")
      
      // The Flutter app will handle this via uni_links
      // Just return true to indicate we handled the URL
      return true
    }
    
    return super.application(app, open: url, options: options)
  }
  
  static func sendExpenseToFlutterWithRetry(category: String, amount: String, description: String? = nil) async {
    let maxRetries = 5
    let retryDelay: TimeInterval = 1.0 // 1 second delay between retries
    
    for attempt in 1...maxRetries {
      if let methodChannel = AppDelegate.methodChannel {
        let args: [String: Any] = [
          "amount": amount,
          "category": category,
          "note": description ?? ""
        ]
        
        print("Attempt \(attempt): Sending expense to Flutter: \(args)")
        
        do {
          let result: Any? = try await methodChannel.invokeMethod("logExpense", arguments: args)
          print("Successfully sent expense to Flutter on attempt \(attempt): \(result ?? "no result")")
          return
        } catch {
          print("Attempt \(attempt) failed: \(error)")
          
          if attempt == maxRetries {
            // All retries failed, store in UserDefaults
            print("All retry attempts failed, storing in UserDefaults")
            let expenseData: [String: Any] = [
              "amount": amount,
              "category": category,
              "note": description ?? "",
              "timestamp": Date().timeIntervalSince1970
            ]
            
            var pendingExpenses = UserDefaults.standard.array(forKey: "pendingSiriExpenses") as? [[String: Any]] ?? []
            pendingExpenses.append(expenseData)
            UserDefaults.standard.set(pendingExpenses, forKey: "pendingSiriExpenses")
            
            print("Stored expense in UserDefaults after retries failed")
          } else {
            // Wait before retrying
            try? await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
          }
        }
      } else {
        print("Attempt \(attempt): Method channel not available")
        
        if attempt == maxRetries {
          // Store in UserDefaults as fallback
          let expenseData: [String: Any] = [
            "amount": amount,
            "category": category,
            "note": description ?? "",
            "timestamp": Date().timeIntervalSince1970
          ]
          
          var pendingExpenses = UserDefaults.standard.array(forKey: "pendingSiriExpenses") as? [[String: Any]] ?? []
          pendingExpenses.append(expenseData)
          UserDefaults.standard.set(pendingExpenses, forKey: "pendingSiriExpenses")
          
          print("Stored expense in UserDefaults (method channel never available)")
        } else {
          // Wait before retrying
          try? await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
        }
      }
    }
  }
  
  @objc func syncPendingExpenses() {
    print("AppDelegate: syncPendingExpenses called")
    
    Task {
      // Small delay to ensure Flutter is ready
      try? await Task.sleep(nanoseconds: UInt64(0.5 * 1_000_000_000)) // 0.5 seconds
      
      guard let methodChannel = AppDelegate.methodChannel else {
        print("AppDelegate: Method channel not available for sync")
        return
      }
      
      print("AppDelegate: Method channel available, proceeding with sync")
      
      let pendingExpenses = UserDefaults.standard.array(forKey: "pendingSiriExpenses") as? [[String: Any]] ?? []
      
      if pendingExpenses.isEmpty {
        print("AppDelegate: No pending expenses to sync")
        return
      }
      
      print("AppDelegate: Syncing \(pendingExpenses.count) pending expenses")
      
      for (index, expenseData) in pendingExpenses.enumerated() {
        print("AppDelegate: Processing expense \(index + 1): \(expenseData)")
        
        let args: [String: Any] = [
          "amount": expenseData["amount"] as? String ?? "0.00",
          "category": expenseData["category"] as? String ?? "other",
          "note": expenseData["note"] as? String ?? ""
        ]
        
        do {
          print("AppDelegate: Invoking method with args: \(args)")
          let result: Any? = try await methodChannel.invokeMethod("logExpense", arguments: args)
          print("AppDelegate: Successfully synced expense \(index + 1): \(result ?? "no result")")
        } catch {
          print("AppDelegate: Error syncing expense \(index + 1): \(error)")
        }
      }
      
      // Clear pending expenses after attempting to sync
      UserDefaults.standard.removeObject(forKey: "pendingSiriExpenses")
      print("AppDelegate: Cleared pending expenses from UserDefaults")
    }
  }
  
  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    
    print("AppDelegate: App became active")
    
    // Check if there are pending expenses immediately
    let pendingExpenses = UserDefaults.standard.array(forKey: "pendingSiriExpenses") as? [[String: Any]] ?? []
    print("AppDelegate: Found \(pendingExpenses.count) pending Siri expenses")
    
    if !pendingExpenses.isEmpty {
      print("AppDelegate: Starting sync of pending expenses")
      // Sync immediately when app becomes active
      syncPendingExpenses()
    } else {
      print("AppDelegate: No pending expenses to sync")
    }
  }
}
