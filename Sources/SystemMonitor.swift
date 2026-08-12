import Foundation
import Darwin
import Combine

struct CoreUsage: Identifiable {
    let id: Int
    let usage: Double // 0.0 ~ 1.0
}

struct MemoryData {
    let totalBytes: UInt64
    let usedBytes: UInt64
    let freeBytes: UInt64
    let activeBytes: UInt64
    let wiredBytes: UInt64
    let compressedBytes: UInt64
    let swapUsedBytes: UInt64
    let usagePercentage: Double // 0.0 ~ 1.0
    
    var formattedTotal: String { ByteCountFormatter.string(fromByteCount: Int64(totalBytes), countStyle: .memory) }
    var formattedUsed: String { ByteCountFormatter.string(fromByteCount: Int64(usedBytes), countStyle: .memory) }
    var formattedFree: String { ByteCountFormatter.string(fromByteCount: Int64(freeBytes), countStyle: .memory) }
    var formattedWired: String { ByteCountFormatter.string(fromByteCount: Int64(wiredBytes), countStyle: .memory) }
    var formattedCompressed: String { ByteCountFormatter.string(fromByteCount: Int64(compressedBytes), countStyle: .memory) }
    var formattedActive: String { ByteCountFormatter.string(fromByteCount: Int64(activeBytes), countStyle: .memory) }
    var formattedSwap: String { ByteCountFormatter.string(fromByteCount: Int64(swapUsedBytes), countStyle: .memory) }
}

private struct CPUTicks {
    let user: UInt64
    let system: UInt64
    let idle: UInt64
    let nice: UInt64
    
    var total: UInt64 { user + system + idle + nice }
    var active: UInt64 { user + system + nice }
}

final class SystemMonitor: ObservableObject {
    static let shared = SystemMonitor()
    
    @Published var totalCPUUsage: Double = 0.0 // 0.0 ~ 1.0
    @Published var coreUsages: [CoreUsage] = []
    @Published var fanInfos: [FanInfo] = []
    @Published var memoryData: MemoryData = MemoryData(
        totalBytes: 1, usedBytes: 0, freeBytes: 1,
        activeBytes: 0, wiredBytes: 0, compressedBytes: 0, swapUsedBytes: 0,
        usagePercentage: 0.0
    )
    
    @Published var cpuHistory: [Double] = Array(repeating: 0.0, count: 40)
    @Published var ramHistory: [Double] = Array(repeating: 0.0, count: 40)
    
    private var prevTotalTicks: CPUTicks?
    private var prevCoreTicks: [CPUTicks] = []
    
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        startMonitoring()
        
