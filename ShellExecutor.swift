import Foundation

/// Executes shell commands on macOS.
class ShellExecutor {
    
    /// Executes a standard shell command.
    /// - Parameter command: The command string to execute.
    /// - Returns: The output of the command or nil if it fails.
    static func execute(_ command: String) -> String? {
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        process.arguments = ["-c", command]
        process.launchPath = "/bin/zsh"
        
        do {
            try process.run()
        } catch {
            print("ShellExecutor Error: \(error)")
            return nil
        }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)
    }
    
    /// Executes a command with sudo privileges using AppleScript for authentication.
    /// - Parameter command: The command string to execute with sudo.
    /// - Returns: True if successful, false otherwise.
    static func executeSudo(_ command: String) -> Bool {
        let appleScriptBody = "do shell script \"\(command)\" with administrator privileges"
        let script = NSAppleScript(source: appleScriptBody)
        var error: NSDictionary?
        script?.executeAndReturnError(&error)
        
        if let err = error {
            print("ShellExecutor Sudo Error: \(err)")
            return false
        }
        return true
    }
}
