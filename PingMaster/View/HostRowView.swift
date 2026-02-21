//
//  HostRowView.swift
//  PingMaster
//
//  Created by Lobanov Viktor on 04.02.2026.
//
//ячейка для пинга

import SwiftUI

struct HostRowView: View {
    let host: HostModel
    
    var body: some View {
        HStack(spacing: 15) {
            // Индикатор статуса
            statusCircle
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(host.description)
                    .font(.headline)
                Text(host.address)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if host.status == .checking {
                ProgressView() // Маленькая крутилка справа
            }
        }
        .padding(.vertical, 4)
    }
    
    // Выносим цвет индикатора в отдельное свойство для чистоты кода
    private var statusCircle: some View {
        switch host.status {
        case .pending:  return Circle().fill(Color.gray)
        case .online:   return Circle().fill(Color.green)
        case .offline:  return Circle().fill(Color.red)
        case .checking: return Circle().fill(Color.blue.opacity(0.3))
        }
    }
}

#Preview {
    Group {
        // Посмотрим, как выглядит онлайн статус
        HostRowView(host: HostModel(
            address: "8.8.8.8",
            description: "Google DNS",
            status: .online
        ))
        
        // Посмотрим, как выглядит процесс проверки
        HostRowView(host: HostModel(
            address: "1.1.1.1",
            description: "Cloudflare",
            status: .checking
        ))
    }
    .padding()
    .previewLayout(.sizeThatFits)
}
