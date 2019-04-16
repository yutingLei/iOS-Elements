//
//  ELSelection.swift
//
//  Created by admin on 2019/4/8.
//  Copyright © 2019 Develop. All rights reserved.
//
//

/*****************************************************************
* ELSelection
* 单选或多选
*
* 注意：由于选项默认可见，不宜过多，若选项过多，建议使用 ELSelect 选择器。
*
* [v] 1.支持多种排列方式
* [v] 2.支持有序排列
* [v] 3.支持选项自定义颜色设置
******************************************************************/

import UIKit

public extension ELSelection {
    /// 单选 | 多选
    enum Mode {
        case single
        case multiple
    }
    
    /// Layout
    enum Layout {
        case vertical
        case horizontal
        case justified
        case matrix(row: Int, col: Int)
    }
    
    /// 针对有序选项的起始标志
    ///
    /// - numeric: 数字标志(1~...)
    /// - upperChar: 大写字符("A"~"Z")
    /// - lowerChar: 小写字符("a"~"z")
    /// - roman: 罗马字符("I"~"XX")
    enum Start {
        case numeric(Int)
        case upperChar(Character)
        case lowerChar(Character)
        case roman(Int)
    }
}

//MARK: - Selection
public class ELSelection: UIView {
    
    /// 选择模式(default: .single)
    public var mode: Mode! {
        willSet { updateSelectionItemsMode(with: newValue) }
    }
    
    /// 选项排列方式
    public var layout: Layout!
    
    /// 选项标题
    public var texts: [String]? {
        didSet { createSelectionItems() }
    }
    
    /// 有序选项的起始标志
    public var start: Start? { didSet { updateSelectionItemStartFlag() } }
    
    /// 选中时，选项的颜色
    public var itemSelectedColor: UIColor! { willSet { _ = items.map({ $0.selectedColor = newValue })}}
    
    /// 未选中时，选项的颜色
    public var itemSelectColor: UIColor! { willSet { _ = items.map({ $0.selectColor = newValue })}}
    
    /// 正选中时，状态的背景色
    public var itemSelectingBackgroundColor: UIColor! { willSet { _ = items.map({ $0.selectingBackgroundColor = newValue })}}
    
    /// 选项之间的间隔
    public var itemSpacing: CGFloat = 8
    
    /// 所有选项
    public var items: [ELSelectionItem] {
        get { return subviews as! [ELSelectionItem] }
    }
    
    /// 已选择的选项
    public var selectedIndexes: [Int] {
        get {
            var indexes = [Int]()
            for i in 0..<items.count {
                if items[i].isSelected {
                    indexes.append(i)
                }
            }
            return indexes
        }
        set {
            _ = items.map({ $0.isSelected = false })
            for index in newValue {
                if index >= 0 && index < items.count {
                    items[index].isSelected = true
                }
            }
        }
    }
    
