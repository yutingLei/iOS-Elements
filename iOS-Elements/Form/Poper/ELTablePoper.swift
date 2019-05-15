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

public extension ELTablePoper {
    /// 表格中，每一行内容描述
    enum ContentStyle {
        /// 纯文本
        case pureText
        
        /// icon和文本结合
        case iconText
        
        /// 带子标题的文本(标题与子标题平行排列)
        case subtitle1
        
        /// 带子标题的文本(标题与子标题上下排列)
        case subtitle2
    }
    
    /// 表格中，每一行内容的布局方式
    enum ContentLayout {
        /// 居左排列
        case start
        
        /// 居中排列
        case center
        
        /// 居右排列
        case end
        
        /// Only supports for iconText and subtitle1
        /// 居于两边排列
        case spaceBetween
        
        /// 同等分后，居于每一份的中间排列
        case spaceAround
    }
}

public class ELTablePoper: ELPoper {
    
    /// 多选
    public var isMultipleSelection: Bool = false
    
    /// 当内容为空时,显示提示语(默认: true)
    public var showTipsWhenNullContents: Bool = true
    
    /// 内容为空的提示语(默认: "未找到数据")
    public var tipText: String? {
        get { return tipsLabel.text }
        set { tipsLabel.text = newValue ?? "未找到数据" }
    }
    
    /// 当加载类容时,显示加载动画(默认: true)
    public var showActivityIndicatorWhenLoadingContents: Bool = true
    
    /// 对于内容样式描述(默认: .pureText)
    public var contentStyle: ContentStyle = .pureText
    
    /// 内容子视图的布局(默认: .start)
    public var contentLayout: ContentLayout = .start
    
    /// 选中项的颜色，设置有效
    public var selectedColor: UIColor?
    
    /// 需要展示的内容
    public var contents: [Any]? {
        willSet {
            shouldupdateContentView = true
        }
    }
    
    /// 取值所需的key, 和contents息息相关
    /// 如果contents是一个数据字典, 那么keysToContents就是字典中的键的名称
    /// 如果contents数据内容为[[String: Any]]
    /// keys的顺序: 标题->子标题, 此属性不设置将会默认使用["label", "value"]
    ///            icon->标题,  此属性不设置将会默认使用["icon", "value"]
    public var keysToContents: [String]?
    
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
    
    /// 提示语视图
    lazy var tipsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = ELColor.secondaryText
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "未找到数据"
        containerView.effectsView.addSubview(label)
        return label
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
        
        /// 是否显示提示语
        setTipLabel()
        
        setTheme()
    }
}

extension ELTablePoper {

    /// 创建加载视图
    func setLoadingView() {
        if showActivityIndicatorWhenLoadingContents {
            if contents == nil {
                tableView.isHidden = true
                loadingView.isHidden = false
                loadingView.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
                loadingView.center = CGPoint(x: containerView.bounds.width / 2, y: containerView.bounds.height / 2)
                loadingView.startAnimating()
                return
            }
            loadingView.stopAnimating()
            loadingView.isHidden = true
            tableView.isHidden = false
        }
    }
    
    /// 创建提示视图
    func setTipLabel() {
        if showTipsWhenNullContents {
            if contents != nil && contents?.count == 0 {
                tableView.isHidden = true
                tipsLabel.isHidden = false
                tipsLabel.frame = tableView.frame
                return
            }
            tipsLabel.isHidden = true
            tableView.isHidden = false
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
//            tableView.separatorStyle = .singleLine
//            tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
//            tableView.separatorColor = ELColor.firstLevelBorderColor
        }
    }
    
