//
//  KeyboardViewController.swift
//  Keyboard
//
//  Created by 鲁成龙 on 6.05.2025.
//

import UIKit
import Foundation

// MARK: - 剪贴板项模型
struct ClipboardItem: Codable {
    let content: String
    var isPinned: Bool = false
    var id: String
    
    init(content: String, isPinned: Bool = false) {
        self.content = content
        self.isPinned = isPinned
        self.id = UUID().uuidString
    }
}

// MARK: - 自定义单元格
class ClipboardCell: UITableViewCell {
    static let identifier = "ClipboardCell"
    
    // UI组件
    let containerView = UIView()
    let contentLabel = UILabel()
    let pinButton = UIButton()
    let deleteButton = UIButton()
    
    // 回调闭包
    var pinAction: (() -> Void)?
    var deleteAction: (() -> Void)?
    
    // MARK: 初始化
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    // MARK: 视图设置
    private func setupViews() {
        // 清除背景色
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        
        // 容器视图设置
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.layer.cornerRadius = 8
        containerView.layer.masksToBounds = false
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 1)
        containerView.layer.shadowOpacity = 0.15
        containerView.layer.shadowRadius = 2
        
        // 内容标签设置
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        contentLabel.numberOfLines = 1
        contentLabel.font = UIFont.systemFont(ofSize: 14)
        
        // 固定按钮设置
        pinButton.translatesAutoresizingMaskIntoConstraints = false
        pinButton.setImage(UIImage(systemName: "pin"), for: .normal)
        pinButton.addTarget(self, action: #selector(handlePinTap), for: .touchUpInside)
        
        // 删除按钮设置
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.setImage(UIImage(systemName: "trash"), for: .normal)
        deleteButton.addTarget(self, action: #selector(handleDeleteTap), for: .touchUpInside)
        
        // 添加子视图
        contentView.addSubview(containerView)
        containerView.addSubview(contentLabel)
        containerView.addSubview(pinButton)
        containerView.addSubview(deleteButton)
        
        // 约束设置
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 3),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -3),
            
            contentLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            contentLabel.trailingAnchor.constraint(equalTo: pinButton.leadingAnchor, constant: -8),
            contentLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            pinButton.widthAnchor.constraint(equalToConstant: 24),
            pinButton.heightAnchor.constraint(equalToConstant: 24),
            pinButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            pinButton.trailingAnchor.constraint(equalTo: deleteButton.leadingAnchor, constant: -8),
            
            deleteButton.widthAnchor.constraint(equalToConstant: 24),
            deleteButton.heightAnchor.constraint(equalToConstant: 24),
            deleteButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            deleteButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10)
        ])
    }
    
    // MARK: 按钮动作
    @objc private func handlePinTap() {
        pinAction?()
    }
    
    @objc private func handleDeleteTap() {
        deleteAction?()
    }
    
    // MARK: 配置单元格
    func configure(with item: ClipboardItem, isDarkMode: Bool) {
        contentLabel.text = item.content
        
        // 根据暗/亮模式设置颜色
        if isDarkMode {
            containerView.backgroundColor = UIColor(white: 0.2, alpha: 0.7)
            contentLabel.textColor = .white
            pinButton.tintColor = item.isPinned ? .systemYellow : .white
            deleteButton.tintColor = .white
        } else {
            containerView.backgroundColor = UIColor(white: 1.0, alpha: 0.7)
            contentLabel.textColor = .black
            pinButton.tintColor = item.isPinned ? .systemYellow : .darkGray
            deleteButton.tintColor = .darkGray
        }
        
        // 更新固定按钮图标
        let pinImage = item.isPinned ? UIImage(systemName: "pin.fill") : UIImage(systemName: "pin")
        pinButton.setImage(pinImage, for: .normal)
    }
}