    //MARK: - Initialize
    public init(frame: CGRect, withLayout layout: Layout) {
        super.init(frame: frame)
        self.layout = layout
        backgroundColor = .white
        
        mode = .single
        itemSelectedColor = ELColor.primary
        itemSelectColor = ELColor.withHex("#303133")
        itemSelectingBackgroundColor = ELColor.rgba(230, 230, 230, 0.8)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension ELSelection {
    /// 创建选项
    func createSelectionItems() {
        
        /// Remove old items
        /// 移除旧选项
        let views = subviews
        _ = views.map({ $0.removeFromSuperview() })
        
        /// Create new items
        guard let texts = texts else { return }
        for text in texts {
            let item = ELSelectionItem(frame: CGRect(x: 0, y: 0, width: bounds.width, height: 0), withMode: mode, withText: text)
            item.onChange = onChange
            item.selectColor = itemSelectColor
            item.selectedColor = itemSelectedColor
            item.selectingBackgroundColor = itemSelectingBackgroundColor
            addSubview(item)
        }
        
        /// Layout selection items
        layoutSelectionItems()
    }
    
    /// Update items mode
    func updateSelectionItemsMode(with mode: Mode) {
        for item in items {
            item._mode = mode
        }
    }
    
    /// Layout selection items
    func layoutSelectionItems() {
        var x: CGFloat = 0
        var y: CGFloat = 0
        switch layout! {
        case .vertical:
            let h = (bounds.height - itemSpacing * CGFloat(texts!.count - 1)) / CGFloat(texts!.count)
            let w = bounds.width
            for item in items {
                item.frame = CGRect(x: x, y: y, width: w, height: h)
                item._flagLabel?.frame = CGRect(x: 0, y: (h - 20) / 2, width: 20, height: 20)
                item._textLabel?.frame = CGRect(x: 24, y: 0, width: w - 24, height: h)
                y += (h + itemSpacing)
            }
        case .justified:
            for i in 0..<subviews.count {
                subviews[i].sizeToFit()
                if i != 0 {
                    if x + subviews[i].frame.width >= bounds.width {
                        x = 0
                        y += (subviews[i - 1].frame.height + itemSpacing)
                    }
                }
                subviews[i].frame.origin.x = x
                subviews[i].frame.origin.y = y
                x += (subviews[i].frame.width + itemSpacing)
            }
        case .matrix(let row, let col):
            let h = (bounds.height - itemSpacing * CGFloat(row - 1)) / CGFloat(row)
            let w = (bounds.width - itemSpacing * CGFloat(col - 1)) / CGFloat(col)
            var index = 0
            for _ in 0..<row {
                for _ in 0..<col {
                    items[index].frame = CGRect(x: x, y: y, width: w, height: h)
                    items[index]._flagLabel?.frame = CGRect(x: 0, y: (h - 20) / 2, width: 20, height: 20)
                    items[index]._textLabel?.frame = CGRect(x: 24, y: 0, width: w - 24, height: h)
                    x += (w + itemSpacing)
                    index += 1
                }
                x = 0
                y += (h + itemSpacing)
            }
        default:
            let w = (bounds.width - itemSpacing * CGFloat(texts!.count - 1)) / CGFloat(texts!.count)
            let h = bounds.height
            for item in items {
                item.frame = CGRect(x: x, y: y, width: w, height: h)
                item._flagLabel?.frame = CGRect(x: 0, y: (h - 20) / 2, width: 20, height: 20)
                item._textLabel?.frame = CGRect(x: 24, y: 0, width: w - 24, height: h)
                x += (w + itemSpacing)
            }
        }
    }
    
    /// 更新flag标志
    func updateSelectionItemStartFlag() {
        if let start = start {
            switch start {
            case .numeric(var num):
                for item in items {
                    item.flag = "\(num)"
                    num += 1
                }
            case .upperChar(var upperChar):
                for item in items {
                    item.flag = String(upperChar)
                    if let intValue = upperChar.unicodeScalars.first, let bigger = Unicode.Scalar(intValue.value + UInt32(1)) {
                        upperChar = Character(bigger)
                    } else {
                        assertionFailure("\(#file)-\(#function): Unsupport character")
                    }
                }
            case .lowerChar(var lowerChar):
                for item in items {
                    item.flag = String(lowerChar)
                    if let intValue = lowerChar.unicodeScalars.first, let bigger = Unicode.Scalar(intValue.value + UInt32(1)) {
                        lowerChar = Character(bigger)
                    } else {
                        assertionFailure("\(#file)-\(#function): Unsupport character")
                    }
                }
            case .roman(var num):
                assert(num >= 1 && num <= 20, "当前仅支持小于20的罗马数字!")
                let romanChars = ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX",
                                  "X", "XI", "XII", "XIII", "XIV", "XV", "XVI", "XVII", "XVIII", "XIX", "XX"]
                for item in items {
                    if num <= 20 {
                        item.flag = romanChars[num]
                    }
                    num += 1
                }
            }
        } else {
            for item in items {
                item.flag = nil
            }
        }
    }
    
    func onChange(_ item: ELSelectionItem) {
        if mode == .single {
            _ = items.map({ $0.isSelected = false })
            item.isSelected = true
        } else {
            item.isSelected = !item.isSelected
        }
    }
}

//MARK: - Public functions
public extension ELSelection {
    ///Disabled item at index of items
    func disabledItem(at index: Int, with value: Bool) {
        guard index >= 0 && index < items.count else { return }
        items[index].isEnabled = !value
    }
}

//MARK: - Selection Item
public class ELSelectionItem: UIControl {
    /// Callback
    fileprivate var onChange: ((ELSelectionItem) -> Void)?
    
