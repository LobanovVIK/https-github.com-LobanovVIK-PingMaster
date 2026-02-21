//
//  HostModel.swift
//  PingMaster
//
//  Created by Lobanov Viktor on 04.02.2026.
//

import Foundation

struct HostModel: Identifiable, Codable {
    var id = UUID()         // Нужно для работы List
    var address: String     // IP или домен
    var description: String //  описание 
    var status: HostStatus = .pending
    
    enum HostStatus: String, Codable{
        case pending, online, offline, checking
    }
}

// статусы - состояния
enum HostStatus {
    case pending   // Еще не проверяли (серый)
    case online    // Доступен (зеленый)
    case offline   // Ошибка (красный)
    case checking  // В процессе (анимация)
}
