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
    @Published var selectedDuration: TimeInterval? = nil // Store the requested duration
    
    private var caffeinateProcess: Process?
    private var timer: Timer?
    
    /// Toggles Simple KeepAlive using `caffeinate -i`.
    func enableSimpleMode() {
        if currentMode == .simple {
            disableKeepAlive()
            return
        }
        
        stopAll()
        
        let process = Process()
        process.launchPath = "/usr/bin/caffeinate"
        process.arguments = ["-i"]
        
        do {
            try process.run()
            self.caffeinateProcess = process
            self.currentMode = .simple
            
            // Start the timer IF a duration was pre-selected
            if let duration = selectedDuration, duration > 0 {
                startCountdown(duration: duration)
            }
            
            sendNotification(title: "Simple KeepAlive Enabled", body: "Mac will stay awake while lid is open.")
        } catch {
            print("Failed to start caffeinate: \(error)")
        }
    }
    
    /// Toggles Full KeepAlive using `sudo pmset -a disablesleep 1` and `caffeinate -i`.
    func enableFullMode() {
        if currentMode == .full {
            disableKeepAlive()
            return
        }
        
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
                
                // Start the timer IF a duration was pre-selected
                if let duration = selectedDuration, duration > 0 {
                    startCountdown(duration: duration)
                }
                
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
    
    /// Sets a duration for the *next* or *current* activation.
    func selectDuration(_ duration: TimeInterval?) {
        let cleanDuration = duration == 0 ? nil : duration
        self.selectedDuration = cleanDuration
        
        // If we are ALREADY active, start/restart the timer immediately
        if currentMode != .off {
            if let duration = cleanDuration {
                startCountdown(duration: duration)
            } else {
                stopCountdown()
            }
        }
    }
    
    private func startCountdown(duration: TimeInterval) {
        stopCountdown()
        timerRemaining = duration
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let remaining = self.timerRemaining else { return }
                
                if remaining <= 0 {
                    self.disableKeepAlive()
                } else {
                    self.timerRemaining = remaining - 1
                }
            }
        }
    }
    
    private func stopCountdown() {
        timer?.invalidate()
        timer = nil
        timerRemaining = nil
    }
    
    private func stopAll() {
        // Stop caffeinate process
        if let process = caffeinateProcess, process.isRunning {
            process.terminate()
        }
        caffeinateProcess = nil
        
        // Reset pmset sleep setting ONLY if we were in Full mode
        if currentMode == .full {
            _ = ShellExecutor.executeSudo("pmset -a disablesleep 0")
        }
        
        stopCountdown()
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
