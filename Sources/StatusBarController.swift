import Cocoa
import SwiftUI
import Combine

class ClickableHostingView<Content: View>: NSHostingView<Content> {
    var onClick: (() -> Void)?
    
    override func mouseDown(with event: NSEvent) {
        onClick?()
    }
    
    override func rightMouseDown(with event: NSEvent) {
        onClick?()
    }
}

struct StatusItemView: View {
    @ObservedObject var sysMonitor = SystemMonitor.shared
    @ObservedObject var settings = SettingsStore.shared
    
    var body: some View {
        HStack(spacing: 10) {
            if settings.showCPUInStatus {
                ColumnView(label: "CPU", value: String(format: "%.0f%%", sysMonitor.totalCPUUsage * 100))
            }
            if settings.showRAMInStatus {
                ColumnView(label: "RAM", value: String(format: "%.0f%%", sysMonitor.memoryData.usagePercentage * 100))
            }
            if settings.showFanInStatus {
                let rpm = sysMonitor.fanInfos.first(where: { $0.rpm > 0 })?.rpm ?? (sysMonitor.fanInfos.first?.rpm ?? 0)
                ColumnView(label: "FAN", value: "\(rpm)")
            }
        }
        .padding(.horizontal, 4)
    }
}

struct ColumnView: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: -1) {
            Text(label)
                .font(.system(size: 9.0, weight: .bold))
                .foregroundColor(.primary.opacity(0.85))
            Text(value)
                .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                .foregroundColor(.primary)
        }
    }
}

final class StatusBarController: NSObject, NSPopoverDelegate {
    private var statusItem: NSStatusItem
    private var popover: NSPopover
    private var hostingView: ClickableHostingView<StatusItemView>?
    private var eventMonitor: Any?
    private var cancellables = Set<AnyCancellable>()
    private var pendingWidthUpdate: Bool = false
    
    override init() {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.popover = NSPopover()
        super.init()
        
        let contentView = MonitorView()
        self.popover.contentSize = NSSize(width: 340, height: 500)
        self.popover.behavior = .transient
        self.popover.delegate = self
        self.popover.contentViewController = NSHostingController(rootView: contentView)
        
        setupCustomView()
        setupSubscriptions()
    }
    
    private func setupCustomView() {
        guard let button = statusItem.button else { return }
        
        let rootView = StatusItemView()
        let hosting = ClickableHostingView(rootView: rootView)
        hosting.translatesAutoresizingMaskIntoConstraints = false
        hosting.onClick = { [weak self] in
            self?.togglePopover(nil)
        }
        
        button.title = ""
        button.image = nil
        button.subviews.forEach { $0.removeFromSuperview() }
        button.addSubview(hosting)
        
        NSLayoutConstraint.activate([
            hosting.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            hosting.topAnchor.constraint(equalTo: button.topAnchor),
            hosting.bottomAnchor.constraint(equalTo: button.bottomAnchor)
        ])
        
        self.hostingView = hosting
        updateStatusItemWidth(force: true)
    }
    
    private func setupSubscriptions() {
        Publishers.CombineLatest3(
            SystemMonitor.shared.$totalCPUUsage,
            SystemMonitor.shared.$memoryData,
            SystemMonitor.shared.$fanInfos
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _, _, _ in
            self?.updateStatusItemWidth()
        }
        .store(in: &cancellables)
        
        Publishers.CombineLatest3(
            SettingsStore.shared.$showCPUInStatus,
            SettingsStore.shared.$showRAMInStatus,
            SettingsStore.shared.$showFanInStatus
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _, _, _ in
            self?.updateStatusItemWidth()
        }
        .store(in: &cancellables)
    }
    
    private func updateStatusItemWidth(force: Bool = false) {
        guard let hosting = hostingView else { return }
        
        // Defer statusItem length update while popover is open to prevent window jumping
        if popover.isShown && !force {
            pendingWidthUpdate = true
            return
        }
        
        hosting.layoutSubtreeIfNeeded()
        let fittingWidth = hosting.fittingSize.width
        let finalWidth = max(fittingWidth, 20.0)
        statusItem.length = finalWidth
    }
    
    func popoverWillClose(_ notification: Notification) {
        if pendingWidthUpdate {
            pendingWidthUpdate = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.updateStatusItemWidth(force: true)
            }
        }
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            closePopover(sender)
        } else {
            showPopover(sender)
        }
    }
    
    func showPopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
        
        ProcessManager.shared.refreshProcesses()
        
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            self?.closePopover(event)
        }
    }
    
    func closePopover(_ sender: AnyObject?) {
        popover.performClose(sender)
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}
