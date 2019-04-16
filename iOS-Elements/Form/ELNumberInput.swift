//
//  ELTextInput.swift
//
//  Created by admin on 2019/4/8.
//  Copyright © 2019 Develop. All rights reserved.
//
//

/*****************************************************************
 * ELNumberInput
 * 数字输入组件
 *
 * [v] 1.支持阶梯加减
 * [v] 2.支持范围限制
 * [v] 3.支持精度设置
 * [v] 4.支持控制器位置设置
 ******************************************************************/

import UIKit

public extension ELNumberInput {
    enum ControlPosition {
        case leftAndRight
        case left
        case right
    }
}

/// 数字计数器, 仅允许输入标准的数字值，可定义范围
public class ELNumberInput: UITextField {
    
    /// 数值
    public var value: Decimal {
        get { return getValue() }
        set { setValue(newValue) }
    }
    
    /// 获取int值
    public var intValue: Int {
        get {
            var decimal = getValue()
            return Int(NSDecimalString(&decimal, nil)) ?? 0
        }
    }
    
    /// 获取Float值
    public var floatValue: Float {
        get {
            var decimal = getValue()
            return Float(NSDecimalString(&decimal, nil)) ?? 0
        }
    }
    
    /// 获取Doubel值
    public var doubleValue: Double {
        get {
            var decimal = getValue()
            return Double(NSDecimalString(&decimal, nil)) ?? 0
        }
    }
    
    /// 输入值上限
    public var max: Decimal? {
        didSet { disabledControl() }
    }
    
    /// 输入值下限
    public var min: Decimal? {
        didSet { disabledControl() }
    }
    
    /// 定义递增递减的步数控制
    public var step: Decimal?
    
    /// 精度，非负整数
    public var precision: Int? {
        didSet { setValue(correctionValue) }
    }
    
    /// 按钮位置
    public var controlsPosition: ControlPosition? {
        didSet {
            createControls()
        }
    }
    
    /// 边框颜色
    public var borderColorWhileEditing: UIColor!
    public var borderColorWhenDidEndEditing: UIColor!
    public var borderColorWhileillegalNumber: UIColor!
    
    /// 加减按钮
    var subControl: UIButton!
    var addControl: UIButton!
    
    /// 矫正值
    var correctionValue: Decimal!
    
    //MARK: Initialize
    public init(frame: CGRect, value: Decimal) {
        super.init(frame: frame)
        correctionValue = value
        setValue(value)
        
        /// 默认值
        borderColorWhileEditing = ELColor.primary
        borderColorWhenDidEndEditing = ELColor.withHex("E4E7ED")
        borderColorWhileillegalNumber = ELColor.danger
        
        /// 边框设置
        borderStyle = .none
        layer.borderWidth = 1
        layer.borderColor = borderColorWhenDidEndEditing.cgColor
        
        /// 其他设置
        textAlignment = .center
        textColor = ELColor.withHex("303133")
        font = UIFont.systemFont(ofSize: 14)
        
        /// 创建
        createControls()
        
        /// 添加观察者
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onInputNotified),
                                               name: UITextField.textDidChangeNotification,
                                               object: self)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onInputNotified),
                                               name: UITextField.textDidBeginEditingNotification,
                                               object: self)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onInputNotified),
                                               name: UITextField.textDidEndEditingNotification,
                                               object: self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        addControl.removeTarget(self, action: nil, for: .touchUpInside)
        subControl.removeTarget(self, action: nil, for: .touchUpInside)
        NotificationCenter.default.removeObserver(self)
    }
}

