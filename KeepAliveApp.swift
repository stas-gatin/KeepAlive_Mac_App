import SwiftUI
import UserNotifications

@main
struct KeepAliveApp: App {
    @StateObject private var manager = KeepAliveManager()
    
    init() {
        requestNotificationPermission()
    }
    
    var body: some Scene {
        MenuBarExtra("KeepAlive", systemImage: manager.currentMode == .off ? "bolt.slash" : "bolt.fill") {
            MenuView(manager: manager)
        }
        .menuBarExtraStyle(.window)
    }
    
    private func requestNotificationPermission() {
        guard Bundle.main.bundleIdentifier != nil else {
            print("Skipping notifications: Running as raw binary without app bundle.")
            return
        }
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Notification permission granted.")
            } else if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
}
