import SwiftUI

// MARK: - Color Palette

private extension Color {
    // CPU: Emerald green gradient
    static let cpuStart = Color(red: 0.18, green: 0.80, blue: 0.55)
    static let cpuEnd = Color(red: 0.10, green: 0.62, blue: 0.42)

    // Memory: Warm orange gradient
    static let memStart = Color(red: 1.0, green: 0.62, blue: 0.25)
    static let memEnd = Color(red: 0.95, green: 0.45, blue: 0.18)

    // Accent red for high usage
    static let hotStart = Color(red: 1.0, green: 0.38, blue: 0.35)
    static let hotEnd = Color(red: 0.88, green: 0.22, blue: 0.22)

    // Glass surfaces
    static let glassStroke = Color.white.opacity(0.18)
    static let glassFill = Color.white.opacity(0.06)
    static let glassFillHover = Color.white.opacity(0.10)
    static let dimText = Color.primary.opacity(0.45)
}

// MARK: - Main View

struct PopoverView: View {
    @StateObject private var monitor = SystemMonitor()

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            gaugesSection
            processesSection
            Spacer(minLength: 0)
        }
        .frame(width: 340, height: 400)
        .background(
            ZStack {
                VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                Color.black.opacity(0.15)
            }
        )
    }

    // MARK: Header

    private var headerSection: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.cpuStart)
                .frame(width: 6, height: 6)
                .shadow(color: Color.cpuStart.opacity(0.6), radius: 4, x: 0, y: 0)

            Text("Activity")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.primary.opacity(0.85))

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 14)
    }

    // MARK: Gauges

    private var gaugesSection: some View {
        HStack(spacing: 16) {
            GaugeCard(
                value: monitor.cpuUsage,
                title: "CPU",
                icon: "bolt.fill",
                gradientColors: cpuGradient(for: monitor.cpuUsage)
            )
            GaugeCard(
                value: monitor.memoryUsage,
                title: "Memory",
                icon: "memorychip",
                gradientColors: memGradient(for: monitor.memoryUsage)
            )
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    // MARK: Processes

    private var processesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("TOP PROCESSES")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(.dimText)
                .kerning(0.8)
                .padding(.horizontal, 22)
                .padding(.bottom, 10)

            if monitor.topProcesses.isEmpty {
                HStack(spacing: 8) {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.55)
                    Text("Loading...")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.dimText)
                    Spacer()
                }
                .padding(.vertical, 24)
            } else {
                // Glass card for process list
                VStack(spacing: 1) {
                    ForEach(monitor.topProcesses) { proc in
                        ProcessRow(process: proc)
                    }
                }
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.glassFill)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Color.glassStroke, lineWidth: 0.5)
                        )
                )
                .padding(.horizontal, 14)
            }
        }
    }

    // Dynamic gradient: green at low, orange at mid, red at high
    private func cpuGradient(for value: Double) -> [Color] {
        if value > 75 {
            return [.hotStart, .hotEnd]
        } else if value > 45 {
            return [.memStart, .memEnd]
        } else {
            return [.cpuStart, .cpuEnd]
        }
    }

    private func memGradient(for value: Double) -> [Color] {
        if value > 85 {
            return [.hotStart, .hotEnd]
        } else if value > 65 {
            return [.memStart, .memEnd]
        } else {
            return [.memStart, .memEnd]
        }
    }
}

// MARK: - Gauge Card

struct GaugeCard: View {
    let value: Double
    let title: String
    let icon: String
    let gradientColors: [Color]

    private let ringSize: CGFloat = 80
    private let ringWidth: CGFloat = 5.5

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                // Glow behind ring
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [gradientColors.first!.opacity(0.25), Color.clear],
                            center: .center,
                            startRadius: ringSize * 0.2,
                            endRadius: ringSize * 0.6
                        )
                    )
                    .frame(width: ringSize + 20, height: ringSize + 20)

                // Track
                Circle()
                    .stroke(Color.white.opacity(0.07), lineWidth: ringWidth)
                    .frame(width: ringSize, height: ringSize)

                // Progress
                Circle()
                    .trim(from: 0, to: CGFloat(min(value / 100, 1.0)))
                    .stroke(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                    )
                    .frame(width: ringSize, height: ringSize)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.75), value: value)

                // Center value
                VStack(spacing: 1) {
                    Text("\(Int(value))")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.primary.opacity(0.9))
                }
            }

            // Label
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(gradientColors.first!)
                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.glassFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(0.22), Color.white.opacity(0.06)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                )
        )
    }
}

// MARK: - Process Row

struct ProcessRow: View {
    let process: MonitoredProcess
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 10) {
            // App icon
            Group {
                if let icon = process.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .interpolation(.high)
                } else {
                    Image(systemName: "app.dashed")
                        .resizable()
                        .foregroundColor(.primary.opacity(0.25))
                }
            }
            .frame(width: 20, height: 20)
            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))

            Text(process.name)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.primary.opacity(0.8))
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            Text(String(format: "%.1f", process.cpuUsage))
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(usageColor(process.cpuUsage))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isHovering ? Color.glassFillHover : Color.clear)
        )
        .onHover { h in
            withAnimation(.easeOut(duration: 0.1)) { isHovering = h }
        }
    }

    private func usageColor(_ v: Double) -> Color {
        if v > 50 { return Color.hotStart }
        if v > 20 { return Color.memStart }
        return .primary.opacity(0.45)
    }
}

// MARK: - NSVisualEffectView Bridge

struct VisualEffectBlur: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = material
        v.blendingMode = blendingMode
        v.state = .active
        v.isEmphasized = true
        return v
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
