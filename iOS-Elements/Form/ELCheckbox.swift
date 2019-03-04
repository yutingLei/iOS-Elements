//
//  ELCheckbox.swift
//  iOS-Elements
//
//  Created by conjur on 2019/3/3.
//  ELCheckbox多选框
//  ELCheckboxGroup多选框组
//

import UIKit

public class ELCheckbox: ELSelection {
    //MARK: - Init

    /// 初始化ELCheckbox
    ///
    /// - Parameters:
    ///   - title: 标题
    ///   - fontSize: 标题字体大小
    public init(title: String, fontSize: CGFloat = 14) {
        super.init(frame: CGRect.zero, style: .checkbox, title: title, fontSize: fontSize)

        /// 添加选择指示器视图
        _selectionIndicatorView = ELSelectionIndicatorView(style: .checkbox)
        addSubview(_selectionIndicatorView!)

        /// 创建标题
        createTitleLabel(title, fontSize: fontSize)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //MARK: - Touch Delegate
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let point = touch.location(in: self)
            if (bounds.contains(point)) {
                unowned let weakSelf = self
                onChange?(weakSelf)
            }
        }
    }
}

/// ELRadioGroup为单选框管理器
/// 由于选项默认可见，不宜过多，若选项过多，建议使用 ELSelect 选择器。
public class ELCheckboxGroup: UIView {

    /// 当前选中选项的下标
    public var selectedIndexes: [Int] {
        get {
            var indexes = [Int]()
            for i in 0..<_checkboxs.count {
                if _checkboxs[i].isSelected {
                    indexes.append(i)
                }
            }
            return indexes
        }
    }

    /// 选择Radio的回调
    public typealias ELCheckboxGroupHandler = ((ELCheckbox, Int, Bool) -> Void)
    public var onCheckboxGroupChange: ELCheckboxGroupHandler?

    /// 管理选择框
    var _selections: [Bool]!
    var _checkboxs: [ELCheckbox]!

    //MARK: - Init

    /// 初始化单选框管理视图
    ///
    /// - Parameters:
    ///   - frame: 管理视图frame值
    ///   - titles: 所有单选项的标题
    ///   - horizontal: true水平排列, false垂直排列, 默认水平
    public init?(frame: CGRect, titles: [String], horizontal: Bool = true) {

        if titles.count <= 0 {
            print("单选项个数必须大于0...")
            return nil
        }

        if titles.count > 5 {
            print("单选项个数大于5,建议使用'ELSelect'控件...")
            return nil
        }

        super.init(frame: frame)
        createCheckboxs(with: titles, horizontal: horizontal)
    }

    /// 创建单选项
    ///
    /// - Parameter titles: 单选项标题
    func createCheckboxs(with titles: [String], horizontal: Bool) {
        /// 初始化管理数组
        _selections = [Bool].init(repeating: false, count: titles.count)
        _checkboxs = [ELCheckbox]()

        /// 初始化单选项
        let fcount = CGFloat(titles.count)
        var x: CGFloat = 0
        var y: CGFloat = 0
        let w: CGFloat = horizontal ? ((frame.width - fcount - 1) / fcount) : frame.width
        let h: CGFloat = horizontal ? frame.height : ((frame.height - fcount - 1) / fcount)
        for i in 0..<titles.count {
            /// 创建选择框视图
            let container = UIView(frame: CGRect(x: x, y: y, width: w, height: h))
            container.addSubview({[unowned self] in
                let elCheckbox = ELCheckbox(title: titles[i], fontSize: 14)
                elCheckbox.center.x = elCheckbox.bounds.width / 2
                elCheckbox.center.y = container.bounds.midY
                elCheckbox.onChange = self.onChange
                _checkboxs.append(elCheckbox)
                return elCheckbox
                } ())
            addSubview(container)

            if horizontal {
                x += w
            } else {
                y += h
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //MARK: - Observer
    @objc func onChange(checkbox: ELSelection) {
        let selectedIndex = _checkboxs.firstIndex { $0 == checkbox }

        if let selectedIndex = selectedIndex {
            _checkboxs[selectedIndex].isSelected = !_checkboxs[selectedIndex].isSelected
            onCheckboxGroupChange?(_checkboxs[selectedIndex], selectedIndex, _checkboxs[selectedIndex].isSelected)
        }
    }
}
