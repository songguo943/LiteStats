import SwiftUI
import AppKit

struct MonitorView: View {
    @ObservedObject var sysMonitor = SystemMonitor.shared
    @ObservedObject var procManager = ProcessManager.shared
    @ObservedObject var settings = SettingsStore.shared
    
    @State private var selectedTab: Int = 0 // 0: CPU, 1: RAM
    @State private var showSettings: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Top App Bar
            HStack(spacing: 8) {
                // App Logo Badge
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.primary.opacity(0.12))
                        .frame(width: 24, height: 24)
                    Image(systemName: "cpu.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.cyan)
                }
                
                Text("LiteStats")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: {
                        sysMonitor.updateStats()
                        procManager.refreshProcesses()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help(settings.l10n("Refresh", "刷新"))
                    
                    Button(action: { showSettings.toggle() }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(showSettings ? .accentColor : .secondary)
                    }
                    .buttonStyle(.plain)
                    .help(settings.l10n("Preferences", "偏好设置"))
                    
                    Button(action: { NSApplication.shared.terminate(nil) }) {
                        Image(systemName: "power")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.red.opacity(0.85))
                    }
                    .buttonStyle(.plain)
                    .help(settings.l10n("Quit App", "退出程序"))
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 10)
            
            Divider()
                .opacity(0.2)
            
            if showSettings {
                SettingsView(showSettings: $showSettings)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 10) {
                        // Overview Cards (CPU Load & Memory Usage)
                        HStack(spacing: 10) {
                            MetricCard(
                                title: settings.l10n("CPU Load", "CPU 负载"),
                                value: String(format: "%.1f%%", sysMonitor.totalCPUUsage * 100),
                                icon: "bolt.fill",
                                color: .cyan,
                                subtitle: nil,
                                history: sysMonitor.cpuHistory
                            )
                            
                            MetricCard(
                                title: settings.l10n("Memory Usage", "内存 占用"),
                                value: String(format: "%.1f%%", sysMonitor.memoryData.usagePercentage * 100),
                                icon: "memorychip.fill",
                                color: .purple,
                                subtitle: "\(sysMonitor.memoryData.formattedUsed) / \(sysMonitor.memoryData.formattedTotal)",
                                history: sysMonitor.ramHistory
                            )
                        }
                        
                        // Per-Core CPU Usage Card
                        VStack(alignment: .leading, spacing: 8) {
                            Text(settings.l10n("CPU Per-Core Usage", "CPU 核心负载分布"))
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                                ForEach(sysMonitor.coreUsages) { core in
                                    VStack(alignment: .leading, spacing: 3) {
                                        HStack {
                                            Text("C\(core.id)")
                                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                                .foregroundColor(.secondary)
                                            Spacer()
                                            Text(String(format: "%.0f%%", core.usage * 100))
                                                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                                .foregroundColor(coreColor(core.usage))
                                        }
                                        
                                        GeometryReader { geo in
                                            ZStack(alignment: .leading) {
                                                Capsule()
                                                    .fill(Color.primary.opacity(0.1))
                                                Capsule()
                                                    .fill(coreColor(core.usage))
                                                    .frame(width: geo.size.width * CGFloat(core.usage))
                                            }
                                        }
                                        .frame(height: 5)
                                    }
                                }
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.primary.opacity(0.04))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.06), lineWidth: 1))
                        )
                        
                        // Fan Speeds Card
                        if !sysMonitor.fanInfos.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "fanblades.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                    Text(settings.l10n("Fan Speeds", "风扇转速"))
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                
                                HStack(spacing: 12) {
                                    ForEach(sysMonitor.fanInfos) { fan in
                                        HStack(spacing: 8) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color.primary.opacity(0.08))
                                                    .frame(width: 26, height: 26)
                                                Image(systemName: "fanblades")
                                                    .font(.system(size: 13))
                                                    .foregroundColor(.accentColor)
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 1) {
                                                Text(fan.name)
                                                    .font(.system(size: 10, weight: .medium))
                                                    .foregroundColor(.secondary)
                                                Text("\(fan.rpm) RPM")
                                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                                    .foregroundColor(.primary)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.primary.opacity(0.04))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.06), lineWidth: 1))
                            )
                        } else {
                            HStack(spacing: 6) {
                                Image(systemName: "fanblades")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                Text(settings.l10n("Cooling System: Fanless", "散热系统: 无风扇静音架构"))
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.03)))
                        }
                        
                        // Memory Breakdown Card
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(settings.l10n("Memory Breakdown", "内存分布"))
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(String(format: "%.1f%% used", sysMonitor.memoryData.usagePercentage * 100))
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            
                            // Segmented Bar
                            GeometryReader { geo in
                                HStack(spacing: 2) {
                                    let total = Double(max(sysMonitor.memoryData.totalBytes, 1))
                                    let activeW = CGFloat(Double(sysMonitor.memoryData.activeBytes) / total) * geo.size.width
                                    let wiredW = CGFloat(Double(sysMonitor.memoryData.wiredBytes) / total) * geo.size.width
                                    let compW = CGFloat(Double(sysMonitor.memoryData.compressedBytes) / total) * geo.size.width
                                    
                                    Capsule().fill(Color.blue).frame(width: max(activeW, 0))
                                    Capsule().fill(Color.orange).frame(width: max(wiredW, 0))
                                    Capsule().fill(Color.purple).frame(width: max(compW, 0))
                                }
                                .clipShape(Capsule())
                                .background(Capsule().fill(Color.primary.opacity(0.1)))
                            }
                            .frame(height: 8)
                            
                            HStack(spacing: 12) {
                                LegendItem(color: .blue, text: "App: \(sysMonitor.memoryData.formattedActive)")
                                LegendItem(color: .orange, text: "Wired: \(sysMonitor.memoryData.formattedWired)")
                                LegendItem(color: .purple, text: "Compressed: \(sysMonitor.memoryData.formattedCompressed)")
                            }
                            .font(.system(size: 9))
                            
                            if sysMonitor.memoryData.swapUsedBytes > 0 {
                                Text(settings.l10n("Swap Memory: ", "交换内存: ") + sysMonitor.memoryData.formattedSwap)
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(.yellow)
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.primary.opacity(0.04))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.06), lineWidth: 1))
                        )
                        
                        // Top Processes Section
                        if settings.showTopProcesses {
                            VStack(alignment: .leading, spacing: 8) {
                                Picker("", selection: $selectedTab) {
                                    Text(settings.l10n("CPU Leaders", "CPU 占用榜")).tag(0)
                                    Text(settings.l10n("RAM Leaders", "内存占用榜")).tag(1)
                                }
                                .pickerStyle(.segmented)
                                .labelsHidden()
                                
                                let processes = selectedTab == 0 ? procManager.topCPUProcesses : procManager.topRAMProcesses
                                
                                ForEach(processes) { item in
                                    HStack(spacing: 8) {
                                        if let icon = item.icon {
                                            Image(nsImage: icon)
                                                .resizable()
                                                .frame(width: 16, height: 16)
                                        } else {
                                            Image(systemName: "app.fill")
                                                .font(.system(size: 11))
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Text(item.name)
                                            .font(.system(size: 11, weight: .medium))
                                            .lineLimit(1)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        Text(selectedTab == 0 ? String(format: "%.1f%%", item.cpuUsagePercentage) : item.formattedMemory)
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .foregroundColor(selectedTab == 0 ? .cyan : .purple)
                                        
                                        Button(action: { procManager.killProcess(pid: item.id) }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 12))
                                                .foregroundColor(.red.opacity(0.75))
                                        }
                                        .buttonStyle(.plain)
                                        .help(settings.l10n("Force Terminate (PID \(item.id))", "强行结束 (PID \(item.id))"))
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.primary.opacity(0.04))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.06), lineWidth: 1))
                            )
                        }
                        
                        // Footer Action Button
                        Button(action: {
                            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app"))
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "macwindow")
                                Text(settings.l10n("Open Activity Monitor", "打开 Activity Monitor"))
                            }
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.accentColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.accentColor.opacity(0.08))
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.accentColor.opacity(0.3), lineWidth: 1))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                }
            }
        }
        .frame(width: 325, height: 455)
        .onAppear {
            procManager.refreshProcesses()
        }
    }
    
    private func coreColor(_ usage: Double) -> Color {
        if usage > 0.8 { return .red }
        if usage > 0.5 { return .orange }
        return .cyan
    }
}

