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
    /// 当选项被选中时触发
    @objc optional func onSelected(at index: Int, with content: Any)
    
    /// 在绘制过程中，是否设置选项为选中状态
    ///
    /// - Parameter index: 第index个选项
    /// - Returns: true: 选中状态，false: 未选中状态
    @objc optional func isSelected(at index: Int) -> Bool
    
    /// 在绘制过程中，该选项是否禁用
    /// 如果含有"disabled"字段，则以"disabled"字段为准
    ///
    /// - Parameter index: 第index个选项
    /// - Returns: true: 禁用，false: 不禁用
    @objc optional func isDisabled(at index: Int) -> Bool
}

public class ELTablePoper: ELPoper {
    
    /// 多选
    public var isMultipleSelection: Bool!
    
    /// 显示加载动画指示器，当内容为空时.
    public var showActivityIndicatorWhenNullContents: Bool!
    
    /// 显示模板
    public var selectionStyle: UITableViewCell.CellStyle!
    
    /// 当选项在选中状态下的文字颜色
    public var selectedColor: UIColor?
    
    /// 选项内容([String] | [[String: Any]])
    /// 当传入类型为[[String: Any]]时，contents取值，使用'valuesKeyInContents'属性
    public var contents: [Any]?
    
    /// 如果contents类型为[[String: Any]]，必须设置取值的key,
    /// 若不设置，将会默认为["label", "sublabel"]
    /// 第一个key为标题，第二个为子标题
    public var valuesKeyInContents: [String]?
    
    /// 表格中的容器视图
    var tableView: UITableView!
    
    /// 选中项
    var selectedIndexes = [Int]()
    
    /// 加载视图
    var loadingView: UIActivityIndicatorView = {
        let active = UIActivityIndicatorView()
        active.hidesWhenStopped = true
        return active
    }()
    
    public init(refrenceView: UIView, delegate: ELTablePoperProtocol?) {
        super.init(refrenceView: refrenceView, delegate: delegate)
        selectionStyle = .default
        isMultipleSelection = false
        showActivityIndicatorWhenNullContents = true
        createTableView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public extension ELTablePoper {
    override func show() {
        let size = suggestionSizes()
        let rects = suggestionRects(with: size)
        layoutViews(with: rects)
        super.show()
    }
}

extension ELTablePoper {
    /// 创建表格视图
    func createTableView() {
        tableView = UITableView()
        tableView.showsVerticalScrollIndicator = false
        tableView.dataSource = self
        tableView.delegate = self
        contentView.addSubview(tableView)
    }
    
    /// 布局
    func layoutViews(with rects: (CGRect, CGRect)) {
        defer { updateTheme() }
        
        /// 隐藏所有子视图
        _ = contentView.subviews.map({ $0.isHidden = true })
        contentView.frame = rects.1
        
        /// 是否显示加载动画
        if contents == nil && showActivityIndicatorWhenNullContents {
            loadingView.isHidden = false
            loadingView.frame = rects.0
            loadingView.startAnimating()
            if loadingView.superview == nil {
                contentView.addSubview(loadingView)
            }
            return
        }
        
        /// 显示选项表格
        if tableView.superview == nil {
            contentView.addSubview(tableView)
        }
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = isFullScreen ? .always : .never
        }
        tableView.isHidden = false
        tableView.frame = rects.0
        tableView.reloadData()
    }
    
    /// 更新主题
    override func updateTheme() {
        super.updateTheme()
        if theme == .light {
            if contents == nil && showActivityIndicatorWhenNullContents {
                loadingView.style = .gray
            }
            tableView.backgroundColor = .white
            tableView.separatorStyle = .none
        } else {
            if contents == nil && showActivityIndicatorWhenNullContents {
                loadingView.style = .white
            }
            tableView.backgroundColor = ELColor.rgb(54, 55, 56)
            tableView.separatorStyle = .singleLine
            tableView.separatorInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
            tableView.separatorColor = ELColor.withHex("333333")
        }
    }
}

extension ELTablePoper {
    /// 计算contentView的大小
    func suggestionSizes() -> (CGSize, CGSize) {
        if isFullScreen {
            return suggestionContentSize(of: CGSize.zero)
        }
        
        /// with loading?
        if  contents == nil && showActivityIndicatorWhenNullContents {
            return suggestionContentSize(of: CGSize(width: 120, height: 120))
        }
        
        let cellHeight: CGFloat = selectionStyle! == .subtitle ? 50 : 35
        
        /// typeof 'contents' is [String]
        if let contents = contents as? [String] {
            var maxWidth: CGFloat = 0
            for content in contents {
                let width = content.widthWithLimitHeight(cellHeight)
                maxWidth = max(width, maxWidth)
            }
            return suggestionContentSize(of: CGSize(width: maxWidth + 20, height: CGFloat(contents.count) * cellHeight))
        }
        
        /// typeof 'contents' is [[String: Any]]
        if let contents = contents as? [[String: Any]] {
            let keys = valuesKeyInContents ?? ["value", "subvalue"]
            assert(keys.count > 0, "The property of 'valuesKeyInContents' that must contain 1 element.")
            var maxWidth: CGFloat = 0
            for content in contents {
                var textWidth: CGFloat = 0
                if let text = content[keys[0]] as? String {
                    textWidth = text.widthWithLimitHeight(cellHeight)
                }
                if keys.count > 1, selectionStyle != .default, let detailText = content[keys[1]] as? String {
                    let detailTextWidth = detailText.widthWithLimitHeight(20, fontSize: 13)
                    if selectionStyle == .subtitle {
                        textWidth = max(textWidth, detailTextWidth)
                    } else {
                        textWidth += (detailTextWidth + 20)
                    }
                }
                maxWidth = max(maxWidth, textWidth)
            }
            return suggestionContentSize(of: CGSize(width: maxWidth + 36, height: CGFloat(contents.count) * cellHeight))
        } else {
            assertionFailure("Unsupported type of contents, must be '[String]' or '[[String: Any]]'")
        }
        
        return suggestionContentSize(of: CGSize.zero)
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
        
        let isSelected = (delegate as? ELTablePoperProtocol)?.isSelected?(at: indexPath.row) ?? selectedIndexes.contains(indexPath.row)
        var isDisabled = (delegate as? ELTablePoperProtocol)?.isDisabled?(at: indexPath.row) ?? false
        
        /// 赋值
        if let contents = contents as? [String] {
            cell?.setText(contents[indexPath.row], valuesKey: nil)
        } else if let contents = contents as? [[String: Any]] {
            let keys = valuesKeyInContents ?? ["value", "subvalue"]
            assert(keys.count > 0, "The property of 'valuesKeyInContents' that must contain one element.")
            cell?.setText(contents[indexPath.row], valuesKey: keys[0])
            /// sublabel
            if keys.count > 1 {
                cell?.setDetailText(contents[indexPath.row], valuesKey: keys[1])
            }
            /// disabled
            isDisabled = (contents[indexPath.row]["disabled"] as? Bool) ?? false
        }
        cell?.setTextColor(selectedColor, isSelected, theme, isDisabled)
        
        return cell!
    }
    
