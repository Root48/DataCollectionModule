//
//  BatteryData.swift
//  DataCollectionModule
//
//  Created by Andriy Hrytsyshyn on 08.08.2025.
//

import Foundation
import UIKit

struct BatteryData: Codable {
    let timestamp: Date
    let batteryLevel: Float
    let batteryState: String
    let deviceId: String
    let isLowPowerModeEnabled: Bool
    
    init() {
        self.timestamp = Date()
        
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true
        
        self.batteryLevel = device.batteryLevel
        self.batteryState = device.batteryState.description
        self.deviceId = device.identifierForVendor?.uuidString ?? UUID().uuidString
        self.isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
    }
    
    var jsonData: Data? {
        return try? JSONEncoder().encode(self)
    }
    
    var base64EncodedData: String? {
        guard let jsonData = jsonData else { return nil }
        return jsonData.base64EncodedString()
    }
}

extension UIDevice.BatteryState {
    var description: String {
        switch self {
        case .unknown:
            return "unknown"
        case .unplugged:
            return "unplugged"
        case .charging:
            return "charging"
        case .full:
            return "full"
        @unknown default:
            return "unknown"
        }
    }
}
