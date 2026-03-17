import Foundation
import UserNotifications

enum KeepAliveMode: String {
    case off = "Disabled"
    case simple = "Simple (Idle Sleep Prevented)"
    case full = "Full (Lid Sleep Prevented)"
}

/// Manages the keep-alive state and system processes.
@MainActor
class KeepAliveManager: ObservableObject {
    @Published var currentMode: KeepAliveMode = .off
    @Published var timerRemaining: TimeInterval? = nil
    
    private var caffeinateProcess: Process?
    private var timer: Timer?
    
    /// Enables Simple KeepAlive using `caffeinate -i`.
    func enableSimpleMode() {
        stopAll()
        
        let process = Process()
        process.launchPath = "/usr/bin/caffeinate"
        process.arguments = ["-i"]
        
        do {
            try process.run()
            self.caffeinateProcess = process
            self.currentMode = .simple
            sendNotification(title: "Simple KeepAlive Enabled", body: "Mac will stay awake while lid is open.")
        } catch {
            print("Failed to start caffeinate: \(error)")
        }
    }
    
    /// Enables Full KeepAlive using `sudo pmset -a disablesleep 1` and `caffeinate -i`.
    func enableFullMode() {
        stopAll()
        
        // Disable sleep via pmset (requires sudo)
        let success = ShellExecutor.executeSudo("pmset -a disablesleep 1")
        
        if success {
            // Also run caffeinate to prevent display/system idle sleep
            let process = Process()
            process.launchPath = "/usr/bin/caffeinate"
            process.arguments = ["-i"]
            
            do {
                try process.run()
                self.caffeinateProcess = process
                self.currentMode = .full
                sendNotification(title: "Full KeepAlive Enabled", body: "Mac will stay awake even with lid closed. Beware of overheating!")
            } catch {
                print("Failed to start caffeinate for full mode: \(error)")
            }
        } else {
            print("Failed to acquire sudo privileges for Full KeepAlive.")
        }
    }
    
    /// Disables all KeepAlive settings and restores defaults.
    func disableKeepAlive() {
        stopAll()
        self.currentMode = .off
        sendNotification(title: "KeepAlive Disabled", body: "Standard energy-saving settings restored.")
    }
    
    /// Sets a timer to disable KeepAlive after a duration.
    func setTimer(duration: TimeInterval) {
        timer?.invalidate()
        timerRemaining = duration
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let remaining = self.timerRemaining else { return }
                
                if remaining <= 0 {
                    self.disableKeepAlive()
                    self.timerRemaining = nil
                    self.timer?.invalidate()
                } else {
                    self.timerRemaining = remaining - 1
                }
            }
        }
    }
    
    private func stopAll() {
        // Stop caffeinate process
        if caffeinateProcess?.isRunning == true {
            caffeinateProcess?.terminate()
        }
        caffeinateProcess = nil
        
        // Reset pmset sleep setting (requires sudo)
        _ = ShellExecutor.executeSudo("pmset -a disablesleep 0")
        
        // Stop timer
        timer?.invalidate()
        timer = nil
        timerRemaining = nil
    }
    
    private func sendNotification(title: String, body: String) {
        print("KeepAlive Notice: \(title) - \(body)")
        
        guard Bundle.main.bundleIdentifier != nil else {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