        // Listen to settings refresh interval changes
        SettingsStore.shared.$refreshInterval
            .dropFirst()
            .sink { [weak self] _ in
                self?.resetTimer()
            }
            .store(in: &cancellables)
    }
    
    func startMonitoring() {
        updateStats()
        resetTimer()
    }
    
    private func resetTimer() {
        timer?.invalidate()
        let interval = SettingsStore.shared.refreshInterval
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.updateStats()
        }
    }
    
    func updateStats() {
        updateCPUStats()
        updateMemoryStats()
        updateFanStats()
    }
    
    private func updateFanStats() {
        let fans = SMCReader.shared.getFanInfos()
        DispatchQueue.main.async {
            self.fanInfos = fans
        }
    }
    
    // MARK: - CPU Stats via Mach host_processor_info
    private func updateCPUStats() {
        var numCPUsU: natural_t = 0
        var cpuInfo: processor_info_array_t?
        var numCPUInfo: mach_msg_type_number_t = 0
        
        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &numCPUsU,
            &cpuInfo,
            &numCPUInfo
        )
        
        guard result == KERN_SUCCESS, let info = cpuInfo else { return }
        
        var currentTotalUser: UInt64 = 0
        var currentTotalSystem: UInt64 = 0
        var currentTotalIdle: UInt64 = 0
        var currentTotalNice: UInt64 = 0
        
        var currentCoreTicks: [CPUTicks] = []
        
        for i in 0..<Int(numCPUsU) {
            let base = i * Int(CPU_STATE_MAX)
            let u = UInt64(info[base + Int(CPU_STATE_USER)])
            let s = UInt64(info[base + Int(CPU_STATE_SYSTEM)])
            let id = UInt64(info[base + Int(CPU_STATE_IDLE)])
            let n = UInt64(info[base + Int(CPU_STATE_NICE)])
            
            currentTotalUser += u
            currentTotalSystem += s
            currentTotalIdle += id
            currentTotalNice += n
            
            currentCoreTicks.append(CPUTicks(user: u, system: s, idle: id, nice: n))
        }
        
        let size = vm_size_t(numCPUInfo) * vm_size_t(MemoryLayout<integer_t>.size)
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: info), size)
        
        let currentTotalTicks = CPUTicks(
            user: currentTotalUser,
            system: currentTotalSystem,
            idle: currentTotalIdle,
            nice: currentTotalNice
        )
        
        // Calculate Total CPU Usage Delta
        if let prevTotal = prevTotalTicks {
            let totalDiff = currentTotalTicks.total > prevTotal.total ? currentTotalTicks.total - prevTotal.total : 1
            let activeDiff = currentTotalTicks.active > prevTotal.active ? currentTotalTicks.active - prevTotal.active : 0
            let usage = min(max(Double(activeDiff) / Double(totalDiff), 0.0), 1.0)
            
            DispatchQueue.main.async {
                self.totalCPUUsage = usage
                self.cpuHistory.removeFirst()
                self.cpuHistory.append(usage)
            }
        }
        prevTotalTicks = currentTotalTicks
        
        // Calculate Per Core CPU Usage Delta
        if prevCoreTicks.count == currentCoreTicks.count {
            var newCoreUsages: [CoreUsage] = []
            for i in 0..<currentCoreTicks.count {
                let curr = currentCoreTicks[i]
                let prev = prevCoreTicks[i]
                let totalDiff = curr.total > prev.total ? curr.total - prev.total : 1
                let activeDiff = curr.active > prev.active ? curr.active - prev.active : 0
                let usage = min(max(Double(activeDiff) / Double(totalDiff), 0.0), 1.0)
                newCoreUsages.append(CoreUsage(id: i, usage: usage))
            }
            DispatchQueue.main.async {
                self.coreUsages = newCoreUsages
            }
        }
        prevCoreTicks = currentCoreTicks
    }
    
    // MARK: - Memory Stats via Mach host_statistics64
    private func updateMemoryStats() {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        
        let hostPort = mach_host_self()
        let kerr = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(hostPort, HOST_VM_INFO64, $0, &count)
            }
        }
        
        guard kerr == KERN_SUCCESS else { return }
        
        var pageSize: vm_size_t = 4096
        host_page_size(hostPort, &pageSize)
        let pageSizeBytes = UInt64(pageSize)
        
        let totalRAM = ProcessInfo.processInfo.physicalMemory
        let active = UInt64(stats.active_count) * pageSizeBytes
        let wired = UInt64(stats.wire_count) * pageSizeBytes
        let compressed = UInt64(stats.compressor_page_count) * pageSizeBytes
        let free = UInt64(stats.free_count) * pageSizeBytes
        
        let usedRAM = wired + active + compressed
        let realFreeRAM = totalRAM > usedRAM ? totalRAM - usedRAM : free
        
        var xsu = xsw_usage()
        var size = MemoryLayout<xsw_usage>.size
        let swapUsed: UInt64
        if sysctlbyname("vm.swapusage", &xsu, &size, nil, 0) == 0 {
            swapUsed = UInt64(xsu.xsu_used)
        } else {
            swapUsed = 0
        }
        
        let percentage = min(max(Double(usedRAM) / Double(totalRAM), 0.0), 1.0)
        let memData = MemoryData(
            totalBytes: totalRAM,
            usedBytes: usedRAM,
            freeBytes: realFreeRAM,
            activeBytes: active,
            wiredBytes: wired,
            compressedBytes: compressed,
            swapUsedBytes: swapUsed,
            usagePercentage: percentage
        )
        
        DispatchQueue.main.async {
            self.memoryData = memData
            self.ramHistory.removeFirst()
            self.ramHistory.append(percentage)
        }
    }
}
