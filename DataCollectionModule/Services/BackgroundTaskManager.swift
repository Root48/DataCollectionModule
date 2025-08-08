//
//  BackgroundTaskManager.swift
//  DataCollectionModule
//
//  Created by Andriy Hrytsyshyn on 08.08.2025.
//

import UIKit
import Combine

protocol BackgroundTaskManagerProtocol {
    func beginBackgroundTask(withName name: String, expirationHandler: (() -> Void)?) -> UIBackgroundTaskIdentifier
    func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier)
}

class BackgroundTaskManager: BackgroundTaskManagerProtocol, ObservableObject {
    
    // MARK: - Properties
    
    private var currentBackgroundTaskId: UIBackgroundTaskIdentifier = .invalid
    private let taskName = "BatteryDataCollection"
    
    @Published var isBackgroundTaskActive: Bool = false
    @Published var remainingBackgroundTime: TimeInterval = 0
    
    private var backgroundTimeTimer: Timer?
    
    // MARK: - Initialization
    
    init() {
        setupNotifications()
    }
    
    deinit {
        endCurrentBackgroundTask()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Private Methods
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppWillResignActive()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppDidBecomeActive()
        }
    }
    
    private func handleAppWillResignActive() {
        print("📱 App will resign active - starting background task")
        startBackgroundTaskForDataCollection()
    }
    
    private func handleAppDidBecomeActive() {
        print("📱 App became active - managing background task")
        stopBackgroundTimeTimer()
    }
    
    private func startBackgroundTaskForDataCollection() {
        guard currentBackgroundTaskId == .invalid else {
            print("⚠️ Background task already running")
            return
        }
        
        currentBackgroundTaskId = beginBackgroundTask(withName: taskName) { [weak self] in
            print("⏰ Background task expired - ending task")
            self?.endCurrentBackgroundTask()
        }
        
        if currentBackgroundTaskId != .invalid {
            isBackgroundTaskActive = true
            startBackgroundTimeTimer()
            print("✅ Background task started with ID: \(currentBackgroundTaskId)")
        }
    }
    
    private func endCurrentBackgroundTask() {
        guard currentBackgroundTaskId != .invalid else { return }
        
        endBackgroundTask(currentBackgroundTaskId)
        currentBackgroundTaskId = .invalid
        isBackgroundTaskActive = false
        stopBackgroundTimeTimer()
        
        print("🔚 Background task ended")
    }
    
    private func startBackgroundTimeTimer() {
        stopBackgroundTimeTimer()
        
        backgroundTimeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.remainingBackgroundTime = UIApplication.shared.backgroundTimeRemaining
                
                // Якщо залишається менше 10 секунд, завершуємо задачу
                if self.remainingBackgroundTime < 10 {
                    print("⚠️ Background time running low: \(self.remainingBackgroundTime) seconds")
                    self.endCurrentBackgroundTask()
                }
            }
        }
    }
    
    private func stopBackgroundTimeTimer() {
        backgroundTimeTimer?.invalidate()
        backgroundTimeTimer = nil
        remainingBackgroundTime = 0
    }
    
    // MARK: - Public Methods
    
    func beginBackgroundTask(withName name: String, expirationHandler: (() -> Void)?) -> UIBackgroundTaskIdentifier {
        return UIApplication.shared.beginBackgroundTask(withName: name, expirationHandler: expirationHandler)
    }
    
    func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier) {
        UIApplication.shared.endBackgroundTask(identifier)
    }
    
    // Метод для ручного початку фонової задачі (для тестування)
    func startManualBackgroundTask() {
        startBackgroundTaskForDataCollection()
    }
    
    // Метод для ручного завершення фонової задачі (для тестування)
    func endManualBackgroundTask() {
        endCurrentBackgroundTask()
    }
    
    // Отримання статусу фонової задачі
    func getBackgroundTaskStatus() -> String {
        if currentBackgroundTaskId == .invalid {
            return "No active background task"
        } else {
            return "Background task active (ID: \(currentBackgroundTaskId))"
        }
    }
}
