import SwiftUI
import AppKit

struct MonitorView: View {
    @ObservedObject var sysMonitor = SystemMonitor.shared
    @ObservedObject var procManager = ProcessManager.shared
    @ObservedObject var settings = SettingsStore.shared
    
    @State private var selectedTab: Int = 0 // 0: CPU, 1: RAM
    @State private var showSettings: Bool = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "cpu.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.cyan)
                    Text("LiteStats")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                }
                
                Spacer()
                
                Button(action: {
                    sysMonitor.updateStats()
                    procManager.refreshProcesses()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.plain)
                .help(settings.l10n("Refresh", "刷新"))
                
                Button(action: { showSettings.toggle() }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(showSettings ? .accentColor : .primary)
                }
                .buttonStyle(.plain)
                .help(settings.l10n("Preferences", "偏好设置"))
                
                Button(action: { NSApplication.shared.terminate(nil) }) {
                    Image(systemName: "power")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.red.opacity(0.8))
                }
                .buttonStyle(.plain)
                .help(settings.l10n("Quit App", "退出程序"))
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            
            Divider()
                .opacity(0.3)
            
            if showSettings {
                SettingsView(showSettings: $showSettings)
                    .padding(.horizontal, 12)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 12) {
                        // Overview Cards (CPU & RAM)
                        HStack(spacing: 10) {
                            // CPU Card
                            MetricCard(
                                title: settings.l10n("CPU Load", "CPU 负载"),
                                value: String(format: "%.1f%%", sysMonitor.totalCPUUsage * 100),
                                icon: "bolt.fill",
                                color: .cyan,
                                progress: sysMonitor.totalCPUUsage,
                                history: sysMonitor.cpuHistory
                            )
                            
                            // RAM Card
                            MetricCard(
                                title: settings.l10n("Memory Usage", "内存 占用"),
                                value: String(format: "%.1f%%", sysMonitor.memoryData.usagePercentage * 100),
                                icon: "memorychip",
                                color: .purple,
                                progress: sysMonitor.memoryData.usagePercentage,
                                history: sysMonitor.ramHistory
                            )
                        }
                        
                        // Fan Speed Section
                        if !sysMonitor.fanInfos.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "fanblades.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                    Text(settings.l10n("Fan Speeds", "风扇转速"))
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                
                                HStack(spacing: 12) {
                                    ForEach(sysMonitor.fanInfos) { fan in
                                        HStack(spacing: 4) {
                                            Text(fan.name + ":")
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundColor(.secondary)
                                            Text("\(fan.rpm) RPM")
                                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                                .foregroundColor(.primary)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                            }
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.04)))
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
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.02)))
                        }
                        
                        // Per-Core Grid
                        VStack(alignment: .leading, spacing: 6) {
                            Text(settings.l10n("CPU Cores (\(sysMonitor.coreUsages.count) Cores)", "CPU 核心状态 (\(sysMonitor.coreUsages.count) 核心)"))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
                                ForEach(sysMonitor.coreUsages) { core in
                                    HStack(spacing: 4) {
                                        Text("C\(core.id)")
                                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                                            .foregroundColor(.secondary)
                                            .frame(width: 18, alignment: .leading)
                                        
                                        GeometryReader { geo in
                                            ZStack(alignment: .leading) {
                                                RoundedRectangle(cornerRadius: 3)
                                                    .fill(Color.primary.opacity(0.1))
                                                RoundedRectangle(cornerRadius: 3)
                                                    .fill(coreColor(core.usage))
                                                    .frame(width: geo.size.width * CGFloat(core.usage))
                                            }
                                        }
                                        .frame(height: 8)
                                    }
                                }
                            }
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.04)))
                        
                        // Memory Breakdown
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(settings.l10n("Memory Distribution", "内存使用分布"))
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(sysMonitor.memoryData.formattedUsed) / \(sysMonitor.memoryData.formattedTotal)")
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            
                            // Multi-color Segmented Progress Bar
                            GeometryReader { geo in
                                HStack(spacing: 1) {
                                    let total = Double(max(sysMonitor.memoryData.totalBytes, 1))
                                    let activeW = CGFloat(Double(sysMonitor.memoryData.activeBytes) / total) * geo.size.width
                                    let wiredW = CGFloat(Double(sysMonitor.memoryData.wiredBytes) / total) * geo.size.width
                                    let compW = CGFloat(Double(sysMonitor.memoryData.compressedBytes) / total) * geo.size.width
                                    
                                    Rectangle().fill(Color.blue).frame(width: max(activeW, 0))
                                    Rectangle().fill(Color.orange).frame(width: max(wiredW, 0))
                                    Rectangle().fill(Color.purple).frame(width: max(compW, 0))
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .background(RoundedRectangle(cornerRadius: 4).fill(Color.primary.opacity(0.1)))
                            }
                            .frame(height: 8)
                            
                            HStack(spacing: 8) {
                                LegendItem(color: .blue, text: "App: \(sysMonitor.memoryData.formattedActive)")
                                LegendItem(color: .orange, text: "Wired: \(sysMonitor.memoryData.formattedWired)")
                                LegendItem(color: .purple, text: settings.l10n("Compressed: ", "压缩: ") + sysMonitor.memoryData.formattedCompressed)
                            }
                            .font(.system(size: 9))
                            
                            if sysMonitor.memoryData.swapUsedBytes > 0 {
                                Text(settings.l10n("Swap Memory: ", "交换内存 (Swap): ") + sysMonitor.memoryData.formattedSwap)
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(.yellow)
                            }
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.04)))
                        
                        // Top Processes Section
                        if settings.showTopProcesses {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Picker("", selection: $selectedTab) {
                                        Text(settings.l10n("CPU Leaders", "CPU 占用榜")).tag(0)
                                        Text(settings.l10n("RAM Leaders", "内存占用榜")).tag(1)
                                    }
                                    .pickerStyle(.segmented)
                                    .labelsHidden()
                                }
                                
                                let processes = selectedTab == 0 ? procManager.topCPUProcesses : procManager.topRAMProcesses
                                
                                ForEach(processes) { item in
                                    HStack(spacing: 6) {
                                        if let icon = item.icon {
                                            Image(nsImage: icon)
                                                .resizable()
                                                .frame(width: 14, height: 14)
                                        } else {
                                            Image(systemName: "app.fill")
                                                .font(.system(size: 10))
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
                                                .font(.system(size: 11))
                                                .foregroundColor(.red.opacity(0.7))
                                        }
                                        .buttonStyle(.plain)
                                        .help(settings.l10n("Force Terminate (PID \(item.id))", "强行结束 (PID \(item.id))"))
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.04)))
                        }
                        
                        // Footer Quick Launch
                        Button(action: {
                            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app"))
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "macwindow")
                                Text(settings.l10n("Open Activity Monitor", "打开 macOS 活动监视器"))
                            }
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.accentColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 6).stroke(Color.accentColor.opacity(0.4), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                }
            }
        }
        .frame(width: 320, height: 440)
        .onAppear {
            procManager.refreshProcesses()
        }
    }
    
    private func coreColor(_ usage: Double) -> Color {
        if usage > 0.8 { return .red }
        if usage > 0.5 { return .yellow }
        return .cyan
    }
}