    /// Selection item's mode
    fileprivate var _mode: ELSelection.Mode! { willSet { _flagLabel?._mode = newValue } }
    
    /// 针对有序选项的标志
    fileprivate(set) public var flag: String? {
        get { return _flagLabel?.text }
        set {
            _flagLabel?.flag = newValue
            setNeedsDisplay()
        }
    }
    fileprivate var _flagLabel: ELSelectionItemFlag?
    
    /// 选项的标题
    public var text: String? { get { return _textLabel?.text } }
    fileprivate var _textLabel: UILabel?
    
    /// 选中时，选项的颜色
    fileprivate(set) public var selectedColor: UIColor! { didSet { updateItemColor() } }
    
    /// 未选中时，选项的颜色
    fileprivate(set) public var selectColor: UIColor! { didSet { updateItemColor() } }
    
    /// 正选中时，状态的背景色
    public var selectingBackgroundColor: UIColor!
    
    /// 选中状态
    public override var isSelected: Bool {
        get { return super.isSelected }
        set {
            super.isSelected = newValue
            _flagLabel?.isSelected = newValue
            updateItemColor()
        }
    }
    
    /// 使能
    public override var isEnabled: Bool {
        willSet {
            isUserInteractionEnabled = newValue
            if !newValue {
                addSubview({
                    let mask = UIView(frame: bounds)
                    mask.backgroundColor = UIColor.white.withAlphaComponent(0.7)
                    mask.tag = 10001
                    return mask
                }())
            } else {
                viewWithTag(10001)?.removeFromSuperview()
            }
        }
    }
    
    //MARK: Initialize
    init(frame: CGRect, withMode mode: ELSelection.Mode, withText text: String) {
        super.init(frame: frame)
        _mode = mode
        createFlagLabel(with: mode)
        createTextLabel(with: text)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ELSelectionItem {
    /// Create indicator
    func createFlagLabel(with mode: ELSelection.Mode) {
        _flagLabel = ELSelectionItemFlag(frame: CGRect(x: 0, y: 0, width: 20, height: 20), withMode: mode)
        addSubview(_flagLabel!)
    }
    
    /// Create textLabel
    func createTextLabel(with text: String) {
        _textLabel = UILabel(frame: CGRect.zero)
        _textLabel?.font = UIFont.systemFont(ofSize: 16)
        _textLabel?.textAlignment = .justified
        _textLabel?.numberOfLines = 0
        _textLabel?.text = text
        addSubview(_textLabel!)
    }
    
    /// Update item's color
    func updateItemColor() {
        _flagLabel?.selectColor = selectColor
        _flagLabel?.selectedColor = selectedColor
        _textLabel?.textColor = isSelected ? selectedColor : selectColor
    }
}

extension ELSelectionItem {
    /// Fit size
    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        var fitSize = CGSize(width: 24, height: 20)
        
        /// text size
        let textSize = (_textLabel!.text! as NSString).boundingRect(with: CGSize(width: bounds.width - 24, height: CGFloat.infinity),
                                                                    options: .usesLineFragmentOrigin,
                                                                    attributes: [.font: _textLabel!.font],
                                                                    context: nil).size
        fitSize.width += textSize.width
        fitSize.height = max(fitSize.height, textSize.height)
        return fitSize
    }
    
    /// Fixed fit size
    public override func sizeToFit() {
        frame.size = sizeThatFits(CGSize.zero)
        _flagLabel?.frame.origin.x = 0
        _flagLabel?.frame.origin.y = (frame.height - 20) / 2
        _textLabel?.frame = CGRect(x: 24, y: 0, width: frame.width - 24, height: frame.height)
    }
    
    /// Begin tracking
    public override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        backgroundColor = selectingBackgroundColor
        return super.beginTracking(touch, with: event)
    }
    
