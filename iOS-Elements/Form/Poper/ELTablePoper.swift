//
//  ELSelectPoper.swift
//  表格Poper
//
//  Created by admin on 2019/4/15.
//  Copyright © 2019 Develop. All rights reserved.
//

/*****************************************************************
 * ELTablePoper
 * 视图层次结构
 * keyWindow
 *      - UIView
 *          - UIView(即contentView)
 *              - UIScrollView
 *                  - [UITableView]
 *
 * 弹出视图之表格,可选择
 * [v] 1.支持多选
 * [v] 2.支持禁用选项
 * [v] 4.支持加载动画
 ******************************************************************/

import UIKit

@objc public protocol ELTablePoperProtocol: ELPoperProtocol {

    /// 在绘制过程中，是否设置选项为选中状态
    ///
    /// - Parameters:
    ///   - poper: 协议中的TablePoper对象
    ///   - index: Table中第row项是否选中
    /// - Returns: true: 选中, false: 不选中
    @objc optional func tablePoper(_ poper: ELTablePoper, setSelectedRowAt index: Int) -> Bool
    
    /// 在绘制过程中，该选项是否禁用
    /// 如果含有"disabled"字段，则以"disabled"字段为准
    ///
    /// - Parameters:
    ///   - poper: 协议中的TablePoper对象
    ///   - index: Table中第row项是否禁用
    /// - Returns: true: 禁用, false: 不禁用
    @objc optional func tablePoper(_ poper: ELTablePoper, setDisabledRowAt index: Int) -> Bool
    
    /// 当点击TablePoper中的cell时触发
    /// 单选时：indexes和values只有一个值
    /// 多选时：indexes和values可以有0个值
    ///
    /// - Parameters:
    ///   - poper: 协议中的TablePoper对象
    ///   - index: 点击的是Table中第row项
    ///   - value: 对应的值
    @objc optional func tablePoper(_ poper: ELTablePoper, didSelectedRowsAt indexes: [Int], with values: [String])
}

public class ELTablePoper: ELPoper {
    
    /// 多选
    public var isMultipleSelection: Bool = false
    
    /// 显示加载动画指示器，当内容为空时.
    public var showActivityIndicatorWhenNullContents: Bool = true
    
    /// 选择模板
    public var selectionStyle: UITableViewCell.CellStyle = .default
    
    /// 当选项在选中状态下的文字颜色
    public var selectedColor: UIColor = ELColor.primary
    
    /// 选项内容([String] | [[String: Any]])
    /// 当传入类型为[[String: Any]]时，contents取值，使用'keysOfValue'属性
    public var contents: [Any]?
    
    /// 如果contents类型为[[String: Any]]，必须设置取值的key,
    /// 若不设置，将会默认为["label", "sublabel"]
    /// 第一个key为标题，第二个为子标题
    public var keysOfValue: [String] = ["value", "subvalue"] {
        willSet {
            switch selectionStyle {
            case .`default`:
                assert(newValue.count > 0, "选择模板为'.default'时, 传入的元素个数必须大于0")
            default:
                assert(newValue.count > 1, "当选择模板不为'.default', 传入元素个数必须大于1")
            }
            shouldupdateContentView = true
        }
    }
    
    /// 选中项
    var selectedIndexes = [Int]()
    