// MARK: - Metric Card (With Gradient Lines & Subtitles)
struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let subtitle: String?
    let history: [Double]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 12, weight: .bold))
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            if let sub = subtitle {
                Text(sub)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            // Mini Sparkline Graph with Area Gradient
            SparklineView(data: history, color: color)
                .frame(height: 28)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.primary.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.06), lineWidth: 1))
        )
    }
}

// MARK: - Sparkline Chart with Smooth Line & Filled Area
struct SparklineView: View {
    let data: [Double]
    let color: Color
    
    var body: some View {
        GeometryReader { geo in
            if data.count > 1 {
                ZStack {
                    // Area Gradient Fill
                    Path { path in
                        let step = geo.size.width / CGFloat(data.count - 1)
                        path.move(to: CGPoint(x: 0, y: geo.size.height))
                        for i in 0..<data.count {
                            let x = CGFloat(i) * step
                            let y = geo.size.height * (1.0 - CGFloat(data[i]))
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                        path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.25), color.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // Line Stroke
                    Path { path in
                        let step = geo.size.width / CGFloat(data.count - 1)
                        for i in 0..<data.count {
                            let x = CGFloat(i) * step
                            let y = geo.size.height * (1.0 - CGFloat(data[i]))
                            if i == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(color, style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
                }
            }
        }
    }
}

// MARK: - Legend Item
struct LegendItem: View {
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(text).foregroundColor(.secondary)
        }
    }
}

// MARK: - Settings View (Redesigned Glass Cards & Icon Badges)
struct SettingsView: View {
    @Binding var showSettings: Bool
    @ObservedObject var settings = SettingsStore.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header Bar
            HStack {
                Text(settings.l10n("Preferences", "偏好设置"))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
                Button(action: { showSettings = false }) {
                    Text(settings.l10n("Done", "完成"))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.accentColor))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
            .padding(.top, 2)
            
            Divider()
                .opacity(0.3)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 10) {
                    // Language Selector Card
                    SettingsCard(icon: "globe", title: settings.l10n("Language", "显示语言")) {
                        Picker("", selection: $settings.appLanguageRaw) {
                            ForEach(AppLanguage.allCases) { lang in
                                Text(lang.rawValue).tag(lang.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // Startup Card
                    SettingsCard(icon: "rocket.fill", title: settings.l10n("Startup", "启动设置")) {
                        Toggle(settings.l10n("Launch at Login", "开机自动启动"), isOn: $settings.launchAtLogin)
                            .font(.system(size: 11, weight: .medium))
                    }
                    
                    // Status Bar Items Card
                    SettingsCard(icon: "chart.bar.fill", title: settings.l10n("Status Bar Items", "任务栏常驻项目")) {
                        VStack(alignment: .leading, spacing: 6) {
                            Toggle(settings.l10n("CPU Usage", "CPU 占用率"), isOn: $settings.showCPUInStatus)
                                .font(.system(size: 11, weight: .medium))
                            
                            Toggle(settings.l10n("Memory Usage", "内存 占用率"), isOn: $settings.showRAMInStatus)
                                .font(.system(size: 11, weight: .medium))
                            
                            Toggle(settings.l10n("Fan Speed", "风扇 转速"), isOn: $settings.showFanInStatus)
                                .font(.system(size: 11, weight: .medium))
                        }
                    }
                    
                    // Refresh Rate Card
                    SettingsCard(icon: "timer", title: settings.l10n("Refresh Interval", "采样刷新频率")) {
                        Picker("", selection: $settings.refreshInterval) {
                            Text(settings.l10n("1s (High)", "1秒 (高精度)")).tag(1.0)
                            Text(settings.l10n("2s (Default)", "2秒 (推荐)")).tag(2.0)
                            Text(settings.l10n("5s (Energy Saver)", "5秒 (省电模式)")).tag(5.0)
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // Top Processes Card
                    SettingsCard(icon: "sparkles", title: settings.l10n("Features", "高级功能")) {
                        Toggle(settings.l10n("Show Top Processes Leaderboard", "展示 Top 进程占用榜单"), isOn: $settings.showTopProcesses)
                            .font(.system(size: 11, weight: .medium))
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }
}

// MARK: - Reusable Settings Card Container with Icon Badge
struct SettingsCard<Content: View>: View {
    let icon: String
    let title: String
    let content: Content
    
    init(icon: String, title: String, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
            }
            
            content
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.primary.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.06), lineWidth: 1))
        )
    }
}