// MARK: - 键盘控制器
class KeyboardViewController: UIInputViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: 属性
    var tableView: UITableView!
    var clipboardItems: [ClipboardItem] = []
    var isDarkMode: Bool = false
    var showingMode: Int = 0 // 0: 临时项，1: 固定项
    
    // 界面组件
    var toolbarView: UIView!
    var segmentedControl: UISegmentedControl!
    
    // 常量
    let standardKeyboardHeight: CGFloat = 291
    
    // MARK: 生命周期方法
    override func updateViewConstraints() {
        super.updateViewConstraints()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 设置键盘高度
        setupKeyboardHeight()
        
        // 初始化界面组件
        setupToolbar()
        setupTableView()
        
        // 检查权限
        if !hasFullAccess() {
            showFullAccessRequiredLabel()
        }
        
        // 加载数据
        loadClipboardData()
        
        // 设置外观
        updateKeyboardAppearance()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 刷新数据
        loadClipboardData()
        
        // 检查剪贴板新内容
        saveCurrentClipboardContent()
        
        // 更新外观
        updateKeyboardAppearance()
    }
    
    override func textDidChange(_ textInput: UITextInput?) {
        updateKeyboardAppearance()
    }
    
    // MARK: 界面设置
    private func setupKeyboardHeight() {
        if let inputView = self.inputView {
            var newFrame = inputView.frame
            newFrame.size.height = standardKeyboardHeight
            inputView.frame = newFrame
        }
    }
    
    private func setupTableView() {
        let topPadding: CGFloat = 5
        let toolbarHeight: CGFloat = 36
        
        tableView = UITableView(frame: CGRect(
            x: 0,
            y: topPadding,
            width: self.view.bounds.width,
            height: standardKeyboardHeight - toolbarHeight - topPadding
        ))
        
        tableView.register(ClipboardCell.self, forCellReuseIdentifier: ClipboardCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.bounces = true
        tableView.showsVerticalScrollIndicator = true
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = 50
        
        self.view.addSubview(tableView)
    }
    
    private func setupToolbar() {
        toolbarView = UIView(frame: CGRect(
            x: 0,
            y: standardKeyboardHeight - 32,
            width: self.view.bounds.width,
            height: 32
        ))
        toolbarView.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        toolbarView.backgroundColor = .clear
        self.view.addSubview(toolbarView)
        
        // 分段控制器
        segmentedControl = UISegmentedControl(items: ["临时", "固定"])
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        toolbarView.addSubview(segmentedControl)
        
        // 约束
        NSLayoutConstraint.activate([
            segmentedControl.centerXAnchor.constraint(equalTo: toolbarView.centerXAnchor),
            segmentedControl.centerYAnchor.constraint(equalTo: toolbarView.centerYAnchor),
            segmentedControl.widthAnchor.constraint(equalToConstant: 120)
        ])
    }
    
    private func showFullAccessRequiredLabel() {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 40))
        label.text = "请在设置中启用完全访问以读取剪贴板"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .red
        self.view.addSubview(label)
    }
    
    // MARK: 外观更新
    private func updateKeyboardAppearance() {
        let proxy = self.textDocumentProxy
        isDarkMode = proxy.keyboardAppearance == UIKeyboardAppearance.dark
        
        // 设置主视图为透明
        self.view.backgroundColor = .clear
        
        // 更新segmentedControl样式
        if isDarkMode {
            segmentedControl.backgroundColor = UIColor(white: 0.2, alpha: 0.7)
            segmentedControl.selectedSegmentTintColor = UIColor(white: 0.3, alpha: 0.7)
            segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        } else {
            segmentedControl.backgroundColor = UIColor(white: 0.9, alpha: 0.7)
            segmentedControl.selectedSegmentTintColor = UIColor.white
            segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .normal)
        }
        
        // 刷新表格
        tableView.reloadData()
    }
    
    // MARK: 用户操作
    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        showingMode = sender.selectedSegmentIndex
        tableView.reloadData()
    }
    
    // MARK: 数据管理
    private func loadClipboardData() {
        let userDefaults = UserDefaults(suiteName: "group.lcl.clipboard")
        
        if let data = userDefaults?.data(forKey: "clipboardItems"),
           let items = try? JSONDecoder().decode([ClipboardItem].self, from: data) {
            self.clipboardItems = items
        } else {
            // 兼容旧格式
            let history = userDefaults?.stringArray(forKey: "clipboardHistory") ?? []
            self.clipboardItems = history.map { ClipboardItem(content: $0) }
            
            // 保存为新格式
            saveClipboardItems()
        }
        
        self.tableView.reloadData()
    }
    
    private func saveClipboardItems() {
        let userDefaults = UserDefaults(suiteName: "group.lcl.clipboard")
        
        if let data = try? JSONEncoder().encode(clipboardItems) {
            userDefaults?.set(data, forKey: "clipboardItems")
        }
        
        // 兼容性保存
        let history = clipboardItems.map { $0.content }
        userDefaults?.set(history, forKey: "clipboardHistory")
    }
    
    private func saveCurrentClipboardContent() {
        guard hasFullAccess() else { return }
        
        if let clipboardString = UIPasteboard.general.string, !clipboardString.isEmpty {
            // 检查是否已存在
            if !clipboardItems.contains(where: { $0.content == clipboardString }) {
                let newItem = ClipboardItem(content: clipboardString)
                clipboardItems.insert(newItem, at: 0)
                saveClipboardItems()
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: 辅助方法
    private func hasFullAccess() -> Bool {
        return UIPasteboard.general.hasStrings
    }
    
    // MARK: - TableView DataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredClipboardItems.count
    }
    
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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ClipboardCell.identifier, for: indexPath) as! ClipboardCell
        
        let item = filteredClipboardItems[indexPath.row]
        cell.configure(with: item, isDarkMode: isDarkMode)
        
        // 设置固定按钮事件
        cell.pinAction = { [weak self] in
            guard let self = self else { return }
            
            if let realIndex = self.clipboardItems.firstIndex(where: { $0.id == item.id }) {
                self.clipboardItems[realIndex].isPinned.toggle()
                self.saveClipboardItems()
                self.tableView.reloadData()
            }
        }
        
        // 设置删除按钮事件
        cell.deleteAction = { [weak self] in
            guard let self = self else { return }
            
            if let realIndex = self.clipboardItems.firstIndex(where: { $0.id == item.id }) {
                self.clipboardItems.remove(at: realIndex)
                self.saveClipboardItems()
                self.tableView.reloadData()
            }
        }
        
        return cell
    }
    
    // MARK: - TableView Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = filteredClipboardItems[indexPath.row]
        
        // 输入文本
        self.textDocumentProxy.insertText(item.content)
        
        // 点击视觉反馈
        UIView.animate(withDuration: 0.1, animations: {
            if let cell = tableView.cellForRow(at: indexPath) as? ClipboardCell {
                cell.alpha = 0.5
            }
        }) { _ in
            UIView.animate(withDuration: 0.1, animations: {
                if let cell = tableView.cellForRow(at: indexPath) as? ClipboardCell {
                    cell.alpha = 1.0
                }
            })
        }
    }
}
