//
//  NetworkService.swift
//  DataCollectionModule
//
//  Created by Andriy Hrytsyshyn on 08.08.2025.
//

import Foundation
import Combine

protocol NetworkServiceProtocol {
    func sendBatteryData(_ batteryData: BatteryData) -> AnyPublisher<Bool, Error>
}

class NetworkService: NetworkServiceProtocol {
    
    // MARK: - Properties
    
    private let session: URLSession
    private let baseURL = "https://jsonplaceholder.typicode.com/posts"
    
    // MARK: - Initialization
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    // MARK: - Public Methods
    
    func sendBatteryData(_ batteryData: BatteryData) -> AnyPublisher<Bool, Error> {
        guard let url = URL(string: baseURL) else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        // Створюємо запит з Base64 кодуванням для захисту даних
        guard let base64Data = batteryData.base64EncodedData else {
            return Fail(error: NetworkError.encodingFailed)
                .eraseToAnyPublisher()
        }
        
        let requestBody: [String: Any] = [
            "title": "Battery Data Collection",
            "body": base64Data, // Base64 кодовані дані для безпеки
            "userId": 1,
            "timestamp": ISO8601DateFormatter().string(from: batteryData.timestamp)
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("DataCollectionModule/1.0", forHTTPHeaderField: "User-Agent")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            return Fail(error: NetworkError.encodingFailed)
                .eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> Bool in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                let isSuccess = (200...299).contains(httpResponse.statusCode)
                
                if isSuccess {
                    print("✅ Battery data sent successfully - Status: \(httpResponse.statusCode)")
                    
                    // Логуємо відповідь для дебагу (тільки статус)
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("📤 Server response: \(responseString.prefix(100))...")
                    }
                } else {
                    print("❌ Failed to send battery data - Status: \(httpResponse.statusCode)")
                    throw NetworkError.serverError(httpResponse.statusCode)
                }
                
                return isSuccess
            }
            .retry(2) // Повторюємо запит до 2 разів при помилці
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

// MARK: - NetworkError

enum NetworkError: LocalizedError {
    case invalidURL
    case encodingFailed
    case invalidResponse
    case serverError(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL provided"
        case .encodingFailed:
            return "Failed to encode data"
        case .invalidResponse:
            return "Invalid response received"
        case .serverError(let code):
            return "Server error with status code: \(code)"
        }
    }
}