    /// 计算表格视图所需的大小
    func calculateContentViewsSize() -> CGSize {
        if isFullScreen {
            return CGSize.zero
        }
        
        /// 内容为空时且showActivityIndicatorWhenNullContents = true，显示加载动画
        if showActivityIndicatorWhenLoadingContents && contents == nil {
            return CGSize(width: 120, height: 120)
        }
        
        /// 当showTipsWhenNullContents = true，并且数据个数为0时，显示提示语
        if showTipsWhenNullContents && contents != nil && contents?.count == 0 {
            return CGSize(width: 120, height: 120)
        }
        
        /// 声明内容视图大小
        var contentSize = CGSize.zero
        
        /// 定义每个cell的高度
        let cellHeight: CGFloat = contentStyle == .subtitle2 ? 50 : 35
        
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
                
                let keys = keysToContents ?? ["label", "value"]
                
                switch contentStyle {
                case .pureText, .iconText:
                    for content in contents {
                        if let text = content[keys[0]] as? String {
                            let textWidth = text.width(withLimit: cellHeight)
                            contentSize.width = max(textWidth + 8, contentSize.width) /// 恰好宽度会被截取，所以+8dp
                        }
                    }
                    if contentStyle == .iconText {
                        contentSize.width += cellHeight
                    }
                case .subtitle1, .subtitle2:
                    for content in contents {
                        var maxWidth: CGFloat = 0
                        if let text = content[keys[0]] as? String {
                            let textWidth = text.width(withLimit: cellHeight) + 8 /// 恰好宽度会被截取，所以+8dp
                            maxWidth = textWidth
                        }
                        if let subtext = content[keys[1]] as? String {
                            let subtextWidth = subtext.width(withLimit: cellHeight, fontSize: 13) + 8 /// 恰好宽度会被截取，所以+8dp
                            if contentStyle != .subtitle1 {
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
            cell = ELTablePoperCell(style: contentStyle, layout: contentLayout, reuseIdentifier: "kELTablePoperSelectionCell")
            cell?.theme = theme
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
        var title: String?
        var subtitle: String?
        var icon: UIImage?
        if let contents = contents as? [String] {
            title = contents[indexPath.row]
        } else if let contents = contents as? [[String: Any]] {
            let keys = keysToContents ?? ((contentStyle == .iconText) ? ["icon", "value"] : ["label", "value"])
            if keys.count == 1 {
                title = contents[indexPath.row][keys[0]] as? String
                icon = contents[indexPath.row][keys[0]] as? UIImage
            } else if keys.count == 2 {
                title = contents[indexPath.row][keys[1]] as? String
                subtitle = contents[indexPath.row][keys[1]] as? String
                icon = contents[indexPath.row][keys[0]] as? UIImage
            }
        }
        cell?.setContent(with: title, subtitle: subtitle, icon: icon)
        
        /// 赋值
        cell?.isSelected = isSelected
        cell?.isDisabled = isDisabled
        cell?.selectedColor = selectedColor
        
        return cell!
    }
    
    /// 选项高度
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return contentStyle == .subtitle2 ? 50 : 35
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
        let keys = keysToContents ?? ((contentStyle == .iconText) ? ["icon", "value"] : ["label", "value"])
        for index in selectedIndexes {
            if let value = contents?[index] as? String {
                values.append(value)
            } else if let keyValue = contents?[index] as? [String: Any],
                let value = keyValue[keys[0]] as? String {
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
    
    /// 标题/纯文本
    private var titleLabel: UILabel?
    
    /// 子标题
    private var subtitleLabel: UILabel?
    
    /// 图片
    private var iconImageView: UIImageView?
    
    /// 内容样式
    private(set) var style: ELTablePoper.ContentStyle!
    
    /// 布局样式
    private(set) var layout: ELTablePoper.ContentLayout!
    
    /// 内容主题
    var theme: ELTablePoper.Theme! = .light {
        willSet { setTheme(with: newValue) }
    }
    
    /// 禁用
    var isDisabled: Bool = false
    
    /// 选中时的颜色
    var selectedColor: UIColor? {
        willSet { setTheme(with: theme) }
    }
    
    //MARK: - Init
    init(style: ELTablePoper.ContentStyle, layout: ELTablePoper.ContentLayout, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        self.style = style
        self.layout = layout
        setContents()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Create subviews
    /// Create title's label
    private func createTitleLabel() {
        if titleLabel == nil {
            titleLabel = UILabel()
            titleLabel?.translatesAutoresizingMaskIntoConstraints = false
            titleLabel?.font = UIFont.systemFont(ofSize: 15)
            addSubview(titleLabel!)
        }
        titleLabel?.isHidden = false
    }
    
    /// Create subtitle's label
    private func createSubtitleLabel() {
        if subtitleLabel == nil {
            subtitleLabel = UILabel()
            subtitleLabel?.translatesAutoresizingMaskIntoConstraints = false
            subtitleLabel?.font = UIFont.systemFont(ofSize: 13)
            addSubview(subtitleLabel!)
        }
        subtitleLabel?.isHidden = false
    }
    
    /// Create icon's imageView
    private func createIconImageView() {
        if iconImageView == nil {
            iconImageView = UIImageView()
            iconImageView?.translatesAutoresizingMaskIntoConstraints = false
            iconImageView?.contentMode = .scaleAspectFit
            addSubview(iconImageView!)
        }
        iconImageView?.isHidden = false
    }
    
    //MARK: - Cell's setting
    /// Set style
    private func setContents() {
        switch style! {
        case .pureText:
            createTitleLabel()
            titleLabel!.topAnchor.constraint(equalTo: topAnchor).isActive = true
            titleLabel!.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            titleLabel!.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
            titleLabel!.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            if layout == .end {
                titleLabel?.textAlignment = .right
            } else if layout == .center {
                titleLabel?.textAlignment = .center
            } else {
                titleLabel?.textAlignment = .left
            }
        case .iconText:
            createTitleLabel()
            createIconImageView()
            if layout == .start || layout == .spaceBetween {
                iconImageView!.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
                iconImageView!.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5).isActive = true
                iconImageView!.widthAnchor.constraint(equalToConstant: 25).isActive = true
                iconImageView!.heightAnchor.constraint(equalToConstant: 25).isActive = true
                titleLabel!.leadingAnchor.constraint(equalTo: iconImageView!.trailingAnchor).isActive = true
                titleLabel!.topAnchor.constraint(equalTo: topAnchor).isActive = true
                titleLabel!.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
                titleLabel!.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
                titleLabel!.textAlignment = (layout == .start ? .left : .right)
            }
        case .subtitle1, .subtitle2:
            createTitleLabel()
            createSubtitleLabel()
            if style == .subtitle2 {
                titleLabel!.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
                titleLabel!.topAnchor.constraint(equalTo: topAnchor, constant: 5).isActive = true
                titleLabel!.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
                titleLabel!.heightAnchor.constraint(equalToConstant: 35).isActive = true
                subtitleLabel!.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
                subtitleLabel!.topAnchor.constraint(equalTo: titleLabel!.bottomAnchor, constant: -5).isActive = true
                subtitleLabel!.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
                subtitleLabel!.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
                if layout == .start {
                    titleLabel?.textAlignment = .left
                    subtitleLabel?.textAlignment = .left
                } else if layout == .end {
                    titleLabel?.textAlignment = .right
                    subtitleLabel?.textAlignment = .right
                } else if layout == .center {
                    titleLabel?.textAlignment = .center
                    titleLabel?.textAlignment = .center
                }
            }
        }
    }
    
    /// 设置标题/子标题/图片
    func setContent(with title: String?, subtitle: String?, icon: UIImage?) {
        titleLabel?.text = title
        subtitleLabel?.text = subtitle
        iconImageView?.image = icon
        
        switch style! {
        case .iconText:
            let titleWidth = title?.width(withLimit: 35, fontSize: 15) ?? 0
            if layout == .end {
                titleLabel!.widthAnchor.constraint(equalToConstant: titleWidth).isActive = true
                titleLabel!.topAnchor.constraint(equalTo: topAnchor).isActive = true
                titleLabel!.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
                titleLabel!.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
                iconImageView!.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
                iconImageView!.trailingAnchor.constraint(equalTo: titleLabel!.leadingAnchor, constant: -5).isActive = true
                iconImageView!.widthAnchor.constraint(equalToConstant: 25).isActive = true
                iconImageView!.heightAnchor.constraint(equalToConstant: 25).isActive = true
            } else if layout == .center {
                let halfWidth = (titleWidth + 30) / 2
                iconImageView!.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
                iconImageView!.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 15 - halfWidth).isActive = true
                iconImageView!.widthAnchor.constraint(equalToConstant: 25).isActive = true
                iconImageView!.heightAnchor.constraint(equalToConstant: 25).isActive = true
                titleLabel!.leadingAnchor.constraint(equalTo: iconImageView!.trailingAnchor).isActive = true
                titleLabel!.topAnchor.constraint(equalTo: topAnchor).isActive = true
                titleLabel!.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
                titleLabel!.widthAnchor.constraint(equalToConstant: titleWidth)
            } else if layout == .spaceAround {
                iconImageView!.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
                iconImageView!.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
                iconImageView!.heightAnchor.constraint(equalToConstant: 25).isActive = true
                titleLabel!.leadingAnchor.constraint(equalTo: iconImageView!.trailingAnchor).isActive = true
                titleLabel!.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
                titleLabel!.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
                titleLabel!.widthAnchor.constraint(equalTo: iconImageView!.widthAnchor, multiplier: 1).isActive = true
                titleLabel?.textAlignment = .center
            }
        case .subtitle1:
            let titleWidth = title?.width(withLimit: 35, fontSize: 15) ?? 0
            let subtitleWidth = subtitle?.width(withLimit: 35, fontSize: 13) ?? 0
            if layout == .start {
                titleLabel!.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
                titleLabel!.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
                titleLabel!.widthAnchor.constraint(equalToConstant: titleWidth).isActive = true
                subtitleLabel!.leadingAnchor.constraint(equalTo: titleLabel!.trailingAnchor, constant: 8).isActive = true
                subtitleLabel!.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
                subtitleLabel!.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
            } else if layout == .center {
                let halfWidth = (titleWidth + subtitleWidth + 8) / 2
                titleLabel!.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
                titleLabel!.leadingAnchor.constraint(equalTo: centerXAnchor, constant: -halfWidth).isActive = true
                titleLabel!.widthAnchor.constraint(equalToConstant: titleWidth).isActive = true
                subtitleLabel!.leadingAnchor.constraint(equalTo: titleLabel!.trailingAnchor, constant: 8).isActive = true
                subtitleLabel!.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
                subtitleLabel!.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
                subtitleLabel?.textAlignment = .left
            } else if layout == .end {
                subtitleLabel!.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
                subtitleLabel!.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
                subtitleLabel!.widthAnchor.constraint(equalToConstant: subtitleWidth).isActive = true
                titleLabel!.trailingAnchor.constraint(equalTo: subtitleLabel!.leadingAnchor, constant: 8).isActive = true
                titleLabel!.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
                titleLabel!.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
                titleLabel?.textAlignment = .right
                subtitleLabel?.textAlignment = .right
            } else if layout == .spaceBetween {
                titleLabel!.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
                titleLabel!.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
                titleLabel!.widthAnchor.constraint(equalToConstant: titleWidth).isActive = true
                titleLabel?.textAlignment = .left
                subtitleLabel!.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
                subtitleLabel!.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
                subtitleLabel!.leadingAnchor.constraint(equalTo: titleLabel!.trailingAnchor, constant: 8).isActive = true
                subtitleLabel?.textAlignment = .right
            } else if layout == .spaceAround {
                titleLabel!.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
                titleLabel?.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
                titleLabel?.trailingAnchor.constraint(equalTo: centerXAnchor).isActive = true
                titleLabel?.textAlignment = .center
                
                subtitleLabel!.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
                subtitleLabel!.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
                subtitleLabel!.leadingAnchor.constraint(equalTo: centerXAnchor).isActive = true
                subtitleLabel?.textAlignment = .center
            }
        default: break
        }
    }
    
    /// Set disabled
    func setDisabled(with newValue: Any?) {
        if let value = newValue as? String {
            isDisabled = value == "true"
        } else if let value = newValue as? Bool {
            isDisabled = value
        } else {
            isDisabled = false
        }
        setTheme(with: theme)
    }
    
    /// Set theme
    func setTheme(with newTheme: ELPoper.Theme) {
        if newTheme == .light {
            if isDisabled {
                titleLabel?.textColor = ELColor.secondaryText
                subtitleLabel?.textColor = ELColor.secondaryText
                iconImageView?.image = iconImageView?.image?.stroked(by: ELColor.secondaryText)
            } else {
                let color = selectedColor ?? ELColor.primary
                titleLabel?.textColor = isSelected ? color : ELColor.primaryText
                subtitleLabel?.textColor = isSelected ? color : ELColor.textColor
                iconImageView?.image = iconImageView?.image?.stroked(by: isSelected ? color : ELColor.primaryText)
            }
            backgroundColor = .white
        } else {
            if isDisabled {
                titleLabel?.textColor = ELColor.secondaryText
                subtitleLabel?.textColor = ELColor.secondaryText
                iconImageView?.image = iconImageView?.image?.stroked(by: ELColor.secondaryText)
            } else {
                let color = selectedColor ?? ELColor.primary
                titleLabel?.textColor = isSelected ? color : .white
                subtitleLabel?.textColor = isSelected ? color : ELColor.placeholderText
                iconImageView?.image = iconImageView?.image?.stroked(by: isSelected ? color : .white)
            }
            backgroundColor = ELColor.rgb(54, 55, 56)
        }
    }
}
