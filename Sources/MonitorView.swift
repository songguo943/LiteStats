import SwiftUI
import AppKit

struct MonitorView: View {
    @ObservedObject var sysMonitor = SystemMonitor.shared
    @ObservedObject var procManager = ProcessManager.shared
    @ObservedObject var settings = SettingsStore.shared
    
    @State private var showSettings: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack(spacing: 10) {
                // Logo Badge [L]
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(white: 0.2))
                        .frame(width: 24, height: 24)
                    Text("L")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Text("LiteStats")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: {
                        sysMonitor.updateStats()
                        procManager.refreshProcesses()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    .help(settings.l10n("Refresh", "刷新"))
                    
                    Button(action: { showSettings.toggle() }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(showSettings ? .cyan : Color.white.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    .help(settings.l10n("Preferences", "偏好设置"))
                    
                    Button(action: { NSApplication.shared.terminate(nil) }) {
                        Image(systemName: "power")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.red.opacity(0.85))
                    }
                    .buttonStyle(.plain)
                    .help(settings.l10n("Quit App", "退出程序"))
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 10)
            
            Divider()
                .background(Color.white.opacity(0.12))
            
            if showSettings {
                SettingsView(showSettings: $showSettings)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 10) {
                        // Overview Cards (CPU Load & Memory Usage)
                        HStack(spacing: 10) {
                            DarkMetricCard(
                                title: settings.l10n("CPU Load", "CPU 负载"),
                                value: String(format: "%.1f%%", sysMonitor.totalCPUUsage * 100),
                                icon: "bolt.fill",
                                color: .cyan,
                                gradientColors: [Color.orange, Color.red],
                                subtitle: nil,
                                history: sysMonitor.cpuHistory
                            )
                            
                            DarkMetricCard(
                                title: settings.l10n("Memory Usage", "内存 占用"),
                                value: String(format: "%.1f%%", sysMonitor.memoryData.usagePercentage * 100),
                                icon: "memorychip.fill",
                                color: .blue,
                                gradientColors: [Color.blue, Color.cyan],
                                subtitle: "\(sysMonitor.memoryData.formattedUsed) / \(sysMonitor.memoryData.formattedTotal)",
                                history: sysMonitor.ramHistory
                            )
                        }
                        
                        // Per Core Grid Card
                        VStack(alignment: .leading, spacing: 8) {
                            Text(settings.l10n("CPU Per-Core Usage", "CPU 核心负载分布"))
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color.white.opacity(0.7))
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                                ForEach(sysMonitor.coreUsages) { core in
                                    VStack(alignment: .leading, spacing: 3) {
                                        HStack {
                                            Text("C\(core.id)")
                                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                                .foregroundColor(Color.white.opacity(0.5))
                                            Spacer()
                                            Text(String(format: "%.0f%%", core.usage * 100))
                                                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                                .foregroundColor(coreColor(core.usage))
                                        }
                                        
                                        GeometryReader { geo in
                                            ZStack(alignment: .leading) {
                                                Capsule()
                                                    .fill(Color.white.opacity(0.1))
                                                Capsule()
                                                    .fill(coreColor(core.usage))
                                                    .frame(width: geo.size.width * CGFloat(core.usage))
                                            }
                                        }
                                        .frame(height: 4)
                                    }
                                }
                            }
                        }
                        .padding(12)
                        .background(DarkCardBackground())
                        