//MARK: - Create
extension ELNumberInput {
    /// Create controls
    func createControls() {
        _ = subviews.map({ $0.removeFromSuperview() })
        (leftView as? UIButton)?.removeTarget(self, action: nil, for: .touchUpInside)
        (rightView as? UIButton)?.removeTarget(self, action: nil, for: .touchUpInside)
        leftView = nil
        rightView = nil
        
        if let position = controlsPosition, position != .leftAndRight {
            let controlsContainer = UIView(frame: CGRect(x: 0, y: 0, width: 45, height: bounds.height))
            addControl = createControl(frame: CGRect(x: 0, y: 0, width: 45, height: bounds.height / 2 - 0.5))
            addControl.titleLabel?.font = UIFont.systemFont(ofSize: 12)
            addControl.setTitle("△", for: .normal)
            controlsContainer.addSubview(addControl)
            
            let splitLine = UIView(frame: CGRect(x: 0, y: bounds.height / 2 - 0.5, width: 0, height: 1))
            splitLine.backgroundColor = ELColor.withHex("C0C4CC")
            controlsContainer.addSubview(splitLine)
            
            subControl = createControl(frame: CGRect(x: 0, y: bounds.height / 2 + 0.5, width: 0, height: bounds.height / 2 - 0.5))
            subControl.titleLabel?.font = UIFont.systemFont(ofSize: 12)
            subControl.setTitle("▽", for: .normal)
            controlsContainer.addSubview(subControl)
            
            if controlsPosition == .left {
                leftView = controlsContainer
                leftViewMode = .always
            } else {
                rightView = controlsContainer
                rightViewMode = .always
            }
        } else {
            subControl = createControl()
            subControl.titleLabel?.font = UIFont.systemFont(ofSize: 18)
            subControl.setTitle("-", for: .normal)
            leftView = subControl
            leftViewMode = .always
            addControl = createControl()
            addControl.titleLabel?.font = UIFont.systemFont(ofSize: 18)
            addControl.setTitle("+", for: .normal)
            rightView = addControl
            rightViewMode = .always
        }
        
        if let leftView = leftView {
            let verticalLine = UIView(frame: CGRect(x: leftView.frame.width - 1, y: 0, width: 1, height: bounds.height))
            verticalLine.backgroundColor = ELColor.withHex("E4E7ED")
            leftView.addSubview(verticalLine)
        }
        if let rightView = rightView {
            let verticalLine = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: bounds.height))
            verticalLine.backgroundColor = ELColor.withHex("E4E7ED")
            rightView.addSubview(verticalLine)
        }
    }
    
    /// Create subtract control
    func createControl(frame: CGRect? = nil) -> UIButton {
        var rect = frame ?? {
            let normalFrame = CGRect(x: 0, y: 0, width: 0, height: bounds.height)
            return normalFrame
        }()
        rect.size.width = Swift.min(45, bounds.width * 0.3)
        let control = UIButton(frame: rect)
        control.addTarget(self, action: #selector(onControlTouched), for: .touchUpInside)
        control.backgroundColor = ELColor.withHex("F2F6FC")
        control.setTitleColor(ELColor.withHex("606266"), for: .normal)
        control.setTitleColor(ELColor.withHex("C0C4CC"), for: .selected)
        return control
    }
    
    /// On sub or add control touched
    @objc func onControlTouched(_ button: UIButton) {
        let currentValue = getValue()
        /// Sub action
        if button == subControl {
            setValue(currentValue - (step ?? 1))
        }
        
        /// Add action
        if button == addControl {
            setValue(currentValue + (step ?? 1))
        }
        disabledControl()
    }
}

extension ELNumberInput {
    /// Disabled sub or add control
    func disabledControl() {
        if let min = min {
            let islower = getValue() <= min
            subControl.isUserInteractionEnabled = !islower
            subControl.isSelected = islower
        }
        if let max = max {
            let isupper = getValue() >= max
            addControl.isUserInteractionEnabled = !isupper
            addControl.isSelected = isupper
        }
    }
    
    /// Get value of number input
    func getValue() -> Decimal {
        if let text = text, let _ = Double(text) {
            return Decimal(string: text) ?? correctionValue
        }
        return correctionValue
    }
    
    /// Set value for number input
    func setValue(_ val: Decimal) {
        correctionValue = val
        var decimalString = NSDecimalString(&correctionValue, nil)
        if let precision = precision, precision >= 0 {
            if let doubleValue = Double(decimalString) {
                decimalString = String(format: "%.\(precision)f", doubleValue)
            }
        }
        text = decimalString
    }
    
    /// Notification
    @objc func onInputNotified(_ noti: Notification) {
        guard (noti.object as? ELNumberInput) == self else { return }
        if text == nil {
            layer.borderColor = borderColorWhileillegalNumber.cgColor
            return
        }
        if let text = text, var decimalValue = Decimal(string: text), text != NSDecimalString(&decimalValue, nil) {
            layer.borderColor = borderColorWhileillegalNumber.cgColor
            return
        }
        if noti.name == UITextField.textDidEndEditingNotification {
            layer.borderColor = borderColorWhenDidEndEditing.cgColor
            setValue(getValue())
            disabledControl()
        } else {
            layer.borderColor = borderColorWhileEditing.cgColor
        }
    }
}
