//
//  MainPingView.swift
//  PingMaster
//
//  Created by Lobanov Viktor on 04.02.2026.
//
import SwiftUI

struct MainPingView: View {
    
    @StateObject private var viewModel = PingViewModel()
    @State private var isShowingAddSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // --- ЗАКРЕПЛЕННАЯ ПАНЕЛЬ СОСТОЯНИЯ ---
                VStack {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(viewModel.isInternetAvailable ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                                .frame(width: 45, height: 45)
                            
                            Image(systemName: viewModel.isInternetAvailable ? "antenna.radiowaves.left.and.right" : "wifi.exclamationmark")
                                .font(.title3)
                                .foregroundColor(viewModel.isInternetAvailable ? .green : .red)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("ВАШ ИНТЕРНЕТ")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 5) {
                                Text(viewModel.isInternetAvailable ? "СОЕДИНЕНИЕ УСТАНОВЛЕНО" : "НЕТ ПОДКЛЮЧЕНИЯ")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(viewModel.isInternetAvailable ? .primary : .red)
                                
                                if viewModel.isInternetAvailable {
                                    Text("• \(viewModel.connectionType)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 5)
                }
                .background(Color(.systemGroupedBackground)) // Цвет фона под панелью
                
                // --- СПИСОК ХОСТОВ (теперь он скроллится отдельно) ---
                List {
                    ForEach(viewModel.hosts) { host in
                        NavigationLink(destination: HostDetailView(host: host)) {
                            HostRowView(host: host)
                        }
                    }
                    .onDelete(perform: deleteHost)
                }
                .listStyle(.insetGrouped) // Возвращаем красивый скругленный стиль
            }
            .navigationTitle("Мониторинг")
            .toolbar {
                // Кнопка Плюс (вверху справа)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isShowingAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }

                // Кнопка Остановить (внизу слева)
                ToolbarItem(placement: .bottomBar) {
                    Button(action: {
                        viewModel.stopAllPings()
                    }) {
                        Text("Остановить")
                            .foregroundColor(.red)
                    }
                }

                // Пробел между кнопками внизу
                ToolbarItem(placement: .bottomBar) {
                    Spacer()
                }

                // Кнопка Запустить (внизу справа)
                ToolbarItem(placement: .bottomBar) {
                    Button(action: {
                        viewModel.startAllPings()
                    }) {
                        Text("Запустить все")
                            .font(.system(size: 17, weight: .bold))
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingAddSheet) {
            AddHostView { newAddr, newDesc in
                let newHost = HostModel(address: newAddr, description: newDesc)
                viewModel.hosts.append(newHost)
            }
        }
    }

    private func deleteHost(at offsets: IndexSet) {
        viewModel.hosts.remove(atOffsets: offsets)
    }
}

#Preview {
    MainPingView()
}
