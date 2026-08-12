import Foundation
import Darwin
import AppKit

struct ProcessInfoItem: Identifiable {
    let id: pid_t
    let name: String
    let cpuUsagePercentage: Double
    let memoryBytes: UInt64
    let icon: NSImage?
    
    var formattedMemory: String {
        ByteCountFormatter.string(fromByteCount: Int64(memoryBytes), countStyle: .memory)
    }
}

final class ProcessManager: ObservableObject {
    static let shared = ProcessManager()
    
    @Published var topCPUProcesses: [ProcessInfoItem] = []
    @Published var topRAMProcesses: [ProcessInfoItem] = []
    
    private var previousCpuTimes: [pid_t: (time: UInt64, timestamp: Date)] = [:]
    private var timer: Timer?
    
    init() {
        refreshProcesses()
        // Poll process metrics continuously every 2 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.refreshProcesses()
        }
    }
    
    func refreshProcesses() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let pidsCount = proc_listpids(UInt32(PROC_ALL_PIDS), 0, nil, 0)
            guard pidsCount > 0 else { return }
            
            var pids = [pid_t](repeating: 0, count: Int(pidsCount) / MemoryLayout<pid_t>.size + 20)
            let actualBytes = proc_listpids(UInt32(PROC_ALL_PIDS), 0, &pids, Int32(pids.count * MemoryLayout<pid_t>.size))
            let actualCount = Int(actualBytes) / MemoryLayout<pid_t>.size
            
            var processList: [ProcessInfoItem] = []
            var newCpuTimes: [pid_t: (time: UInt64, timestamp: Date)] = [:]
            let now = Date()
            
            let currentAppPid = ProcessInfo.processInfo.processIdentifier
            
            for i in 0..<actualCount {
                let pid = pids[i]
                guard pid > 0, pid != currentAppPid else { continue }
                
                var nameBuffer = [CChar](repeating: 0, count: 256)
                let nameLength = proc_name(pid, &nameBuffer, UInt32(nameBuffer.count))
                guard nameLength > 0 else { continue }
                let name = String(cString: nameBuffer)
                
                var taskInfo = proc_taskinfo()
                let taskInfoSize = Int32(MemoryLayout<proc_taskinfo>.size)
                let result = proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &taskInfo, taskInfoSize)
                guard result == taskInfoSize else { continue }
                
                let residentMemory = taskInfo.pti_resident_size
                guard residentMemory > 0 else { continue }
                
                let cpuTimeNs = taskInfo.pti_total_user + taskInfo.pti_total_system
                
                var cpuPercentage: Double = 0.0
                if let prev = self.previousCpuTimes[pid] {
                    let timeDelta = Double(cpuTimeNs > prev.time ? cpuTimeNs - prev.time : 0) / 1_000_000_000.0 // ns -> sec
                    let wallDelta = now.timeIntervalSince(prev.timestamp)
                    if wallDelta > 0 {
                        cpuPercentage = min(max((timeDelta / wallDelta) * 100.0, 0.0), 800.0)
                    }
                }
                newCpuTimes[pid] = (cpuTimeNs, now)
                
                var icon: NSImage? = nil
                if let app = NSRunningApplication(processIdentifier: pid) {
                    icon = app.icon
                }
                
                processList.append(ProcessInfoItem(
                    id: pid,
                    name: name,
                    cpuUsagePercentage: cpuPercentage,
                    memoryBytes: residentMemory,
                    icon: icon
                ))
            }
            
            self.previousCpuTimes = newCpuTimes
            
            let sortedCPU = Array(processList.sorted(by: { $0.cpuUsagePercentage > $1.cpuUsagePercentage }).prefix(5))
            let sortedRAM = Array(processList.sorted(by: { $0.memoryBytes > $1.memoryBytes }).prefix(5))
            
            DispatchQueue.main.async {
                self.topCPUProcesses = sortedCPU.isEmpty ? Array(processList.prefix(5)) : sortedCPU
                self.topRAMProcesses = sortedRAM
            }
        }
    }
    
    func killProcess(pid: pid_t) {
        kill(pid, SIGKILL)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.refreshProcesses()
        }
    }
}
