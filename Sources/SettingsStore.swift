import Foundation
import SwiftUI
import Combine

enum LabelFormatStyle: String, CaseIterable, Identifiable {
    case compact = "紧凑 (C 24%  M 66%  F 2320)"
    case minimal = "极简 (24%  66%  2320)"
    case standard = "标准 (CPU 24%  RAM 66%  FAN 2320rpm)"
    
    var id: String { self.rawValue }
}

final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()
    
    @Published var refreshInterval: Double {
        didSet { UserDefaults.standard.set(refreshInterval, forKey: "refreshInterval") }
    }
    
    @Published var showCPUInStatus: Bool {
        didSet { UserDefaults.standard.set(showCPUInStatus, forKey: "showCPUInStatus") }
    }
    
    @Published var showRAMInStatus: Bool {
        didSet { UserDefaults.standard.set(showRAMInStatus, forKey: "showRAMInStatus") }
    }
    
    @Published var showFanInStatus: Bool {
        didSet { UserDefaults.standard.set(showFanInStatus, forKey: "showFanInStatus") }
    }
    
    @Published var labelFormatRaw: String {
        didSet { UserDefaults.standard.set(labelFormatRaw, forKey: "labelFormatRaw") }
    }
    
    @Published var showTopProcesses: Bool {
        didSet { UserDefaults.standard.set(showTopProcesses, forKey: "showTopProcesses") }
    }
    
    var labelFormat: LabelFormatStyle {
        get { LabelFormatStyle(rawValue: labelFormatRaw) ?? .compact }
        set { labelFormatRaw = newValue.rawValue }
    }
    
    init() {
        let interval = UserDefaults.standard.double(forKey: "refreshInterval")
        self.refreshInterval = interval > 0 ? interval : 2.0
        
        self.showCPUInStatus = UserDefaults.standard.object(forKey: "showCPUInStatus") != nil ? UserDefaults.standard.bool(forKey: "showCPUInStatus") : true
        self.showRAMInStatus = UserDefaults.standard.object(forKey: "showRAMInStatus") != nil ? UserDefaults.standard.bool(forKey: "showRAMInStatus") : true
        self.showFanInStatus = UserDefaults.standard.object(forKey: "showFanInStatus") != nil ? UserDefaults.standard.bool(forKey: "showFanInStatus") : false
        
        let format = UserDefaults.standard.string(forKey: "labelFormatRaw")
        self.labelFormatRaw = format ?? LabelFormatStyle.compact.rawValue
        
        self.showTopProcesses = UserDefaults.standard.object(forKey: "showTopProcesses") != nil ? UserDefaults.standard.bool(forKey: "showTopProcesses") : true
    }
}