                        // Fan Speeds Card
                        if !sysMonitor.fanInfos.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "fanblades.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color.white.opacity(0.7))
                                    Text(settings.l10n("Fan Speeds", "风扇转速"))
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(Color.white.opacity(0.7))
                                    Spacer()
                                }
                                
                                HStack(spacing: 12) {
                                    ForEach(sysMonitor.fanInfos) { fan in
                                        HStack(spacing: 8) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color.white.opacity(0.08))
                                                    .frame(width: 28, height: 28)
                                                Image(systemName: "fanblades")
                                                    .font(.system(size: 13))
                                                    .foregroundColor(.white)
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 1) {
                                                Text("\(fanLabel(id: fan.id, count: sysMonitor.fanInfos.count)):")
                                                    .font(.system(size: 11, weight: .semibold))
                                                    .foregroundColor(Color.white.opacity(0.9))
                                                Text("\(fan.rpm) RPM")
                                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                                    .foregroundColor(.white)
                                                Text(fan.rpm > 0 ? settings.l10n("Fan Active", "正常运转") : settings.l10n("Fan Silent", "静音停转"))
                                                    .font(.system(size: 9, weight: .medium))
                                                    .foregroundColor(Color.white.opacity(0.5))
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                            }
                            .padding(12)
                            .background(DarkCardBackground())
                        } else {
                            HStack(spacing: 6) {
                                Image(systemName: "fanblades")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.white.opacity(0.6))
                                Text(settings.l10n("Cooling System: Fanless", "散热系统: 无风扇静音架构"))
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(Color.white.opacity(0.6))
                                Spacer()
                            }
                            .padding(10)
                            .background(DarkCardBackground())
                        }
                        
                        // Memory Breakdown Card
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(settings.l10n("Memory Breakdown", "内存分布"))
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Color.white.opacity(0.7))
                                Spacer()
                                Text(String(format: "%.1f%% used", sysMonitor.memoryData.usagePercentage * 100))
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .foregroundColor(Color.white.opacity(0.5))
                            }
                            
                            // Multi-color Segmented Bar (Green / Orange / Purple)
                            GeometryReader { geo in
                                HStack(spacing: 2) {
                                    let total = Double(max(sysMonitor.memoryData.totalBytes, 1))
                                    let activeW = CGFloat(Double(sysMonitor.memoryData.activeBytes) / total) * geo.size.width
                                    let wiredW = CGFloat(Double(sysMonitor.memoryData.wiredBytes) / total) * geo.size.width
                                    let compW = CGFloat(Double(sysMonitor.memoryData.compressedBytes) / total) * geo.size.width
                                    
                                    Capsule().fill(Color(red: 0.2, green: 0.78, blue: 0.35)).frame(width: max(activeW, 0))
                                    Capsule().fill(Color(red: 1.0, green: 0.58, blue: 0.0)).frame(width: max(wiredW, 0))
                                    Capsule().fill(Color(red: 0.69, green: 0.32, blue: 0.87)).frame(width: max(compW, 0))
                                }
                                .clipShape(Capsule())
                                .background(Capsule().fill(Color.white.opacity(0.1)))
                            }
                            .frame(height: 8)
                            
                            HStack(spacing: 12) {
                                LegendItem(color: Color(red: 0.2, green: 0.78, blue: 0.35), text: settings.l10n("App Memory", "App 内存"))
                                LegendItem(color: Color(red: 1.0, green: 0.58, blue: 0.0), text: settings.l10n("Wired", "紧致内存"))
                                LegendItem(color: Color(red: 0.69, green: 0.32, blue: 0.87), text: settings.l10n("Compressed", "已压缩"))
                            }
                            .font(.system(size: 9))
                            
                            if sysMonitor.memoryData.swapUsedBytes > 0 {
                                Text(settings.l10n("Swap Memory: ", "交换内存: ") + sysMonitor.memoryData.formattedSwap)
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(.yellow)
                            }
                        }
                        .padding(12)
                        .background(DarkCardBackground())
                        
                        // Dual-Column Top Processes Section (CPU & RAM Side-by-Side)
                        if settings.showTopProcesses {
                            HStack(alignment: .top, spacing: 10) {
                                // CPU Processes Column
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(settings.l10n("CPU Processes", "CPU 资源占用"))
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(Color.white.opacity(0.7))
                                    
                                    ForEach(Array(procManager.topCPUProcesses.prefix(3))) { item in
                                        HStack(spacing: 4) {
                                            if let icon = item.icon {
                                                Image(nsImage: icon)
                                                    .resizable()
                                                    .frame(width: 14, height: 14)
                                            } else {
                                                Image(systemName: "app.fill")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(Color.white.opacity(0.5))
                                            }
                                            
                                            Text(item.name)
                                                .font(.system(size: 10, weight: .medium))
                                                .foregroundColor(.white)
                                                .lineLimit(1)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            
                                            Text(String(format: "%.1f%%", item.cpuUsagePercentage))
                                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                                .foregroundColor(.cyan)
                                        }
                                    }
                                }
                                .padding(10)
                                .frame(maxWidth: .infinity)
                                .background(DarkCardBackground())
                                
                                // RAM Processes Column
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(settings.l10n("Memory Processes", "内存 资源占用"))
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(Color.white.opacity(0.7))
                                    
                                    ForEach(Array(procManager.topRAMProcesses.prefix(3))) { item in
                                        HStack(spacing: 4) {
                                            if let icon = item.icon {
                                                Image(nsImage: icon)
                                                    .resizable()
                                                    .frame(width: 14, height: 14)
                                            } else {
                                                Image(systemName: "app.fill")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(Color.white.opacity(0.5))
                                            }
                                            
                                            Text(item.name)
                                                .font(.system(size: 10, weight: .medium))
                                                .foregroundColor(.white)
                                                .lineLimit(1)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            
                                            Text(item.formattedMemory)
                                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                                .foregroundColor(.purple)
                                        }
                                    }
                                }
                                .padding(10)
                                .frame(maxWidth: .infinity)
                                .background(DarkCardBackground())
                            }
                        }
                        
                        // Footer Quick Launch
                        Button(action: {
                            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app"))
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "macwindow")
                                Text(settings.l10n("Open Activity Monitor", "打开 Activity Monitor"))
                            }
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.cyan)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.cyan.opacity(0.1))
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.cyan.opacity(0.3), lineWidth: 1))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                }
            }
        }
        .frame(width: 340, height: 500)
        .preferredColorScheme(.dark)
        .onAppear {
            procManager.refreshProcesses()
        }
    }
    
    private func fanLabel(id: Int, count: Int) -> String {
        if count == 1 {
            return settings.l10n("CPU Fan", "CPU 风扇")
        }
        return id == 0 ? settings.l10n("Left Fan", "左风扇") : settings.l10n("Right Fan", "右风扇")
    }
    
    private func coreColor(_ usage: Double) -> Color {
        if usage > 0.8 { return .red }
        if usage > 0.5 { return .orange }
        return .cyan
    }
}

