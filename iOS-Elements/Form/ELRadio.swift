//
//  ELCheckbox.swift
//  iOS-Elements
//
//  Created by conjur on 2019/2/21.
//  ELRadio单选框
//  ELRadioGroup 单选框管理组
//

import UIKit

public class ELRadio: ELSelection {

    //MARK: - Init

    /// 初始化ELRadio
    ///
    /// - Parameters:
    ///   - title: 标题
    ///   - fontSize: 标题字体大小
    public init(title: String, fontSize: CGFloat = 14) {
        super.init(frame: CGRect.zero, style: .radio, title: title, fontSize: fontSize)

        /// 添加选择指示器视图
        _selectionIndicatorView = ELSelectionIndicatorView(style: .radio)
        addSubview(_selectionIndicatorView!)

        /// 创建标题
        createTitleLabel(title, fontSize: fontSize)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //MARK: - Touch
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !isSelected {
            isSelected = true
            unowned let weakSelf = self
            onChange?(weakSelf)
        }
    }
}

/// ELRadioGroup为单选框管理器
/// 由于选项默认可见，不宜过多，若选项过多，建议使用 ELSelect 选择器。
public class ELRadioGroup: UIView {

    /// 当前选中选项的下标
    public var currentIndex: Int?

    /// 选择Radio的回调
    public typealias ELRadioGroupHandler = ((_ from: Int?, _ to: Int?) -> Void)
    public var onChangedRadio: ELRadioGroupHandler?

    /// 管理选择框
    var _selections: [Bool]!
    var _radios: [ELRadio]!

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
        createRadios(with: titles, horizontal: horizontal)
    }

    /// 创建单选项
    ///
    /// - Parameter titles: 单选项标题
    func createRadios(with titles: [String], horizontal: Bool) {
        /// 初始化管理数组
        _selections = [Bool].init(repeating: false, count: titles.count)
        _radios = [ELRadio]()

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
                let elRadio = ELRadio(title: titles[i], fontSize: 14)
                elRadio.center.x = elRadio.bounds.width / 2
                elRadio.center.y = container.bounds.midY
                elRadio.onChange = self.onChange
                _radios.append(elRadio)
                return elRadio
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
    @objc func onChange(radio: ELSelection) {
        let selectedIndex = _radios.firstIndex { $0 == radio }
        if let index = selectedIndex {
            for i in 0..<_radios.count {
                _radios[i].isSelected = index == i
            }
        }

        onChangedRadio?(currentIndex, selectedIndex)
        currentIndex = selectedIndex
    }
}
