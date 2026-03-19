import SwiftUI

struct MenuView: View {
    @ObservedObject var manager: KeepAliveManager
    @State private var isGlowing = false
    @State private var orbRotation = 0.0
    @State private var showCustomPicker = false
    @State private var customHours = 0
    @State private var customMinutes = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // ... (rest of header remains the same)
            
            // Header
            HStack {
                Text("KeepAlive")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
                statusBadge
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            Spacer(minLength: 30)
            
            // ... (Orb area remains same)
            // MARK: - Central Status Orb & Timer
            ZStack {
                // Background Glow
                Circle()
                    .fill(currentThemeColor.opacity(0.2))
                    .frame(width: 140, height: 140)
                    .blur(radius: 20)
                    .scaleEffect(isGlowing ? 1.2 : 0.9)
                
                // Outer Progress Ring (Timer)
                if let remaining = manager.timerRemaining, let total = totalTimerDuration {
                    Circle()
                        .stroke(.white.opacity(0.1), lineWidth: 4)
                        .frame(width: 110, height: 110)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(remaining / total))
                        .stroke(
                            AngularGradient(
                                colors: [currentThemeColor, currentThemeColor.opacity(0.5), currentThemeColor],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 110, height: 110)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: currentThemeColor.opacity(0.6), radius: 6)
                }
                
                // The Orb
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [currentThemeColor, currentThemeColor.opacity(0.4), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 50
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    // Animated Mesh Pattern
                    Circle()
                        .strokeBorder(
                            AngularGradient(
                                colors: [.white.opacity(0.6), .clear, .white.opacity(0.3), .clear],
                                center: .center
                            ),
                            lineWidth: 0.5
                        )
                        .frame(width: 75, height: 75)
                        .rotationEffect(.degrees(orbRotation))
                    
                    // Status Icon
                    Image(systemName: modeIcon)
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.4), radius: 4)
                }
                .overlay(
                    Circle()
                        .stroke(.white.opacity(0.3), lineWidth: 0.5)
                )
            }
            .padding(.vertical, 10)
            
            // MARK: - Digital Time Display
            if let remaining = manager.timerRemaining {
                Text(formatDuration(remaining))
                    .font(.system(size: 26, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.top, 15)
            } else {
                Text(manager.currentMode == .off ? "STANDBY" : "ACTIVE")
                    .font(.system(size: 14, weight: .heavy, design: .monospaced))
                    .foregroundStyle(currentThemeColor)
                    .padding(.top, 15)
                    .tracking(4)
            }
            
            Spacer(minLength: 40)
            
            // MARK: - Mode Selection (Glass Segments)
            HStack(spacing: 12) {
                ModeToggleButton(
                    title: "SIMPLE",
                    icon: "bolt.fill",
                    isActive: manager.currentMode == .simple,
                    color: .blue
                ) {
                    manager.enableSimpleMode()
                }
                
                ModeToggleButton(
                    title: "FULL",
                    icon: "bolt.shield.fill",
                    isActive: manager.currentMode == .full,
                    color: .orange
                ) {
                    manager.enableFullMode()
                }
            }
            .padding(.horizontal, 20)
            
            // MARK: - Custom Timer Controls (Expandable)
            if showCustomPicker {
                HStack(spacing: 15) {
                    CustomStepper(value: $customHours, range: 0...24, label: "hr")
                    CustomStepper(value: $customMinutes, range: 0...59, label: "min")
                    
                    Button(action: {
                        let totalSeconds = Double(customHours * 3600 + customMinutes * 60)
                        if totalSeconds > 0 {
                            manager.selectDuration(totalSeconds)
                            withAnimation { showCustomPicker = false }
                        } else {
                            manager.selectDuration(nil)
                        }
                    }) {
                        let isCurrent = manager.selectedDuration != nil && 
                                      manager.selectedDuration == Double(customHours * 3600 + customMinutes * 60)
                        
                        Text("SET")
                            .font(.system(size: 10, weight: .black))
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(isCurrent ? Color.blue : Color.blue.opacity(0.6)) // Brighter background
                            .clipShape(Capsule())
                            .foregroundStyle(.white) // Pure white text
                            .shadow(color: .blue.opacity(isCurrent ? 0.5 : 0), radius: 4)
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(isCurrent ? 0.8 : 0.3), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 15)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // MARK: - Timer Presets
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text("TIMER:")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(.white.opacity(0.6))
                    
                    TimerActionChip(
                        label: "1H", 
                        isSelected: manager.selectedDuration == 3600 && !showCustomPicker
                    ) { 
                        showCustomPicker = false
                        manager.selectDuration(3600) 
                    }
                    
                    TimerActionChip(
                        label: "2H", 
                        isSelected: manager.selectedDuration == 7200 && !showCustomPicker
                    ) { 
                        showCustomPicker = false
                        manager.selectDuration(7200) 
                    }
                    
                    TimerActionChip(
                        label: "OFF", 
                        isDestructive: true,
                        isSelected: manager.selectedDuration == nil && !showCustomPicker
                    ) { 
                        showCustomPicker = false
                        manager.selectDuration(nil) 
                    }
                }
                
                HStack {
                    TimerActionChip(
                        label: "CUSTOM DURATION",
                        isSelected: showCustomPicker
                    ) {
                        withAnimation(.spring()) {
                            showCustomPicker.toggle()
                        }
                    }
                    
                    if manager.timerRemaining != nil, showCustomPicker == false, 
                       manager.selectedDuration != 3600, manager.selectedDuration != 7200, manager.selectedDuration != nil {
                        Text("Active")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.blue.opacity(0.2))
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                    
                    // Power buttons moved here for better balance
                    HStack(spacing: 12) {
                        Button(action: { manager.disableKeepAlive() }) {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(manager.currentMode == .off ? Color.white.opacity(0.2) : Color.blue)
                        }
                        .buttonStyle(.plain)
                        .help("Restore defaults")
                        
                        Button(action: { 
                            manager.disableKeepAlive()
                            NSApplication.shared.terminate(nil) 
                        }) {
                            Image(systemName: "power.circle.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(Color.red.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                        .help("Quit KeepAlive")
                    }
                }
            }
            .padding(20)
        }
        .frame(width: 300)
        .background(
            ZStack {
                Color.black // Pure black background
                VisualEffectView(material: .popover, blendingMode: .withinWindow)
                    .opacity(0.2) // Subtle texture
            }
        )
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isGlowing = true
            }
            withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                orbRotation = 360
            }
        }
    }
    
    // MARK: - Subviews & Helpers
    
    private var statusBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(currentThemeColor)
                .frame(width: 6, height: 6)
            Text(manager.currentMode == .off ? "INACTIVE" : "READY")
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(.white.opacity(0.9)) // Always bright white
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 10)
        .background(currentThemeColor.opacity(0.2))
        .clipShape(Capsule())
    }
    
    private var currentThemeColor: Color {
        switch manager.currentMode {
        case .off: return Color.white.opacity(0.3) // Silver instead of dark gray
        case .simple: return .blue
        case .full: return .orange
        }
    }
    
    private var modeIcon: String {
        switch manager.currentMode {
        case .off: return "bolt.slash.fill"
        case .simple: return "bolt.fill"
        case .full: return "bolt.shield.fill"
        }
    }
    
    private var totalTimerDuration: TimeInterval? {
        // Simple heuristic for total duration of the current timer
        // For a more precise progress we'd need to store the start duration in manager
        guard let remaining = manager.timerRemaining else { return nil }
        if remaining > 3600 { return 7200 }
        return 3600
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        let s = Int(seconds) % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}