// MARK: - Metric Card
struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let progress: Double
    let history: [Double]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 12, weight: .bold))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
                Text(value)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            }
            
            // Mini Sparkline Graph
            SparklineView(data: history, color: color)
                .frame(height: 24)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.04)))
    }
}

// MARK: - Sparkline Chart
struct SparklineView: View {
    let data: [Double]
    let color: Color
    
    var body: some View {
        GeometryReader { geo in
            if data.count > 1 {
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
                .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
            }
        }
    }
}

// MARK: - Legend Item
struct LegendItem: View {
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 3) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(text).foregroundColor(.secondary)
        }
    }
}

// MARK: - Settings View Inside Popover (Redesigned Full-Width Aligned Cards)
struct SettingsView: View {
    @Binding var showSettings: Bool
    @ObservedObject var settings = SettingsStore.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(settings.l10n("Preferences", "偏好设置"))
                    .font(.system(size: 13, weight: .bold))
                Spacer()
                Button(settings.l10n("Done", "完成")) { showSettings = false }
                    .font(.system(size: 11, weight: .semibold))
            }
            
            Divider()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 10) {
                    // Language Selector Card
                    VStack(alignment: .leading, spacing: 6) {
                        Text(settings.l10n("Language", "显示语言"))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        Picker("", selection: $settings.appLanguageRaw) {
                            ForEach(AppLanguage.allCases) { lang in
                                Text(lang.rawValue).tag(lang.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.04)))
                    
                    // Startup Card
                    VStack(alignment: .leading, spacing: 6) {
                        Text(settings.l10n("Startup", "启动设置"))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        Toggle(settings.l10n("Launch at Login", "开机自动启动"), isOn: $settings.launchAtLogin)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.04)))
                    
                    // Status Bar Items Card
                    VStack(alignment: .leading, spacing: 6) {
                        Text(settings.l10n("Status Bar Items", "任务栏常驻项目"))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Toggle(settings.l10n("CPU Usage", "CPU 占用率"), isOn: $settings.showCPUInStatus)
                                .font(.system(size: 11, weight: .medium))
                            
                            Toggle(settings.l10n("Memory Usage", "内存 占用率"), isOn: $settings.showRAMInStatus)
                                .font(.system(size: 11, weight: .medium))
                            
                            Toggle(settings.l10n("Fan Speed", "风扇 转速"), isOn: $settings.showFanInStatus)
                                .font(.system(size: 11, weight: .medium))
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.04)))
                    
                    // Refresh Rate Card
                    VStack(alignment: .leading, spacing: 6) {
                        Text(settings.l10n("Refresh Interval", "采样刷新频率"))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        Picker("", selection: $settings.refreshInterval) {
                            Text(settings.l10n("1s (High)", "1秒 (高精度)")).tag(1.0)
                            Text(settings.l10n("2s (Default)", "2秒 (推荐)")).tag(2.0)
                            Text(settings.l10n("5s (Energy Saver)", "5秒 (省电模式)")).tag(5.0)
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.04)))
                    
                    // Top Processes Card
                    VStack(alignment: .leading, spacing: 6) {
                        Text(settings.l10n("Features", "高级功能"))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        Toggle(settings.l10n("Show Top Processes Leaderboard", "展示 Top 进程占用榜单"), isOn: $settings.showTopProcesses)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.04)))
                }
            }
        }
        .padding(.vertical, 4)
    }
}
