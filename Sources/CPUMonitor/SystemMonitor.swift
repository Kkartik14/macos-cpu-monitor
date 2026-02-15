import Foundation
import AppKit
import Darwin

struct MonitoredProcess: Identifiable {
    let id = UUID()
    let pid: Int32
    let name: String
    let cpuUsage: Double
    let icon: NSImage?
}

class SystemMonitor: ObservableObject {
    @Published var cpuUsage: Double = 0.0
    @Published var memoryUsage: Double = 0.0
    @Published var topProcesses: [MonitoredProcess] = []
    
    private var timer: Timer?
    private var previousCPUInfo: processor_info_array_t?
    private var previousCPUInfoCount: mach_msg_type_number_t = 0
    private var processorCount: natural_t = 0
    
    init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        // Initial fetch
        updateStats()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateStats()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateStats() {
        let cpu = getCPUUsage()
        let mem = getMemoryUsage()
        
        // Fetch processes in background to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async {
            let procs = self.getTopProcesses()
            DispatchQueue.main.async {
                self.cpuUsage = cpu
                self.memoryUsage = mem
                self.topProcesses = procs
            }
        }
    }
    
    // MARK: - CPU Usage
    private func getCPUUsage() -> Double {
        var info: processor_info_array_t!
        var msgCount: mach_msg_type_number_t = 0
        var count: natural_t = 0
        var totalUsage: Double = 0.0
        
        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &count, &info, &msgCount)
        
        if result == KERN_SUCCESS {
            if let prevInfo = previousCPUInfo {
                var totalInUse: Int64 = 0
                var totalTotal: Int64 = 0
                
                for i in 0..<Int32(count) {
                    let base = Int(i) * Int(CPU_STATE_MAX)
                    
                    let user = info[base + Int(CPU_STATE_USER)] - prevInfo[base + Int(CPU_STATE_USER)]
                    let system = info[base + Int(CPU_STATE_SYSTEM)] - prevInfo[base + Int(CPU_STATE_SYSTEM)]
                    let nice = info[base + Int(CPU_STATE_NICE)] - prevInfo[base + Int(CPU_STATE_NICE)]
                    let idle = info[base + Int(CPU_STATE_IDLE)] - prevInfo[base + Int(CPU_STATE_IDLE)]
                    
                    let total = user + system + nice + idle
                    let inUse = user + system + nice
                    
                    totalInUse += Int64(inUse)
                    totalTotal += Int64(total)
                }
                
                if totalTotal > 0 {
                    totalUsage = Double(totalInUse) / Double(totalTotal) * 100.0
                }
                
                // Deallocate previous info
                let prevSize = Int(previousCPUInfoCount) * MemoryLayout<integer_t>.stride
                vm_deallocate(mach_task_self_, vm_address_t(bitPattern: prevInfo), vm_size_t(prevSize))
            }
            
            previousCPUInfo = info
            previousCPUInfoCount = msgCount
            processorCount = count
        }
        
        return totalUsage
    }
    
    // MARK: - Memory Usage
    private func getMemoryUsage() -> Double {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let pageSize = UInt64(vm_kernel_page_size)
            let active = UInt64(stats.active_count) * pageSize
            let wired = UInt64(stats.wire_count) * pageSize
            let compressed = UInt64(stats.compressor_page_count) * pageSize
            
            let used = active + wired + compressed
            let total = ProcessInfo.processInfo.physicalMemory
            
            return Double(used) / Double(total) * 100.0
        }
        
        return 0.0
    }
    
    // MARK: - Top Processes
    private func getTopProcesses() -> [MonitoredProcess] {
        // Run ps command to get top CPU consumers
        // ps -Aceo pid,%cpu,comm -r
        // Note: Start from line 1 (skip header)
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-Aceo", "pid,%cpu,comm", "-r"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                var lines = output.components(separatedBy: .newlines)
                if !lines.isEmpty { lines.removeFirst() } // Header
                
                var top: [MonitoredProcess] = []
                
                for line in lines {
                    let parts = line.trimmingCharacters(in: .whitespaces).components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                    if parts.count >= 3,
                       let pid = Int32(parts[0]),
                       let cpu = Double(parts[1]) {
                        
                        // Skip system processes if desired? keeping for now.
                        // Skip self
                        if pid == ProcessInfo.processInfo.processIdentifier { continue }
                        
                        let name = parts.dropFirst(2).joined(separator: " ")
                        
                        // Try to get app icon
                        // NSRunningApplication is main thread only safely? 
                        // It's mostly thread safe but icon access might be better on main.
                        // We will fetch icon on main thread/lazy load or just nil for now inside background.
                        // Actually NSWorkspace.icon(forFile:) or runningApp.icon
                        
                        var icon: NSImage? = nil
                         if let app = NSRunningApplication(processIdentifier: pid) {
                             icon = app.icon
                         } else {
                            // Fallback?
                            icon = NSWorkspace.shared.icon(forFile: "/bin/bash") // generic
                         }
                        
                        top.append(MonitoredProcess(pid: pid, name: name, cpuUsage: cpu, icon: icon))
                        if top.count >= 5 { break }
                    }
                }
                return top
            }
        } catch {
            print("Error running ps: \(error)")
        }
        
        return []
    }
}
