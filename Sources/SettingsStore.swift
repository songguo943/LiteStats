import Foundation
import SwiftUI
import Combine
import ServiceManagement

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "English"
    case chinese = "简体中文"
    
    var id: String { self.rawValue }
    var code: String {
        switch self {
        case .english: return "en"
        case .chinese: return "zh"
        }
    }
}

final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()
    
    @Published var appLanguageRaw: String {
        didSet { UserDefaults.standard.set(appLanguageRaw, forKey: "appLanguageRaw") }
    }
    
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
    
    @Published var showTopProcesses: Bool {
        didSet { UserDefaults.standard.set(showTopProcesses, forKey: "showTopProcesses") }
    }
    
    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
            updateLaunchAtLogin(enabled: launchAtLogin)
        }
    }
    
    var appLanguage: AppLanguage {
        get { AppLanguage(rawValue: appLanguageRaw) ?? .english }
        set { appLanguageRaw = newValue.rawValue }
    }
    
    func l10n(_ en: String, _ zh: String) -> String {
        return appLanguage == .chinese ? zh : en
    }
    
    init() {
        let lang = UserDefaults.standard.string(forKey: "appLanguageRaw")
        self.appLanguageRaw = lang ?? AppLanguage.english.rawValue
        
        let interval = UserDefaults.standard.double(forKey: "refreshInterval")
        self.refreshInterval = interval > 0 ? interval : 2.0
        
        self.showCPUInStatus = UserDefaults.standard.object(forKey: "showCPUInStatus") != nil ? UserDefaults.standard.bool(forKey: "showCPUInStatus") : true
        self.showRAMInStatus = UserDefaults.standard.object(forKey: "showRAMInStatus") != nil ? UserDefaults.standard.bool(forKey: "showRAMInStatus") : true
        self.showFanInStatus = UserDefaults.standard.object(forKey: "showFanInStatus") != nil ? UserDefaults.standard.bool(forKey: "showFanInStatus") : false
        
        self.showTopProcesses = UserDefaults.standard.object(forKey: "showTopProcesses") != nil ? UserDefaults.standard.bool(forKey: "showTopProcesses") : true
        
        if #available(macOS 13.0, *) {
            self.launchAtLogin = (SMAppService.mainApp.status == .enabled)
        } else {
            self.launchAtLogin = UserDefaults.standard.bool(forKey: "launchAtLogin")
        }
    }
    
    private func updateLaunchAtLogin(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    if SMAppService.mainApp.status != .enabled {
                        try SMAppService.mainApp.register()
                    }
                } else {
                    if SMAppService.mainApp.status == .enabled {
                        try SMAppService.mainApp.unregister()
                    }
                }
            } catch {
                print("Launch at login error:", error)
            }
        }
    }
}