    /// 选项高度
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return selectionStyle == .subtitle ? 50 : 35
    }
    
    /// 选择
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        (delegate as? ELTablePoperProtocol)?.onSelected?(at: indexPath.row, with: contents![indexPath.row])
        if let contents = contents as? [[String: Any]] {
            if let isDisabled = contents[indexPath.row]["disabled"] as? Bool, isDisabled {
                return
            }
            if isMultipleSelection {
                if let index = selectedIndexes.firstIndex(of: indexPath.row) {
                    selectedIndexes.remove(at: index)
                } else {
                    selectedIndexes.append(indexPath.row)
                }
                tableView.reloadRows(at: [indexPath], with: .none)
                return
            }
        }
        dismiss()
    }
}

//MARK: - Table cell
class ELTablePoperCell: UITableViewCell {
    
    /// Initialize
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        textLabel?.font = UIFont.systemFont(ofSize: 15)
        detailTextLabel?.font = UIFont.systemFont(ofSize: 13)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Text label's text
    func setText(_ value: Any, valuesKey: String?) {
        if let value = value as? String {
            textLabel?.text = value
        }
        
        if let value = value as? [String: Any], let key = valuesKey {
            textLabel?.text = value[key] as? String
        }
    }
    
    /// Detail text label's text
    func setDetailText(_ value: Any, valuesKey: String) {
        if let value = value as? [String: Any] {
            detailTextLabel?.text = value[valuesKey] as? String
        }
    }
    
    /// Colors
    func setTextColor(_ color: UIColor?, _ selected: Bool,_ theme: ELPoper.Theme,_ isDisabled: Bool) {
        if selected {
            textLabel?.textColor = color ?? ELColor.primary
            detailTextLabel?.textColor = color ?? ELColor.primary
            accessoryView = UIImageView(image: ELIcon.get(.check)?.stroked(by: color ?? ELColor.primary)?.scale(to: 20))
            return
        } else {
            accessoryView = nil
        }
        if theme == .light {
            backgroundColor = UIColor.white
            textLabel?.textColor = isDisabled ? ELColor.withHex("909399") : ELColor.withHex("303133")
            detailTextLabel?.textColor = isDisabled ? ELColor.withHex("C0C4CC") : ELColor.withHex("606266")
        } else {
            backgroundColor = ELColor.rgb(54, 55, 56)
            textLabel?.textColor = isDisabled ? ELColor.withHex("606266") : UIColor.white
            detailTextLabel?.textColor = isDisabled ? ELColor.withHex("606266") : ELColor.withHex("C0C4CC")
        }
    }
}