    /// 表格中的容器视图
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.showsVerticalScrollIndicator = false
        tableView.dataSource = self
        tableView.delegate = self
        containerView.effectsView.addSubview(tableView)
        return tableView
    }()
    
    /// 加载视图
    lazy var loadingView: UIActivityIndicatorView = {
        let active = UIActivityIndicatorView()
        active.hidesWhenStopped = true
        containerView.effectsView.addSubview(active)
        return active
    }()
    
    /// 是否更新内容视图
    var shouldupdateContentView = true {
        willSet {
            if newValue {
                shouldUpdateContainerView = newValue
            }
        }
    }
    
    //MARK: - 初始化
    public init(refrenceView: UIView, withDelegate delegate: ELTablePoperProtocol?) {
        super.init(refrenceView: refrenceView, withDelegate: delegate)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public extension ELTablePoper {
    override func show() {
        
        defer {
            tableView.reloadData()
            super.show()
        }
        
        guard shouldupdateContentView else { return }
        shouldupdateContentView = false
        
        /// 计算步骤:
        ///     1.计算内容所需大小
        ///     2.根据内容所需大小计算容器视图大小
        ///     3.计算容器视图大小及位置，并且过程中会适配屏幕
        ///     4.此时根据容器视图大小计算内容视图大小及位置
        calculateContainerViewsSize(with: calculateContentViewsSize())
        calculateContainerViewsRect()
        calculateContentViewsRect()
        
        /// 是否显示加载动画
        setLoadingView()
        
        setTheme()
    }
}

extension ELTablePoper {

    /// 创建加载视图
    func setLoadingView() {
        if contents == nil && showActivityIndicatorWhenNullContents {
            tableView.isHidden = true
            loadingView.isHidden = false
            loadingView.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            loadingView.center = CGPoint(x: containerView.bounds.width / 2, y: containerView.bounds.height / 2)
            loadingView.startAnimating()
        } else {
            loadingView.stopAnimating()
            loadingView.isHidden = true
            tableView.isHidden = false
            tableView.reloadData()
        }
    }
}

//MARK: - Settings
extension ELTablePoper {
    /// 更新主题
    override func setTheme() {
        super.setTheme()
        if theme == .light {
            loadingView.style = .gray
            tableView.backgroundColor = .white
            tableView.separatorStyle = .none
        } else {
            loadingView.style = .white
            tableView.backgroundColor = ELColor.rgb(54, 55, 56)
            tableView.separatorStyle = .singleLine
            tableView.separatorInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
            tableView.separatorColor = ELColor.withHex("333333")
        }
    }
    
    /// 计算表格视图所需的大小
    func calculateContentViewsSize() -> CGSize {
        if isFullScreen {
            return CGSize.zero
        }
        
        /// 内容为空时且showActivityIndicatorWhenNullContents = true，显示加载动画
        if contents == nil && showActivityIndicatorWhenNullContents {
            return CGSize(width: 120, height: 120)
        }
        
        /// 声明内容视图大小
        var contentSize = CGSize.zero
        
        /// 定义每个cell的高度
        let cellHeight: CGFloat = selectionStyle == .subtitle ? 50 : 35
        
        /// 如果设置了固定宽度或高度
        if let fixedSize = fixedSize {
            if fixedSize.width != 0 {
                contentSize.width = fixedSize.width
            }
            if fixedSize.height != 0 {
                contentSize.height = fixedSize.height
            }
        }
        
        /// 如果宽度为0，计算最长字符串
        if contentSize.width == 0 {
            /// 当传入的内容类型为[String]时, 计算最长字符串
            if let contents = contents as? [String] {
                for text in contents {
                    let textWidth = text.width(withLimit: cellHeight) + 8
                    contentSize.width = max(textWidth, contentSize.width)
                }
            }
            
            /// 当传入的内容类型为[[String: Any]]时，根据模板计算最长字符串
            if let contents = contents as? [[String: Any]] {
                switch selectionStyle {
                case .`default`:
                    for content in contents {
                        if let text = content[keysOfValue[0]] as? String {
                            let textWidth = text.width(withLimit: cellHeight)
                            contentSize.width = max(textWidth + 8, contentSize.width) /// 恰好宽度会被截取，所以+8dp
                        }
                    }
                default:
                    for content in contents {
                        var maxWidth: CGFloat = 0
                        if let text = content[keysOfValue[0]] as? String {
                            let textWidth = text.width(withLimit: cellHeight) + 8 /// 恰好宽度会被截取，所以+8dp
                            maxWidth = textWidth
                        }
                        if selectionStyle != .default, let subtext = content[keysOfValue[1]] as? String {
                            let subtextWidth = subtext.width(withLimit: cellHeight, fontSize: 13) + 8 /// 恰好宽度会被截取，所以+8dp
                            if selectionStyle != .subtitle {
                                maxWidth = max(maxWidth, subtextWidth)
                            } else {
                                maxWidth += (subtextWidth + 8) /// 8表示标题与子标题之间的间隔
                            }
                        }
                        contentSize.width = max(contentSize.width, maxWidth)
                    }
                }
                contentSize.width = max(contentSize.width, 120)
            }
        }
        
        /// 如果高度为0，计算内容视图高度
        if contentSize.height == 0 {
            if let contents = contents {
                contentSize.height = CGFloat(contents.count) * cellHeight
            }
        }
        
        return contentSize
    }
    
    /// 计算内容视图真实位置及大小
    func calculateContentViewsRect() {
        tableView.frame = containerView.bounds
        
        /// 如果是全屏
        if isFullScreen {
            tableView.frame.origin.x = padding.left
            tableView.frame.origin.y = statusBarHeight + 40
            tableView.frame.size.width -= padding.lar
            tableView.frame.size.height -= (statusBarHeight + 40 + padding.top)
            return
        }
        
        /// 根据位置计算
        switch location {
        case .left, .right:
            if location == .left {
                tableView.frame.origin.x = padding.left
            } else {
                tableView.frame.origin.x = padding.left + (isArrowed ? suggestionArrowsHeight : 0)
            }
            tableView.frame.origin.y = padding.top
            tableView.frame.size.width -= (padding.lar + (isArrowed ? suggestionArrowsHeight : 0))
            tableView.frame.size.height -= padding.tab
        default:
            let refRect = refrenceView.convert(refrenceView.bounds, to: UIApplication.shared.keyWindow)
            if containerView.frame.midY > refRect.midY {
                tableView.frame.origin.y = padding.top + (isArrowed ? suggestionArrowsHeight : 0)
            } else {
                tableView.frame.origin.y = padding.top
            }
            tableView.frame.origin.x = padding.left
            tableView.frame.size.width -= padding.lar
            tableView.frame.size.height -= (padding.tab + (isArrowed ? suggestionArrowsHeight : 0))
        }
    }
}

extension ELTablePoper: UITableViewDataSource, UITableViewDelegate {
    /// 选项个数
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contents?.count ?? 0
    }
    
    /// 选项视图
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "kELTablePoperSelectionCell") as? ELTablePoperCell
        if cell == nil {
            cell = ELTablePoperCell(style: selectionStyle, reuseIdentifier: "kELTablePoperSelectionCell")
        }
        
        /// 选中与禁用
        var isSelected = selectedIndexes.contains(indexPath.row)
        var isDisabled = false
        if let delegate = delegate as? ELTablePoperProtocol {
            unowned let weakSelf = self
            isSelected = delegate.tablePoper?(weakSelf, setSelectedRowAt: indexPath.row) ?? isSelected
            isDisabled = delegate.tablePoper?(weakSelf, setDisabledRowAt: indexPath.row) ?? false
        }
        
        /// 赋值
        cell?.isSelected = isSelected
        cell?.isDisabled = isDisabled
        cell?.selectedColor = selectedColor
        cell?.setTexts(contents?[indexPath.row], keysOfValue: keysOfValue)
        cell?.applySettings()
        
        return cell!
    }
    
    /// 选项高度
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return selectionStyle == .subtitle ? 50 : 35
    }
    
    /// 选择
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        /// Disabled
        guard let cell = tableView.cellForRow(at: indexPath) as? ELTablePoperCell, cell.isDisabled == false else { return }
        
        /// 更新Cell
        defer {
            if isMultipleSelection {
                tableView.reloadRows(at: [indexPath], with: .none)
            }
        }
        
        /// 多选/单选选项计算
        if isMultipleSelection {
            if let index = selectedIndexes.firstIndex(of: indexPath.row) {
                selectedIndexes.remove(at: index)
            } else {
                selectedIndexes.append(indexPath.row)
            }
        } else {
            selectedIndexes.removeAll()
            selectedIndexes.append(indexPath.row)
        }
        
        /// 获取对应值
        var values = [String]()
        for index in selectedIndexes {
            if let value = contents?[index] as? String {
                values.append(value)
            } else if let keyValue = contents?[index] as? [String: Any], let value = keyValue[keysOfValue[0]] as? String {
                values.append(value)
            }
        }
        if let delegate = delegate as? ELTablePoperProtocol {
            unowned let weakSelf = self
            delegate.tablePoper?(weakSelf, didSelectedRowsAt: selectedIndexes, with: values)
        }
        
        if !isMultipleSelection {
            hide()
        }
    }
}

