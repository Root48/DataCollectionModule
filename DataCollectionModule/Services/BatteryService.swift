//
//  BatteryService.swift
//  DataCollectionModule
//
//  Created by Andriy Hrytsyshyn on 08.08.2025.
//

import Foundation
import UIKit
import Combine

protocol BatteryServiceProtocol {
    func getCurrentBatteryData() -> BatteryData
    func startMonitoring()
    func stopMonitoring()
    var batteryDataPublisher: AnyPublisher<BatteryData, Never> { get }
}

class BatteryService: BatteryServiceProtocol, ObservableObject {
    
    // MARK: - Properties
    
    private let batteryDataSubject = PassthroughSubject<BatteryData, Never>()
    private var cancellables = Set<AnyCancellable>()
    private var monitoringTimer: Timer?
    
    var batteryDataPublisher: AnyPublisher<BatteryData, Never> {
        batteryDataSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    init() {
        setupBatteryMonitoring()
    }
    
    deinit {
        stopMonitoring()
        UIDevice.current.isBatteryMonitoringEnabled = false
    }
    
    // MARK: - Private Methods
    
    private func setupBatteryMonitoring() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        // Додаємо спостерігачі за змінами стану батареї
        NotificationCenter.default.addObserver(
            forName: UIDevice.batteryLevelDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleBatteryChange()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIDevice.batteryStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleBatteryChange()
        }
    }
    
    private func handleBatteryChange() {
        let batteryData = getCurrentBatteryData()
        batteryDataSubject.send(batteryData)
    }
    
    // MARK: - Public Methods
    
    func getCurrentBatteryData() -> BatteryData {
        return BatteryData()
    }
    
    func startMonitoring() {
        stopMonitoring() // Зупиняємо попередній таймер, якщо він існує
        
        // Створюємо таймер для збору даних кожні 2 хвилини (120 секунд) - для тестування: 20 секунд
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 120.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            DispatchQueue.global(qos: .utility).async {
                let batteryData = self.getCurrentBatteryData()
                
                DispatchQueue.main.async {
                    self.batteryDataSubject.send(batteryData)
                }
            }
        }
        
        // Відправляємо перші дані одразу
        let initialData = getCurrentBatteryData()
        batteryDataSubject.send(initialData)
        
        print("🔋 Battery monitoring started - collecting data every 2 minutes")
    }
    
    func stopMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        print("🔋 Battery monitoring stopped")
    }
}