    /// End tracking
    public override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        unowned let weakSelf = self
        onChange?(weakSelf)
        
        backgroundColor = superview?.backgroundColor
        super.endTracking(touch, with: event)
    }
    
}

//MARK: - 选择指示器或字符标签
class ELSelectionItemFlag: UILabel {
    
    var _mode: ELSelection.Mode! {
        willSet {
            layer.cornerRadius = newValue == .single ? 10 : 3
        }
    }
    
    /// 选中时指示器颜色或文字颜色
    var selectedColor: UIColor! {
        willSet {
            if isSelected {
                textColor = _mode == .multiple ? UIColor.white : newValue
                backgroundColor = _mode == .multiple ? newValue : .white
                layer.borderColor = newValue.cgColor
                setNeedsDisplay()
            }
        }
    }
    
    /// 未选中时指示器颜色或文字颜色
    var selectColor: UIColor! {
        willSet {
            if !isSelected {
                textColor = newValue
                backgroundColor = .white
                layer.borderColor = newValue.cgColor
                setNeedsDisplay()
            }
        }
    }
    
    /// 选中
    var isSelected: Bool! {
        willSet {
            text = flag
            if _mode == .single {
                backgroundColor = .white
                textColor = newValue ? selectedColor : selectColor
                layer.borderWidth = flag != nil ? 1 : 5
                layer.borderColor = newValue ? selectedColor.cgColor : selectColor.cgColor
            } else {
                layer.borderWidth = 1
                layer.borderColor = newValue ? selectedColor.cgColor : selectColor.cgColor
                textColor = newValue ? UIColor.white : selectColor
                backgroundColor = newValue ? selectedColor : .white
            }
            setNeedsDisplay()
        }
    }
    
    /// 标志字符
    var flag: String? {
        didSet {
            text = flag
            font = UIFont.systemFont(ofSize: fontSizeFit(with: 14))
            setNeedsDisplay()
        }
    }
    
    //MARK: Init
    init(frame: CGRect, withMode mode: ELSelection.Mode) {
        super.init(frame: frame)
        _mode = mode
        isSelected = false
        font = UIFont.systemFont(ofSize: 14)
        textAlignment = .center
        layer.masksToBounds = true
        layer.borderWidth = 1
        layer.cornerRadius = mode == .single ? 8 : 3
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 绘制
    override func draw(_ rect: CGRect) {
        if let _ = flag {
            drawText(in: rect)
            return
        }
        if _mode == .multiple && isSelected {
            let context = UIGraphicsGetCurrentContext()
            context?.setStrokeColor(UIColor.white.cgColor)
            
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 3, y: 6))
            path.addLine(to: CGPoint(x: 7, y: 11))
            path.addLine(to: CGPoint(x: 13, y: 3))
            context?.addPath(path.cgPath)
            context?.strokePath()
        }
    }
    
    /// Justified font size
    func fontSizeFit(with fontSize: CGFloat) -> CGFloat {
        if let text = text {
            let textWidth = (text as NSString).boundingRect(with: CGSize(width: CGFloat.infinity, height: 20),
                                                            options: .usesLineFragmentOrigin,
                                                            attributes: [.font: UIFont.systemFont(ofSize: fontSize)],
                                                            context: nil).width
            if textWidth > 18 {
                return fontSizeFit(with: fontSize - 1)
            }
        }
        return fontSize
    }
}
