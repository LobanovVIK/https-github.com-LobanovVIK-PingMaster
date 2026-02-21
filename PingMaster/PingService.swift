//
// PingService.swift
// PingMaster
//
// Created by Lobanov Viktor on 04.02.2026.
//

import Foundation

// Та же структура, что у нас была
struct PingResult {
    let status: Bool
    let responseTime: Double
    let message: String
    let sequence: Int
    let ttl: Int
}

class PingService: NSObject, SimplePingDelegate {
    private var pinger: SimplePing?
    private var continuation: CheckedContinuation<PingResult, Never>?
    private var startTime: Date?
    private var currentSequence: Int = 0
    private var timeoutTimer: Timer?
    
    // 1. Быстрая проверка
    @MainActor
    func checkHost(address: String) async -> Bool {
        let result = await performPing(address: address, seq: 0)
        return result.status
    }
    
    // 2. Детальная проверка
    @MainActor
    func checkHostDetailed(address: String, seq: Int) async -> PingResult {
        return await performPing(address: address, seq: seq)
    }
    
    private func performPing(address: String, seq: Int) async -> PingResult {
        // Если предыдущий пинг не завершился, принудительно закрываем
        stopWithResult(nil)
        
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            self.currentSequence = seq
            
            let pinger = SimplePing(hostName: address)
            pinger.delegate = self
            self.pinger = pinger
            
            // Запускаем на главном потоке, так как SimplePing нужен RunLoop
            DispatchQueue.main.async {
                pinger.start()
                
                // Ставим тайм-аут 2 секунды
                self.timeoutTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
                    self.stopWithResult(PingResult(
                        status: false,
                        responseTime: 0,
                        message: "Request timeout for icmp_seq \(seq)",
                        sequence: seq,
                        ttl: 0
                    ))
                }
            }
        }
    }
    
    private func stopWithResult(_ result: PingResult?) {
        timeoutTimer?.invalidate()
        timeoutTimer = nil
        pinger?.stop()
        pinger = nil
        
        if let result = result {
            continuation?.resume(returning: result)
            continuation = nil
        }
    }
    
    // MARK: - SimplePing Delegate
    
    func simplePing(_ pinger: SimplePing, didStartWithAddress address: Data) {
        startTime = Date()
        pinger.send(with: nil)
    }
    
    func simplePing(_ pinger: SimplePing, didFailWithError error: Error) {
        stopWithResult(PingResult(status: false, responseTime: 0, message: "Error: \(error.localizedDescription)", sequence: currentSequence, ttl: 0))
    }
    
    func simplePing(_ pinger: SimplePing, didReceivePingResponsePacket packet: Data, sequenceNumber: UInt16) {
        let duration = Date().timeIntervalSince(startTime ?? Date()) * 1000
        
        // Извлекаем TTL (в IPv4 это 8-й байт пакета)
        let ttl = packet.count > 8 ? Int(packet[8]) : 64
        
        let msg = "64 bytes from \(pinger.hostName): icmp_seq=\(sequenceNumber) ttl=\(ttl) time=\(String(format: "%.3f", duration)) ms"
        
        stopWithResult(PingResult(
            status: true,
            responseTime: duration,
            message: msg,
            sequence: Int(sequenceNumber),
            ttl: ttl
        ))
    }
    
    func simplePing(_ pinger: SimplePing, didFailToSendPacket packet: Data, sequenceNumber: UInt16, error: Error) {
        stopWithResult(PingResult(status: false, responseTime: 0, message: "Send failed", sequence: Int(sequenceNumber), ttl: 0))
    }
}
