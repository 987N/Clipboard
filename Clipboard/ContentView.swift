//
//  ContentView.swift
//  Clipboard
//
//  Created by 鲁成龙 on 6.05.2025.
//

import SwiftUI
import SwiftData

// 为了共享数据结构，在主应用中也定义同样的ClipboardItem
struct ClipboardItem: Codable, Identifiable {
    let content: String
    var isPinned: Bool
    var id: String
    
    init(content: String, isPinned: Bool = false) {
        self.content = content
        self.isPinned = isPinned
        self.id = UUID().uuidString
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    
    @State private var clipboardItems: [ClipboardItem] = []
    @State private var showPinnedOnly: Bool = false
    
    var body: some View {
        NavigationSplitView {
            VStack {
                Picker("显示模式", selection: $showPinnedOnly) {
                    Text("所有记录").tag(false)
                    Text("固定记录").tag(true)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                List {
                    ForEach(filteredClipboardItems) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.content)
                                    .lineLimit(1)
                                Text(Date(), format: .dateTime)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Button(action: {
                                togglePin(item: item)
                            }) {
                                Image(systemName: item.isPinned ? "pin.fill" : "pin")
                                    .foregroundColor(item.isPinned ? .yellow : .gray)
                            }
                            
                            Button(action: {
                                deleteItem(item: item)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                        .swipeActions {
                            Button("删除", role: .destructive) {
                                deleteItem(item: item)
                            }
                            Button(item.isPinned ? "取消固定" : "固定") {
                                togglePin(item: item)
                            }
                            .tint(item.isPinned ? .gray : .yellow)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            UIPasteboard.general.string = item.content
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("复制当前剪贴板", action: saveCurrentClipboard)
                        Button("清除所有记录", role: .destructive, action: clearAllItems)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Text("剪贴板历史")
                        .font(.headline)
                }
            }
            .navigationTitle("剪贴板历史")
            .navigationBarTitleDisplayMode(.inline)
        } detail: {
            Text("选择一条记录可复制它")
        }
        .onAppear {
            loadClipboardData()
        }
    }
    
    private var filteredClipboardItems: [ClipboardItem] {
        if showPinnedOnly {
            return clipboardItems.filter { $0.isPinned }
        } else {
            return clipboardItems
        }
    }
    
    // 加载剪贴板数据
    private func loadClipboardData() {
        let userDefaults = UserDefaults(suiteName: "group.lcl.clipboard")
        
        // 尝试加载ClipboardItem数据
        if let data = userDefaults?.data(forKey: "clipboardItems"),
           let items = try? JSONDecoder().decode([ClipboardItem].self, from: data) {
            self.clipboardItems = items
        } else {
            // 兼容旧格式（如果有）
            let history = userDefaults?.stringArray(forKey: "clipboardHistory") ?? []
            self.clipboardItems = history.map { ClipboardItem(content: $0) }
            
            // 保存为新格式
            saveClipboardItems()
        }
    }
    
    // 保存剪贴板数据
    private func saveClipboardItems() {
        let userDefaults = UserDefaults(suiteName: "group.lcl.clipboard")
        
        if let data = try? JSONEncoder().encode(clipboardItems) {
            userDefaults?.set(data, forKey: "clipboardItems")
        }
        
        // 同时保存为旧格式，保持兼容性
        let history = clipboardItems.map { $0.content }
        userDefaults?.set(history, forKey: "clipboardHistory")
    }
    
    // 保存当前剪贴板内容
    private func saveCurrentClipboard() {
        if let clipboardString = UIPasteboard.general.string, !clipboardString.isEmpty {
            // 检查内容是否已存在
            if !clipboardItems.contains(where: { $0.content == clipboardString }) {
                // 添加新内容到列表头部
                let newItem = ClipboardItem(content: clipboardString)
                clipboardItems.insert(newItem, at: 0)
                
                // 保存更新后的数据
                saveClipboardItems()
            }
        }
    }
    
    // 删除项目
    private func deleteItem(item: ClipboardItem) {
        if let index = clipboardItems.firstIndex(where: { $0.id == item.id }) {
            clipboardItems.remove(at: index)
            saveClipboardItems()
        }
    }
    
    // 切换固定状态
    private func togglePin(item: ClipboardItem) {
        if let index = clipboardItems.firstIndex(where: { $0.id == item.id }) {
            clipboardItems[index].isPinned.toggle()
            saveClipboardItems()
        }
    }
    
    // 清除所有记录
    private func clearAllItems() {
        clipboardItems.removeAll()
        saveClipboardItems()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
