//
//  ELCheckItem.swift
//  iOS-Elements
//
//  Created by conjur on 2019/2/22.
//  ELSelection：选择框，请使用子类ELRadio或ELCheckBox
//

import UIKit

/// 单选框/多选框 协议
@objc public protocol ELSelectionDelegate: NSObjectProtocol {

    /// 单选框状态变更触发
    ///
    /// - Parameter radio: 单选框对象
    @objc optional func onRadioStatusChanged(_ radio: ELRadio)

    /// 单选框组中的单选框状态变更触发
    ///
    /// - Parameters:
    ///   - radioGroup: 单选框组对象
    ///   - from: 当前单选框下标
    ///   - to: 将要改变的单选框的下标
    @objc optional func onRadioGroupStatusChanged(_ radioGroup: ELRadioGroup, from: Int, to: Int)

//    @objc optional func onCheckboxStatusChanged(_ checkbox: ELCheckbox)
//    @objc optional func onCheckboxGroupStatusChanged(_ checkboxGroup: ELCheckboxGroup, from: Int, to: Int)
}

/// 请使用子类ELRadio或ELCheckBox
public class ELSelection: UIView {

    /// 选择框类型
    ///
    /// - radio: 单选框
    /// - checkbox: 多选框
    /// - button: 按钮样式
    public enum Style {
        case radio
        case checkbox
        case button
    }

    /// 选择框样式
    var _style: Style?

    /// 选中指示视图(radio/checkbox)
    var _selectionIndicatorView: ELSelectionIndicatorView?

    /// 选中指示按钮(button模式)
    var _selectionButton: ELButton?

    /// 描述文字标签
    var _titleLabel: UILabel?

    /// 选择框选中后的颜色
    var _selectColor: UIColor = UIColor.rgb(96, 98, 102)
    public var selectedColor: UIColor = ELColor.primary {
        didSet {
            _selectionIndicatorView?._selectedColor = selectedColor
        }
    }

    /// 状态改变触发回调
    public var onChange: ((ELSelection) -> Swift.Void)?

    /// 是否选中状态
    public var isSelected: Bool = false {
        didSet {
            _titleLabel?.textColor = isSelected ? selectedColor : _selectColor
            _selectionIndicatorView?._isSelected = isSelected
        }
    }

    /// 是否禁用
    public var isEnabled: Bool = true {
        willSet {
            isUserInteractionEnabled = newValue
            if newValue {
                layer.mask = nil
            } else {
                layer.mask = {
                    let maskLayer = CAShapeLayer()
                    maskLayer.frame = bounds
                    maskLayer.backgroundColor = UIColor.white.withAlphaComponent(0.5).cgColor
                    return maskLayer
                }()
            }
        }
    }

    //MARK: - Init

    /// 快捷初始化
    ///
    /// - Parameters:
    ///   - frame: 视图frame值
    ///   - style: 选择框类型
    init(frame: CGRect, style: Style, title: String, fontSize: CGFloat = 14) {
        super.init(frame: frame)
        _style = style
        clipsToBounds = true
        backgroundColor = .white
    }

    /// 创建文字描述标签
    ///
    /// - Parameters:
    ///   - title: 标题
    ///   - fontSize: 字体大小
    func createTitleLabel(_ title: String, fontSize: CGFloat) {
        /// 设置标题
        if _style == .button {
            _selectionButton = ELButton.init(frame: bounds)
            _selectionButton?.isPlain = true
            _selectionButton?.setTitle(title, withFont: UIFont.systemFont(ofSize: fontSize))
            addSubview(_selectionButton!)
            return
        }

        _titleLabel = UILabel()
        _titleLabel?.text = title
        _titleLabel?.textColor = _selectColor
        _titleLabel?.font = UIFont.systemFont(ofSize: fontSize)
        let labelRect = (title as NSString).boundingRect(with: CGSize(width: CGFloat.infinity, height: CGFloat.infinity),
                                                         options: .usesLineFragmentOrigin,
                                                         attributes: [NSAttributedString.Key.font: _titleLabel!.font],
                                                         context: nil)
        _titleLabel?.frame = CGRect(x: 21, y: 0, width: labelRect.width, height: labelRect.height)
        addSubview(_titleLabel!)
        sizeToFit()
    }

    /// 计算视图的大小
    public override func sizeToFit() {
        var size = CGSize.zero

        /// 获取指示器视图的大小
        if let indicator = _selectionIndicatorView {
            size = indicator.frame.size
        }

        /// 指示器与标题之间有5的间隔
        if let title = _titleLabel {
            size.width += 5
            size.width += title.frame.width
            size.height = max(size.height, title.frame.height)
        }
        frame.size = size

        /// 使指示器视图与标题居中
        if let indicator = _selectionIndicatorView, let title = _titleLabel {
            indicator.center.y = bounds.midY
            title.center.y = bounds.midY
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//MARK: - Indicator View
/// 指示器视图
class ELSelectionIndicatorView: UIView {

    /// 选择框风格
    var _style: ELSelection.Style!

    /// 选择框选中后的颜色
    var _selectedColor: UIColor = ELColor.primary {
        didSet {
            setNeedsDisplay()
        }
    }

    /// 是否是选中状态
    var _isSelected: Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }

    /// 快捷初始化
    ///
    /// - Parameters:
    ///   - frame: 视图frame值
    ///   - style: 选择框类型
    init(style: ELSelection.Style) {
        super.init(frame: CGRect(x: 0, y: 0, width: 16, height: 16))
        _style = style
        clipsToBounds = true
        layer.cornerRadius = style == .radio ? 8 : 3
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Draw for .checkbox
    override func draw(_ rect: CGRect) {
        if _style == .radio {
            layer.borderWidth = _isSelected ? 5 : 1
            layer.borderColor = (_isSelected ? _selectedColor : UIColor.rgb(96, 98, 102)).cgColor
        } else {

        }
    }

}