// MARK: - Dark Card Background Helper
struct DarkCardBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(white: 0.12, opacity: 0.85))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}

// MARK: - Dark Metric Card with Multi-Color Gradient Lines
struct DarkMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let gradientColors: [Color]
    let subtitle: String?
    let history: [Double]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 12, weight: .bold))
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.7))
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            if let sub = subtitle {
                Text(sub)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.5))
            } else {
                Spacer().frame(height: 11)
            }
            
            // Sparkline Graph
            GradientSparklineView(data: history, colors: gradientColors)
                .frame(height: 32)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DarkCardBackground())
    }
}

// MARK: - Gradient Sparkline View
struct GradientSparklineView: View {
    let data: [Double]
    let colors: [Color]
    
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
                            colors: [(colors.first ?? .cyan).opacity(0.3), (colors.last ?? .blue).opacity(0.02)],
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
                    .stroke(
                        LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 2.0, lineCap: .round, lineJoin: .round)
                    )
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
            Text(text).foregroundColor(Color.white.opacity(0.7))
        }
    }
}

// MARK: - Settings View (Dark Glass Theme)
struct SettingsView: View {
    @Binding var showSettings: Bool
    @ObservedObject var settings = SettingsStore.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header Bar
            HStack {
                Text(settings.l10n("Preferences", "偏好设置"))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button(action: { showSettings = false }) {
                    Text(settings.l10n("Done", "完成"))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.blue))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
            .padding(.top, 2)
            
            Divider()
                .background(Color.white.opacity(0.12))
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 10) {
                    // Language Selector Card
                    DarkSettingsCard(icon: "globe", title: settings.l10n("Language", "显示语言")) {
                        Picker("", selection: $settings.appLanguageRaw) {
                            ForEach(AppLanguage.allCases) { lang in
                                Text(lang.rawValue).tag(lang.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // Startup Card
                    DarkSettingsCard(icon: "rocket.fill", title: settings.l10n("Startup", "启动设置")) {
                        Toggle(settings.l10n("Launch at Login", "开机自动启动"), isOn: $settings.launchAtLogin)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    // Status Bar Items Card
                    DarkSettingsCard(icon: "chart.bar.fill", title: settings.l10n("Status Bar Items", "任务栏常驻项目")) {
                        VStack(alignment: .leading, spacing: 6) {
                            Toggle(settings.l10n("CPU Usage", "CPU 占用率"), isOn: $settings.showCPUInStatus)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white)
                            
                            Toggle(settings.l10n("Memory Usage", "内存 占用率"), isOn: $settings.showRAMInStatus)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white)
                            
                            Toggle(settings.l10n("Fan Speed", "风扇 转速"), isOn: $settings.showFanInStatus)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Refresh Rate Card
                    DarkSettingsCard(icon: "timer", title: settings.l10n("Refresh Interval", "采样刷新频率")) {
                        Picker("", selection: $settings.refreshInterval) {
                            Text(settings.l10n("1s (High)", "1秒 (高精度)")).tag(1.0)
                            Text(settings.l10n("2s (Default)", "2秒 (推荐)")).tag(2.0)
                            Text(settings.l10n("5s (Energy Saver)", "5秒 (省电模式)")).tag(5.0)
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // Top Processes Card
                    DarkSettingsCard(icon: "sparkles", title: settings.l10n("Features", "高级功能")) {
                        Toggle(settings.l10n("Show Top Processes Leaderboard", "展示 Top 进程占用榜单"), isOn: $settings.showTopProcesses)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }
}

// MARK: - Dark Settings Card
struct DarkSettingsCard<Content: View>: View {
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
                    .foregroundColor(.cyan)
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.7))
            }
            
            content
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DarkCardBackground())
    }
}
