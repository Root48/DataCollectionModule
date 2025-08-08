//
//  ContentViewModel.swift
//  DataCollectionModule
//
//  Created by Andriy Hrytsyshyn on 08.08.2025.
//

import SwiftUI
import Combine

class ContentViewModel: ObservableObject {
    
    // MARK: - Properties
    
    @Published var currentBatteryLevel: Float = 0.0
    @Published var batteryState: String = "unknown"
    @Published var isCollecting: Bool = false
    @Published var statusMessage: String = "Ready to collect data"
    @Published var totalDataSent: Int = 0
    @Published var errorCount: Int = 0
    @Published var lastCollectionTime: String = "Never"
    @Published var isLowPowerMode: Bool = false
    
    private let dataCollectionManager: DataCollectionManager
    private let batteryService: BatteryService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        self.batteryService = BatteryService()
        self.dataCollectionManager = DataCollectionManager(batteryService: batteryService)
        
        setupSubscriptions()
        updateCurrentBatteryInfo()
    }
    
    // MARK: - Private Methods
    
    private func setupSubscriptions() {
        // Підписуємось на стан збору даних
        dataCollectionManager.$isCollecting
            .assign(to: \.isCollecting, on: self)
            .store(in: &cancellables)
        
        dataCollectionManager.$totalDataSentCount
            .assign(to: \.totalDataSent, on: self)
            .store(in: &cancellables)
        
        dataCollectionManager.$errorCount
            .assign(to: \.errorCount, on: self)
            .store(in: &cancellables)
        
        dataCollectionManager.$lastDataCollectionTime
            .map { date in
                guard let date = date else { return "Never" }
                return DateFormatter.shortDateTime.string(from: date)
            }
            .assign(to: \.lastCollectionTime, on: self)
            .store(in: &cancellables)
        
        // Підписуємось на статус збору даних
        dataCollectionManager.collectionStatus
            .map { status in
                switch status {
                case .idle:
                    return "Ready to collect data"
                case .collecting:
                    return "Collecting data every 2 minutes..."
                case .sendingData:
                    return "Sending data to server..."
                case .success(let message):
                    return message
                case .error(let message):
                    return message
                }
            }
            .assign(to: \.statusMessage, on: self)
            .store(in: &cancellables)
        
        // Підписуємось на дані про батарею
        batteryService.batteryDataPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] batteryData in
                self?.currentBatteryLevel = batteryData.batteryLevel
                self?.batteryState = batteryData.batteryState
                self?.isLowPowerMode = batteryData.isLowPowerModeEnabled
            }
            .store(in: &cancellables)
    }
    
    private func updateCurrentBatteryInfo() {
        let batteryData = batteryService.getCurrentBatteryData()
        currentBatteryLevel = batteryData.batteryLevel
        batteryState = batteryData.batteryState
        isLowPowerMode = batteryData.isLowPowerModeEnabled
    }
    
    // MARK: - Public Methods
    
    func startDataCollection() {
        dataCollectionManager.startDataCollection()
    }
    
    func stopDataCollection() {
        dataCollectionManager.stopDataCollection()
    }
    
    func refreshBatteryInfo() {
        updateCurrentBatteryInfo()
    }
    
    func resetCounters() {
        dataCollectionManager.resetCounters()
    }
    
    func getCollectionSummary() -> String {
        return dataCollectionManager.getCollectionSummary()
    }
    
    // MARK: - Computed Properties
    
    var batteryLevelPercentage: String {
        if currentBatteryLevel < 0 {
            return "Unknown"
        }
        return "\(Int(currentBatteryLevel * 100))%"
    }
    
    var batteryIcon: String {
        switch batteryState {
        case "charging":
            return "battery.100.bolt"
        case "full":
            return "battery.100"
        case "unplugged":
            if currentBatteryLevel > 0.75 {
                return "battery.75"
            } else if currentBatteryLevel > 0.50 {
                return "battery.50"
            } else if currentBatteryLevel > 0.25 {
                return "battery.25"
            } else {
                return "battery.0"
            }
        default:
            return "battery"
        }
    }
    
    var statusColor: Color {
        if statusMessage.contains("error") || statusMessage.contains("Failed") {
            return .red
        } else if statusMessage.contains("success") || statusMessage.contains("sent") {
            return .green
        } else if isCollecting {
            return .blue
        } else {
            return .secondary
        }
    }
}

// MARK: - DateFormatter Extension

extension DateFormatter {
    static let shortDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}
