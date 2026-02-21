//
//  PingViewModel.swift
//  PingMaster
//
//  Created by Lobanov Viktor on 04.02.2026.
//
import SwiftUI
import Foundation
import Network



@MainActor
class PingViewModel: ObservableObject {
    @Published var hosts: [HostModel] = []{
        didSet {
            save()
        }
    }
    
    private let pingService = PingService()
    private let key = "saved_hosts"
    
    
    // Новые свойства для статуса интернета
        @Published var isInternetAvailable: Bool = true
        @Published var connectionType: String = "Неизвестно"
        
        private var monitor: NWPathMonitor?
        private let monitorQueue = DispatchQueue(label: "InternetMonitor", qos: .background)
    
    
    init() {
        load()
        setupInternetMonitoring()
        
        }
    

    
    func startAllPings() {
        for i in hosts.indices {
            // Ставим статус проверки
            hosts[i].status = .checking
            let addr = hosts[i].address
            
            Task {
                // ВАЖНО: Создаем сервис ВНУТРИ цикла для каждого адреса отдельно
                let service = PingService()
                let isAlive = await service.checkHost(address: addr)
                
                // Возвращаемся в главный поток для обновления UI
                await MainActor.run {
                    // Проверяем, не удалили ли хост, пока шел пинг
                    if i < hosts.count {
                        withAnimation(.smooth) {
                            self.hosts[i].status = isAlive ? .online : .offline
                        }
                    }
                }
            }
        }
    }
    
    // Добавим метод остановки, чтобы кнопка в MainView заработала
        func stopAllPings() {
            for i in hosts.indices {
                hosts[i].status = .pending
            }
        }
    
    
//    private func checkAddress(_ address: String) async -> Bool {
//        // Тут твоя логика из предыдущего сообщения
//        try? await Task.sleep(nanoseconds: 1_000_000_000)
//        return address.contains("8.8.8.8") || address.contains("google")
//    }
//    
   
    private func checkAddress(_ address: String) async -> Bool {
            // Мы пытаемся "достучаться" до хоста по TCP порту (например, 80 или 7 — эхо)
            // Если устройство в сети, оно обычно хотя бы сбрасывает соединение, что уже знак жизни
            
            return await withCheckedContinuation { continuation in
                let host = NWEndpoint.Host(address)
                let port = NWEndpoint.Port(integerLiteral: 80) // Стандартный порт
                
                let connection = NWConnection(host: host, port: port, using: .tcp)
                
                connection.stateUpdateHandler = { state in
                    switch state {
                    case .ready:
                        continuation.resume(returning: true)
                        connection.cancel()
                    case .failed(_):
                        continuation.resume(returning: false)
                        connection.cancel()
                    case .waiting(let error):
                        // Если долго висит в ожидании - скорее всего оффлайн
                        if error.localizedDescription.contains("No route") {
                            continuation.resume(returning: false)
                            connection.cancel()
                        }
                    default:
                        break
                    }
                }
                
                // Ставим тайм-аут 2 секунды, чтобы не ждать вечно
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if connection.state == .preparing || connection.state == .setup {
                        connection.cancel()
                        continuation.resume(returning: false)
                    }
                }
                
                connection.start(queue: .global())
            }
        }
    
    func save() {
            do {
                let encoded = try JSONEncoder().encode(hosts)
                UserDefaults.standard.set(encoded, forKey: key)
                print("Данные сохранены: \(hosts.count) хостов")
            } catch {
                print("Ошибка кодирования для сохранения: \(error)")
            }
        }
    
    func load() {
            if let data = UserDefaults.standard.data(forKey: key) {
                do {
                    let decoded = try JSONDecoder().decode([HostModel].self, from: data)
                    self.hosts = decoded
                    print("Данные успешно загружены: \(decoded.count) хостов")
                } catch {
                    print("Ошибка загрузки данных: \(error)")
                }
            }
        }
    
    
    func addHost(address: String, description: String) {
            let newHost = HostModel(address: address, description: description)
            hosts.append(newHost)
        }
    
    private func setupInternetMonitoring() {
            // Остановим старый монитор, если он был
            monitor?.cancel()
            
            let newMonitor = NWPathMonitor()
            newMonitor.pathUpdateHandler = { [weak self] path in
                Task { @MainActor in
                    // В эмуляторе иногда нужно проверять и .satisfied, и отсутствие интерфейсов
                    let status = path.status == .satisfied
                    
                    var type = "Другое"
                    if path.usesInterfaceType(.wifi) { type = "Wi-Fi" }
                    else if path.usesInterfaceType(.cellular) { type = "LTE/5G" }
                    else if path.usesInterfaceType(.wiredEthernet) { type = "Ethernet" }
                    
                    // Обновляем состояние
                    withAnimation {
                        self?.isInternetAvailable = status
                        self?.connectionType = type
                    }
                    
                    print("Смена статуса сети: \(status), Тип: \(type)")
                }
            }
            
            self.monitor = newMonitor
            newMonitor.start(queue: monitorQueue)
        }
    
    
    
}
