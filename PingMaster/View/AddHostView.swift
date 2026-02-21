//
//  AddHostView.swift
//  PingMaster
//
//  Created by Lobanov Viktor on 04.02.2026.
//

import SwiftUI

struct AddHostView: View {
    // Свойства для ввода данных
    @State private var address: String = ""
    @State private var description: String = ""
    
    // Окружение, чтобы закрыть экран
    @Environment(\.dismiss) var dismiss
    
    // Замыкание (callback), которое передаст данные обратно на главный экран
    var onAdd: (String, String) -> Void
    
    var body: some View {
            NavigationView { // 1. Заменили на NavigationView
                Form {
                    Section(header: Text("Параметры хоста")) {
                        TextField("IP адрес или домен", text: $address)
                            .disableAutocorrection(true) // 2. Старый стиль для автокоррекции
                            .autocapitalization(.none)    // 3. Старый стиль для регистра
                            .keyboardType(.URL)
                        
                        TextField("Описание (например: Мой сервер)", text: $description)
                    }
                    
                    Section {
                        Button(action: {
                            onAdd(address, description)
                            dismiss()
                        }) {
                            Text("Добавить")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .font(.system(size: 17, weight: .bold)) 
                        }
                        .disabled(address.isEmpty || description.isEmpty)
                    }
                }
                .navigationTitle("Новый адрес")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Отмена") {
                            dismiss()
                        }
                    }
                }
            }
            .navigationViewStyle(.stack) // Чтобы на старых iOS не разъезжалось в режиме планшета
        }
}

#Preview {
    AddHostView { addr, desc in
        print("Добавлено: \(addr)")
    }
}