// MARK: - Support Views

struct ModeToggleButton: View {
    let title: String
    let icon: String
    let isActive: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.system(size: 10, weight: .black))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    if isActive {
                        color.opacity(0.2)
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(color.opacity(0.5), lineWidth: 1)
                    } else {
                        Color.white.opacity(0.03)
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    }
                }
            )
            .cornerRadius(15)
            .foregroundStyle(isActive ? color : Color.white.opacity(0.6))
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3), value: isActive)
    }
}

struct TimerActionChip: View {
    let label: String
    var isDestructive: Bool = false
    var isSelected: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 10, weight: isSelected ? .black : .bold))
                .padding(.vertical, 4)
                .padding(.horizontal, 10)
                .background(isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.white.opacity(0.4) : Color.white.opacity(0.1), lineWidth: isSelected ? 1 : 0.5)
                )
        }
        .buttonStyle(.plain)
        .foregroundStyle(isDestructive ? Color.red.opacity(0.8) : (isSelected ? Color.white : Color.white.opacity(0.7)))
    }
}

// Standard macOS bridge for glass effect
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Custom Stepper Support

struct CustomStepper: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let label: String
    
    var body: some View {
        HStack(spacing: 8) {
            Button(action: { if value > range.lowerBound { value -= 1 } }) {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .buttonStyle(.plain)
            
            VStack(spacing: 0) {
                Text("\(value)")
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
                Text(label)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .frame(width: 25)
            
            Button(action: { if value < range.upperBound { value += 1 } }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .buttonStyle(.plain)
        }
    }
}
