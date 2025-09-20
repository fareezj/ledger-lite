import Flutter
import UIKit
import Intents

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
      name: "ledgerlite/siri",
      binaryMessenger: controller.binaryMessenger
    )
    
    AppDelegate.methodChannel = methodChannel
    print("DEBUG: Method channel initialized successfully")
    
    // Register App Intents for Siri discovery
    #if DEBUG
    print("DEBUG: Registering App Intents...")
    #endif
    
    // Donate shortcuts to Siri for better discoverability
    donateShortcuts()
    
    // Also try to register the App Shortcuts Provider explicitly
    registerAppShortcuts()
    
    #if DEBUG
    print("DEBUG: App Intents registered and shortcuts donated")
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
          
          // Donate shortcut based on this expense to help Siri learn
          self.donateShortcutForExpense(amount: amount, category: category)
          
          // Add expense to database here if needed
          // For now, just acknowledge receipt
          result("Expense logged successfully")
        } else {
          result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid expense data", details: nil))
        }
      case "getSiriExpenses", "getShortcutExpenses", "getPendingExpenses", "getUrlExpenses", "getSimpleExpenses":
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
      case "openSiriSettings":
        // Open iOS Settings app to Siri & Search section
        if let url = URL(string: "App-Prefs:SIRI") {
          UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else if let url = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        result("Opening Siri settings")
      case "showAddShortcut":
        // Present native iOS UI to add Siri shortcut
        self.showAddShortcutUI(result: result)
      case "refreshSiriShortcuts":
        // Force refresh Siri's shortcut index
        Task {
          do {
            // Clear old interactions and force re-indexing
            try await INInteraction.deleteAll()
            #if DEBUG
            print("DEBUG: Cleared Siri interactions for refresh")
            #endif

            // Re-donate all shortcuts
            await self.donateShortcuts()
            await self.registerAppShortcuts()

            result("Siri shortcuts refreshed successfully")
          } catch {
            result(FlutterError(code: "REFRESH_FAILED", message: "Failed to refresh Siri shortcuts: \(error)", details: nil))
          }
        }
      case "checkSiriAvailability":
        // Check if Siri is available on this device
        let siriAvailable = true // Siri is available on iOS devices that support it
        result(siriAvailable)
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

    // Handle Siri expense URLs with parameters
    if url.scheme == "ledgerlite" && url.host == "add-expense" {
      print("AppDelegate: Handling Siri expense URL")

      // Parse URL parameters
      let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
      var amount: Double = 5.0
      var category: String = "other"

      if let queryItems = urlComponents?.queryItems {
        for item in queryItems {
          if item.name == "amount", let amountString = item.value, let parsedAmount = Double(amountString) {
            amount = parsedAmount
            print("AppDelegate: Parsed amount from URL: \(amount)")
          } else if item.name == "category", let categoryValue = item.value {
            category = categoryValue
            print("AppDelegate: Parsed category from URL: \(category)")
          }
        }
      }

      // Store expense data in UserDefaults with parsed parameters
      let expenseData: [String: Any] = [
        "amount": String(format: "%.2f", amount),
        "category": category,
        "note": "Added via Siri URL",
        "timestamp": Date().timeIntervalSince1970,
        "id": UUID().uuidString
      ]

      var pendingExpenses = UserDefaults.standard.array(forKey: "pendingSiriExpenses") as? [[String: Any]] ?? []
      pendingExpenses.append(expenseData)
      UserDefaults.standard.set(pendingExpenses, forKey: "pendingSiriExpenses")

      print("AppDelegate: Stored expense from URL: \(expenseData)")

      // The Flutter app will handle this via uni_links
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
  
  // Donate shortcuts to Siri for automatic discovery
  private func donateShortcuts() {
    #if DEBUG
    print("DEBUG: Donating shortcuts to Siri...")
    #endif

    Task {
      do {
        // Donate the basic intent multiple times with different contexts
        // This helps Siri learn and surface shortcuts more readily
        let intent = SimpleExpenseIntent()
        try await intent.donate()

        #if DEBUG
        print("DEBUG: Successfully donated shortcuts to Siri")
        #endif
      } catch {
        #if DEBUG
        print("DEBUG: Failed to donate shortcuts: \(error)")
        #endif
      }
    }

    #if DEBUG
    print("DEBUG: Shortcut donation completed")
    #endif
  }  // Explicitly register App Shortcuts for Siri discovery
  private func registerAppShortcuts() {
    #if DEBUG
    print("DEBUG: Explicitly registering App Shortcuts...")
    #endif
    
    // Force Siri to update its shortcut index
    Task {
      do {
        // Clear old interactions to force fresh learning
        try await INInteraction.deleteAll()
        #if DEBUG
        print("DEBUG: Cleared Siri interaction history for fresh start")
        #endif
        
      } catch {
        #if DEBUG
        print("DEBUG: Failed to register shortcuts: \(error)")
        #endif
      }
    }
  }
  
  // Donate a specific shortcut based on logged expense
  private func donateShortcutForExpense(amount: String, category: String) {
    // For now, just donate the basic intent to help with discoverability
    // The AppShortcutsProvider will handle the specific phrases
    Task {
      do {
        let intent = SimpleExpenseIntent()
        try await intent.donate()
        #if DEBUG
        print("DEBUG: Donated shortcut for Flutter expense: $\(amount) \(category)")
        #endif
      } catch {
        #if DEBUG
        print("DEBUG: Failed to donate Flutter shortcut: \(error)")
        #endif
      }
    }
  }

  // Present native iOS UI to add Siri shortcut
  // Present native iOS UI to add Siri shortcut
  private func showAddShortcutUI(result: @escaping FlutterResult) {
    #if DEBUG
    print("DEBUG: Presenting add shortcut UI")
    #endif

    // Try to open the Shortcuts app directly
    if let shortcutsURL = URL(string: "shortcuts://") {
      UIApplication.shared.open(shortcutsURL, options: [:]) { success in
        if success {
          result("Opened Shortcuts app successfully")
        } else {
          // Fallback to Siri settings
          self.fallbackToSiriSettings(result: result)
        }
      }
    } else {
      // Fallback to Siri settings
      self.fallbackToSiriSettings(result: result)
    }
  }

  // Fallback method to open Siri settings
  private func fallbackToSiriSettings(result: @escaping FlutterResult) {
    if let url = URL(string: "App-Prefs:SIRI") {
      UIApplication.shared.open(url, options: [:], completionHandler: nil)
      result("Opened Siri settings")
    } else if let url = URL(string: UIApplication.openSettingsURLString) {
      UIApplication.shared.open(url, options: [:], completionHandler: nil)
      result("Opened iOS settings")
    } else {
      result(FlutterError(code: "CANNOT_OPEN_SETTINGS", message: "Cannot open settings", details: nil))
    }
  }
}
