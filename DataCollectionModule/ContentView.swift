//
//  ContentView.swift
//  DataCollectionModule
//
//  Created by Andriy Hrytsyshyn on 08.08.2025.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject private var viewModel = ContentViewModel()
    @State private var showingSummary = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                
                // Заголовок
                Text("Battery Data Collection")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // Поточна інформація про батарею
                batteryInfoCard
                
                // Статус збору даних
                statusCard
                
                // Статистика
                statisticsCard
                
                Spacer()
                
                // Кнопки управління
                controlButtons
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSummary) {
                summaryView
            }
        }
    }
    
    // MARK: - Subviews
    
    private var batteryInfoCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: viewModel.batteryIcon)
                    .font(.system(size: 30))
                    .foregroundColor(batteryColor)
                
                Text(viewModel.batteryLevelPercentage)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(batteryColor)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(viewModel.batteryState.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if viewModel.isLowPowerMode {
                        Label("Low Power", systemImage: "battery.0")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Button("Refresh") {
                viewModel.refreshBatteryInfo()
            }
            .font(.caption)
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var statusCard: some View {
        VStack(spacing: 8) {
            HStack {
                Circle()
                    .fill(viewModel.isCollecting ? Color.green : Color.gray)
                    .frame(width: 12, height: 12)
                
                Text("Collection Status")
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
            }
            
            HStack {
                Text(viewModel.statusMessage)
                    .font(.subheadline)
                    .foregroundColor(viewModel.statusColor)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var statisticsCard: some View {
        HStack(spacing: 20) {
            StatisticView(
                title: "Data Sent",
                value: "\(viewModel.totalDataSent)",
                icon: "arrow.up.circle",
                color: .green
            )
            
            StatisticView(
                title: "Errors",
                value: "\(viewModel.errorCount)",
                icon: "exclamationmark.triangle",
                color: .red
            )
            
            StatisticView(
                title: "Last Collection",
                value: viewModel.lastCollectionTime,
                icon: "clock",
                color: .blue
            )
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var controlButtons: some View {
        VStack(spacing: 12) {
            Button(action: {
                if viewModel.isCollecting {
                    viewModel.stopDataCollection()
                } else {
                    viewModel.startDataCollection()
                }
            }) {
                HStack {
                    Image(systemName: viewModel.isCollecting ? "stop.circle.fill" : "play.circle.fill")
                    Text(viewModel.isCollecting ? "Stop Collection" : "Start Collection")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.isCollecting ? Color.red : Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
                .font(.headline)
            }
            
            HStack(spacing: 12) {
                Button("Reset Counters") {
                    viewModel.resetCounters()
                }
                .buttonStyle(.bordered)
                
                Button("View Summary") {
                    showingSummary = true
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    private var summaryView: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(viewModel.getCollectionSummary())
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    Text("Technical Details:")
                        .font(.headline)
                        .padding(.top)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Data collected every 2 minutes", systemImage: "timer")
                        Label("HTTPS transmission to server", systemImage: "lock.shield")
                        Label("Base64 encoding for data protection", systemImage: "key")
                        Label("Background task support", systemImage: "moon")
                        Label("Battery monitoring optimization", systemImage: "battery.100.bolt")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Collection Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingSummary = false
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var batteryColor: Color {
        if viewModel.currentBatteryLevel < 0.2 {
            return .red
        } else if viewModel.currentBatteryLevel < 0.5 {
            return .orange
        } else {
            return .green
        }
    }
}

// MARK: - StatisticView

struct StatisticView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(color)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ContentView()
}
