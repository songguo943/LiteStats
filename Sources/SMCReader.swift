import Foundation

public struct FanInfo: Identifiable {
    public let id: Int
    public let name: String
    public let rpm: Int
}

public class SMCReader {
    public static let shared = SMCReader()
    
    public func getFanInfos() -> [FanInfo] {
        let rawData = getSMCFanData()
        guard rawData.count > 0 else { return [] }
        
        var fans: [FanInfo] = []
        let mirror = Mirror(reflecting: rawData.fans)
        var idx = 0
        for child in mirror.children {
            if idx >= Int(rawData.count) { break }
            if let fanItem = child.value as? SMCFanItem {
                fans.append(FanInfo(id: idx, name: "Fan \(idx + 1)", rpm: Int(fanItem.rpm)))
                idx += 1
            }
        }
        return fans
    }
}
