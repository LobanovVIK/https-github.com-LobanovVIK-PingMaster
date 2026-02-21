//
//  HostDetailView.swift
//  PingMaster
//
//  Created by Lobanov Viktor on 04.02.2026.
//

import SwiftUI

struct HostDetailView: View {
    let host: HostModel
    @State private var logs: [String] = [] // Массив для строк лога
    @State private var currentStatus: HostModel.HostStatus
    @State private var isPinging = false
    
    init(host: HostModel) {
        self.host = host
        _currentStatus = State(initialValue: host.status)
    }
    
    var body: some View {
        List {
            Section(header: Text("Информация")) {
                HStack {
                    Text("Адрес")
                    Spacer()
                    Text(host.address)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Описание")
                    Spacer()
                    Text(host.description)
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Статус")) {
                HStack {
                    Text("Текущее состояние")
                    Spacer()
                    statusLabel(for: currentStatus)
                }
            }
            
            Section {
                Button(action: runDetailedPing) {
                    if isPinging {
                        ProgressView().tint(.white)
                    } else {
                        Text("Проверить этот адрес")
                            .fontWeight(.bold)
                    }
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
                .disabled(isPinging)
            }
            
            // СЕКЦИЯ ЛОГА
            if !logs.isEmpty {
                Section(header: Text("Результаты (ICMP Log)")) {
                    ForEach(logs, id: \.self) { log in
                        Text(log)
                            .font(.system(.caption, design: .monospaced)) // Моноширинный шрифт как в консоли
                            .transition(.opacity)
                    }
                }
            }
        }
        .navigationTitle(host.description)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Функция запуска 4-х проверок
    // Функция запуска 4-х проверок
        private func runDetailedPing() {
            logs.removeAll()
            isPinging = true
            currentStatus = .checking
            
            Task {
                let service = PingService()
                var successCount = 0
                
                // Красивое начало как в терминале
                withAnimation {
                    logs.append("PING \(host.address) (ICMP): 56 data bytes")
                }
                
                for i in 0..<4 {
                    let result = await service.checkHostDetailed(address: host.address, seq: i)
                    
                    withAnimation {
                        // Добавляем строчку ТОЛЬКО один раз
                        logs.append(result.message)
                        
                        if result.status {
                            successCount += 1
                        }
                    }
                    
                    try? await Task.sleep(nanoseconds: 500_000_000)
                }
                
                withAnimation {
                    currentStatus = successCount > 0 ? .online : .offline
                    isPinging = false
                    logs.append("--- \(host.address) statistics ---")
                    logs.append("\(successCount) packets received, \(4 - successCount) packets lost")
                }
            }
        }
    
    @ViewBuilder
    private func statusLabel(for status: HostModel.HostStatus) -> some View {
        switch status {
        case .online:
            Text("ONLINE").bold().foregroundColor(.green)
        case .offline:
            Text("OFFLINE").bold().foregroundColor(.red)
        case .checking:
            Text("CHECKING...").foregroundColor(.orange)
        case .pending:
            Text("WAITING").foregroundColor(.gray)
        }
    }
}

//#Preview {
//    NavigationStack {
//        HostDetailView(host: HostModel(address: "google.com", description: "Поисковик", status: .online))
//    }
//}
#Preview {
    NavigationView { 
        HostDetailView(host: HostModel(address: "google.com", description: "Поисковик", status: .online))
    }
}
