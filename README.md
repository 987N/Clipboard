# Clipboard 剪贴板历史键盘项目

## 项目简介

本项目包含一个主应用（Clipboard）和一个自定义键盘扩展（Keyboard），通过 App Group 实现剪贴板历史内容的同步与输入。

- **主应用**：保存和展示所有复制过的文字内容，支持固定和删除操作。
- **键盘扩展**：显示历史剪贴板内容，点击即可输入到当前文本框，支持固定/删除记录。

---

## 功能说明

### 主应用

- 展示所有历史剪贴板内容。
- 支持一键保存当前剪贴板内容到历史。
- 删除不需要的历史记录。
- **固定重要内容**：支持固定常用内容，防止被删除。
- **分类显示**：可以切换显示"所有记录"或仅"固定记录"。
- **滑动操作**：支持滑动删除或固定记录。
- **点击复制**：点击任意记录将其复制到系统剪贴板。

### 键盘扩展

- 展示历史剪贴板内容列表。
- 点击某一项，自动输入到当前文本框。
- 支持切换系统键盘。
- **仅在键盘显示时检查剪贴板**：优化性能，不再使用定时器持续监听。
- **自适应系统键盘外观**：跟随系统键盘的亮色/暗色模式自动调整界面。
- **完全访问提示**：提示用户开启"完全访问"以读取剪贴板数据。
- **分类管理**：临时记录和固定记录分开显示，临时记录中不再包含固定项。
- **紧凑设计**：减小条目高度，显示更多内容，提高使用效率。
- **删除记录功能**：可删除不需要的记录。
- **美化界面**：圆角和阴影设计，更加美观。
- **标准键盘高度**：与系统键盘保持一致的高度，提供一致的用户体验。
- **简洁界面**：隐藏了多余的按钮，保留必要功能按钮。

---

## App Group 配置

1. 在 Xcode 的主应用和键盘扩展的 Target -> Signing & Capabilities 中，添加同一个 App Group。
2. 在 `Clipboard.entitlements` 和键盘扩展的 entitlements 文件中添加：

```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group</string>
</array>
```

---

## 数据存储说明

- 剪贴板历史内容通过 `UserDefaults(suiteName: "group")` 进行共享。
- 主应用每次保存内容时会同步写入 App Group。
- 键盘扩展启动时自动读取 App Group 内容。
- 键盘扩展仅在显示时检查剪贴板变化，优化性能和电池消耗。
- 现在使用 JSON 存储结构化数据，支持保存内容、固定状态等信息。

---

## 主要代码说明

### 剪贴板数据结构

```swift
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
```

### 保存剪贴板数据

```swift
func saveClipboardItems() {
    let userDefaults = UserDefaults(suiteName: "group")

    if let data = try? JSONEncoder().encode(clipboardItems) {
        userDefaults?.set(data, forKey: "clipboardItems")
    }

    // 同时保存为旧格式，保持兼容性
    let history = clipboardItems.map { $0.content }
    userDefaults?.set(history, forKey: "clipboardHistory")
}
```

### 分类显示临时项和固定项

```swift
var filteredClipboardItems: [ClipboardItem] {
    switch showingMode {
    case 0: // 临时项（不包含固定项）
        return clipboardItems.filter { !$0.isPinned }
    case 1: // 固定项
        return clipboardItems.filter { $0.isPinned }
    default:
        return clipboardItems
    }
}
```

### 固定/解除固定记录

```swift
func togglePin(item: ClipboardItem) {
    if let index = clipboardItems.firstIndex(where: { $0.id == item.id }) {
        clipboardItems[index].isPinned.toggle()
        saveClipboardItems()
    }
}
```

### 删除记录

```swift
func deleteItem(item: ClipboardItem) {
    if let index = clipboardItems.firstIndex(where: { $0.id == item.id }) {
        clipboardItems.remove(at: index)
        saveClipboardItems()
    }
}
```

### 主应用保存内容到 App Group

```swift
let userDefaults = UserDefaults(suiteName: "group")
var history = userDefaults?.stringArray(forKey: "clipboardHistory") ?? []
history.insert(clipboardString, at: 0)
userDefaults?.set(history, forKey: "clipboardHistory")
```

### 键盘扩展读取内容

```swift
let userDefaults = UserDefaults(suiteName: "group")
let history = userDefaults?.stringArray(forKey: "clipboardHistory") ?? []
self.datas = history
self.tableView.reloadData()
```

### 键盘扩展点击输入

```swift
func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let text = datas[indexPath.row]
    self.textDocumentProxy.insertText(text)
}
```

### 键盘扩展自动监听剪贴板

```swift
// 检查剪贴板是否有变化
@objc func checkPasteboardChanges() {
    guard hasFullAccess() else { return }

    if let currentString = UIPasteboard.general.string,
       !currentString.isEmpty,
       currentString != lastPasteboardString {

        // 更新上次检查的内容
        lastPasteboardString = currentString

        // 保存到App Group
        let userDefaults = UserDefaults(suiteName: "group")
        var history = userDefaults?.stringArray(forKey: "clipboardHistory") ?? []

        // 避免重复内容
        if history.first != currentString {
            history.insert(currentString, at: 0)
            userDefaults?.set(history, forKey: "clipboardHistory")
            self.datas = history
            self.tableView.reloadData()
        }
    }
}
```

### 键盘扩展外观适配

```swift
// 更新键盘背景色，与系统键盘保持一致
func updateKeyboardAppearance() {
    let proxy = self.textDocumentProxy
    isDarkMode = proxy.keyboardAppearance == UIKeyboardAppearance.dark

    if isDarkMode {
        // 暗色模式
        self.view.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
        tableView.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
    } else {
        // 亮色模式
        self.view.backgroundColor = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0)
        tableView.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
    }
}
```

---

## 使用方法

1. 在主应用中复制你想保存的内容，点击"保存剪贴板"按钮。
2. 在任何输入框切换到自定义键盘，选择历史内容即可快速输入。
3. 在系统设置中为键盘扩展开启"完全访问"，允许其读取剪贴板内容。
4. 使用"固定"功能保存常用内容，防止被清除。
5. 使用分段控制器在"临时"和"固定"记录之间切换。

---

## 注意事项

- **必须开启"完全访问"**：在设置->通用->键盘->键盘->你的自定义键盘中开启"允许完全访问"才能让键盘扩展访问剪贴板。
- 剪贴板历史内容仅在本机保存，不上传云端，保护隐私。
- 现在的键盘仅在显示时检查剪贴板内容，更节省电池和系统资源。
- 临时记录区不会显示已固定的项目，避免重复内容。
- 现在键盘可以显示更多条目，提高了使用效率。

---