//MARK: - Table cell
class ELTablePoperCell: UITableViewCell {
    
    /// 标题
    var titleLabel: UILabel!
    
    /// 副标题
    lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13)
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
    /// 选中标志
    lazy var checkoutFlag: UIImageView = {
        let imageView = UIImageView()
        imageView.image = ELIcon.get(.check)?.stroked(by: ELColor.primary)
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = true
        return imageView
    }()
    
    /// 主题
    var theme: ELPoper.Theme = .light
    
    /// cell类型
    var style: CellStyle! {
        willSet { shouldUpdateConstraints = newValue != style }
    }
    
    /// 选中时的颜色
    var selectedColor: UIColor?
    
    /// 禁用
    var isDisabled: Bool = false
    
    /// 是否应该更新约束
    var shouldUpdateConstraints = true
    
    /// Initialize
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.style = style
        selectionStyle = .none
        
        
        titleLabel = UILabel()
        titleLabel?.font = UIFont.systemFont(ofSize: 15)
        contentView.addSubview(titleLabel!)
        titleLabel?.translatesAutoresizingMaskIntoConstraints = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 设置约束
    func setConstraints() {
        NSLayoutConstraint.deactivate(titleLabel.constraints)
        NSLayoutConstraint.deactivate(subtitleLabel.constraints)
        NSLayoutConstraint.deactivate(checkoutFlag.constraints)
        
        checkoutFlag.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        checkoutFlag.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        checkoutFlag.widthAnchor.constraint(equalToConstant: isSelected ? 20 : 0).isActive = true
        checkoutFlag.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        switch style! {
        case .`default`:
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            titleLabel.trailingAnchor.constraint(equalTo: checkoutFlag.leadingAnchor).isActive = true
            titleLabel.topAnchor.constraint(equalTo: topAnchor).isActive = true
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            titleLabel.textAlignment = .left
        case .subtitle:
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            titleLabel.trailingAnchor.constraint(equalTo: checkoutFlag.leadingAnchor).isActive = true
            titleLabel.topAnchor.constraint(equalTo: topAnchor).isActive = true
            titleLabel.heightAnchor.constraint(equalToConstant: 35).isActive = true
            titleLabel.textAlignment = .left
            
            subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            subtitleLabel.trailingAnchor.constraint(equalTo: checkoutFlag.leadingAnchor).isActive = true
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor).isActive = true
            subtitleLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
            subtitleLabel.textAlignment = .left
        case .value1:
            let textWidth = titleLabel.text?.width(withLimit: 35) ?? 0
            
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            titleLabel.topAnchor.constraint(equalTo: topAnchor).isActive = true
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            titleLabel.widthAnchor.constraint(equalToConstant: textWidth + 10).isActive = true
            titleLabel.textAlignment = .left
            
            subtitleLabel.topAnchor.constraint(equalTo: topAnchor).isActive = true
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor).isActive = true
            subtitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            subtitleLabel.trailingAnchor.constraint(equalTo: checkoutFlag.leadingAnchor).isActive = true
            subtitleLabel.textAlignment = .right
        default:
            let textWidth = titleLabel.text?.width(withLimit: 35) ?? 0
            
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            titleLabel.widthAnchor.constraint(equalToConstant: textWidth + 10).isActive = true
            titleLabel.topAnchor.constraint(equalTo: topAnchor).isActive = true
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            titleLabel.textAlignment = .right
            
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor).isActive = true
            subtitleLabel.trailingAnchor.constraint(equalTo: checkoutFlag.leadingAnchor).isActive = true
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor).isActive = true
            subtitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            subtitleLabel.textAlignment = .left
        }
    }
    
    /// 设置值
    func setTexts(_ info: Any?, keysOfValue keys: [String]) {
        if let info = info as? String {
            titleLabel.text = info
        } else if let info = info as? [String: Any] {
            titleLabel.text = info[keys[0]] as? String
            
            subtitleLabel.isHidden = keys.count <= 1
            if style != .default, keys.count > 1 {
                subtitleLabel.text = info[keys[1]] as? String
            }
            isDisabled = (info["disabled"] as? Bool) ?? false
        }
    }
    
    /// 应用设置
    func applySettings() {
        /// 选中
        checkoutFlag.isHidden = !isSelected
        
        /// 设置约束
        setConstraints()
        
        /// 主题颜色
        if theme == .light {
            backgroundColor = UIColor.white
            if isDisabled {
                titleLabel.textColor = ELColor.withHex("C0C4CC")
                subtitleLabel.textColor = ELColor.withHex("C0C4CC")
            } else {
                titleLabel?.textColor = isSelected ? (selectedColor ?? ELColor.primary) : ELColor.withHex("303133")
                subtitleLabel.textColor = isSelected ? (selectedColor ?? ELColor.primary) : ELColor.withHex("606266")
                checkoutFlag.image = checkoutFlag.image?.stroked(by: selectedColor ?? ELColor.primary)
            }
        } else {
            backgroundColor = ELColor.rgb(54, 55, 56)
            if isDisabled {
                titleLabel.textColor = ELColor.withHex("606266")
                subtitleLabel.textColor = ELColor.withHex("606266")
            } else {
                titleLabel?.textColor = isSelected ? (selectedColor ?? ELColor.primary) : .white
                subtitleLabel.textColor = isSelected ? (selectedColor ?? ELColor.primary) : ELColor.withHex("C0C4CC")
                checkoutFlag.image = checkoutFlag.image?.stroked(by: selectedColor ?? ELColor.white)
            }
        }
    }
}
