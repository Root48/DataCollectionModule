//
//  DataCollectionManager.swift
//  DataCollectionModule
//
//  Created by Andriy Hrytsyshyn on 08.08.2025.
//

import Foundation
import Combine
import UIKit

protocol DataCollectionManagerProtocol {
    func startDataCollection()
    func stopDataCollection()
    var isCollecting: Bool { get }
    var collectionStatus: AnyPublisher<DataCollectionStatus, Never> { get }
}

enum DataCollectionStatus {
    case idle
    case collecting
    case sendingData
    case error(String)
    case success(String)
}

class DataCollectionManager: DataCollectionManagerProtocol, ObservableObject {
    
    // MARK: - Properties
    
    private let batteryService: BatteryServiceProtocol
    private let networkService: NetworkServiceProtocol
    private let backgroundTaskManager: BackgroundTaskManagerProtocol
    
    @Published private(set) var isCollecting: Bool = false
    @Published private(set) var lastDataCollectionTime: Date?
    @Published private(set) var totalDataSentCount: Int = 0
    @Published private(set) var errorCount: Int = 0
    
    private let statusSubject = PassthroughSubject<DataCollectionStatus, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Publishers
    
    var collectionStatus: AnyPublisher<DataCollectionStatus, Never> {
        statusSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    init(
        batteryService: BatteryServiceProtocol = BatteryService(),
        networkService: NetworkServiceProtocol = NetworkService(),
        backgroundTaskManager: BackgroundTaskManagerProtocol = BackgroundTaskManager()
    ) {
        self.batteryService = batteryService
        self.networkService = networkService
        self.backgroundTaskManager = backgroundTaskManager
        
        setupDataCollectionPipeline()
    }
    
    // MARK: - Private Methods
    
    private func setupDataCollectionPipeline() {
        // Підписуємось на дані від BatteryService
        batteryService.batteryDataPublisher
            .sink { [weak self] batteryData in
                self?.handleNewBatteryData(batteryData)
            }
            .store(in: &cancellables)
    }
    
    private func handleNewBatteryData(_ batteryData: BatteryData) {
        guard isCollecting else { return }
        
        print("🔋 New battery data collected: \(batteryData.batteryLevel)% - \(batteryData.batteryState)")
        
        // Оновлюємо статус
        statusSubject.send(.sendingData)
        lastDataCollectionTime = batteryData.timestamp
        
        // Відправляємо дані на сервер
        sendDataToServer(batteryData)
    }
    
    private func sendDataToServer(_ batteryData: BatteryData) {
        networkService.sendBatteryData(batteryData)
            .sink(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        self?.handleSendingError(error)
                    }
                },
                receiveValue: { [weak self] success in
                    if success {
                        self?.handleSendingSuccess()
                    } else {
                        self?.handleSendingError(NetworkError.serverError(0))
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    private func handleSendingSuccess() {
        totalDataSentCount += 1
        statusSubject.send(.success("Data sent successfully (\(totalDataSentCount))"))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            if self?.isCollecting == true {
                self?.statusSubject.send(.collecting)
            }
        }
    }
    
    private func handleSendingError(_ error: Error) {
        errorCount += 1
        let errorMessage = "Failed to send data: \(error.localizedDescription) (Errors: \(errorCount))"
        statusSubject.send(.error(errorMessage))
        
        print("❌ \(errorMessage)")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            if self?.isCollecting == true {
                self?.statusSubject.send(.collecting)
            }
        }
    }
    
    // MARK: - Public Methods
    
    func startDataCollection() {
        guard !isCollecting else {
            print("⚠️ Data collection already running")
            return
        }
        
        isCollecting = true
        statusSubject.send(.collecting)
        
        // Запускаємо моніторинг батареї
        batteryService.startMonitoring()
        
        print("🚀 Data collection started")
        print("📊 Collecting battery data every 2 minutes")
        print("🔐 Data will be Base64 encoded before sending")
    }
    
    func stopDataCollection() {
        guard isCollecting else {
            print("⚠️ Data collection not running")
            return
        }
        
        isCollecting = false
        statusSubject.send(.idle)
        
        // Зупиняємо моніторинг батареї
        batteryService.stopMonitoring()
        
        print("🛑 Data collection stopped")
        print("📈 Total data sent: \(totalDataSentCount)")
        print("⚠️ Total errors: \(errorCount)")
    }
    
    // MARK: - Utility Methods
    
    func getCollectionSummary() -> String {
        let duration = lastDataCollectionTime?.timeIntervalSinceNow ?? 0
        let status = isCollecting ? "Active" : "Stopped"
        
        return """
        📊 Data Collection Summary:
        Status: \(status)
        Total Data Sent: \(totalDataSentCount)
        Error Count: \(errorCount)
        Last Collection: \(lastDataCollectionTime?.formatted(.dateTime) ?? "Never")
        Success Rate: \(getSuccessRate())%
        """
    }
    
    private func getSuccessRate() -> Int {
        let totalAttempts = totalDataSentCount + errorCount
        guard totalAttempts > 0 else { return 100 }
        return Int((Double(totalDataSentCount) / Double(totalAttempts)) * 100)
    }
    
    func resetCounters() {
        totalDataSentCount = 0
        errorCount = 0
        lastDataCollectionTime = nil
        print("🔄 Counters reset")
    }
}
