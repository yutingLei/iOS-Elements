//
//  ELSelect.swift
//
//  Created by conjur on 2019/4/8.
//  Copyright © 2019 Develop. All rights reserved.
//
//

/*****************************************************************
 * ELSelect
 * 选择器
 *
 * [v] 1.支持多选
 * [v] 2.使用远程或本地搜索，请使用'ELTextInput'的'fetchSuggestion[Async]'属性
 ******************************************************************/

import UIKit

public class ELSelect: UIView {
    
    /// 字符和箭头位置
    public enum Align {
        case spaceBetween
        case center
    }
    
    /// 字符和箭头位置
    public var alignItems: Align! {
        didSet { layoutSubviews() }
    }
    
    /// 选择的值
    public var value: String? {
        didSet { setPlaceholder(nil) }
    }
    
    /// 占位符
    public var placeholder: String? {
        willSet { setPlaceholder(newValue) }
    }
    
    /// 多选(false)
    public var isMultiple: Bool!
    
    /// 是否禁用(false)
    public var isDisabled: Bool! {
        willSet { setDisabled(newValue) }
    }
    
    /// 选项内容
    public var contents: [Any]?
    public var keysOfValue: [String]?
    
    /// 值标签
    var valuesLabel: UILabel!
    
    /// 箭头按钮
    var arrowImage: UIImageView!
    
    /// 选中触发
    var _onSelected: (([String]?) -> Void)?
    
    /// 弹出视图
    lazy var tablePoper: ELTablePoper = {
        let tablePoper = ELTablePoper(refrenceView: self, delegate: self)
        tablePoper.animationStyle = .unfold
        return tablePoper
    }()
    
    //MARK: Initialize
    public init(frame: CGRect, onSelected: (([String]?) -> Void)?) {
        super.init(frame: frame)
        
        backgroundColor = .white
        layer.cornerRadius = frame.height * 0.15
        layer.masksToBounds = true
        layer.borderWidth = 1
        layer.borderColor = ELColor.withHex("DCDFE6").cgColor
        
        _onSelected = onSelected
        alignItems = .spaceBetween
        isMultiple = false
        isDisabled = false
        createValuesLabel()
        createArrowButton()
    }
    
    /// Layout subviews
    public override func layoutSubviews() {
        switch alignItems! {
        case .spaceBetween:
            valuesLabel.frame = CGRect(x: 8, y: 0, width: bounds.width - 40, height: bounds.height)
            valuesLabel.textAlignment = .left
            arrowImage.frame = CGRect(x: bounds.width - 28, y: bounds.height / 2 - 10, width: 20, height: 20)
        default:
            if let text = valuesLabel.text {
                let textWidth = (text as NSString).boundingRect(with: CGSize(width: CGFloat.infinity, height: bounds.height),
                                                                options: .usesLineFragmentOrigin,
                                                                attributes: [.font: UIFont.systemFont(ofSize: 16)],
                                                                context: nil).width
                let totalWidth = min(textWidth + 8 + 20, bounds.width - 16)
                valuesLabel.frame = CGRect(x: (bounds.width - totalWidth) / 2, y: 0, width: textWidth, height: bounds.height)
                valuesLabel.textAlignment = .center
                arrowImage.frame = CGRect(x: valuesLabel.frame.maxX + 8, y: bounds.height / 2 - 10, width: 20, height: 20)
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ELSelect {
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        backgroundColor = UIColor.black.withAlphaComponent(0.05)
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        backgroundColor = UIColor.white
        if let touch = touches.first {
            let point = touch.location(in: superview)
            if frame.contains(point) {
                showPoper()
            }
        }
    }
}

extension ELSelect {
    /// Value's label
    func createValuesLabel() {
        valuesLabel = UILabel()
        valuesLabel.font = UIFont.systemFont(ofSize: 16)
        valuesLabel.textColor = ELColor.withHex("C0C4CC")
        addSubview(valuesLabel)
    }
    
    /// Arrow button
    func createArrowButton() {
        arrowImage = UIImageView()
        arrowImage.image = ELIcon.get(.arrowDown)?.stroked(by: ELColor.withHex("C0C4CC"))
        arrowImage.contentMode = .scaleAspectFit
        addSubview(arrowImage)
    }
    
    /// Touched
    @objc func showPoper() {
        tablePoper.isMultipleSelection = isMultiple
        tablePoper.contents = contents
        tablePoper.show()
    }
}

extension ELSelect {
    /// Set placeholder
    func setPlaceholder(_ text: String?) {
        if let value = value {
            valuesLabel.text = value
            valuesLabel.textColor = ELColor.withHex("606266")
        } else {
            valuesLabel.text = text ?? placeholder
            valuesLabel.textColor = ELColor.withHex("C0C4CC")
        }
        layoutSubviews()
    }
    
    /// Set isDisabled
    func setDisabled(_ disabled: Bool) {
        isUserInteractionEnabled = !disabled
        if disabled {
            let maskView = UIView(frame: bounds)
            maskView.backgroundColor = UIColor.black.withAlphaComponent(0.05)
            maskView.tag = 10001
            addSubview(maskView)
        } else {
            viewWithTag(10001)?.removeFromSuperview()
        }
    }
}

extension ELSelect: ELTablePoperProtocol {
    /// Selected option
    public func onSingleSelected(at index: Int) {
        guard let content = contents?[index] else { return }
        
        if let strValue = content as? String {
            value = strValue
            _onSelected?([strValue])
        }
        
        if let mapValue = content as? [String: Any] {
            let keys = keysOfValue ?? ["value", "subvalue"]
            value = mapValue[keys[0]] as? String
            if let value = value {
                _onSelected?([value])
            }
        }
    }
    
    /// Selected options
    public func onMultipleSelected(at indexes: [Int]) {
        guard let contents = contents, indexes.count > 0 else { value = nil; return }
        
        var values = [String]()
        for index in indexes {
            if let content = contents[index] as? String {
                values.append(content)
                continue
            }
            
            if let content = contents[index] as? [String: Any] {
                let key = keysOfValue ?? ["value"]
                if let value = content[key[0]] as? String {
                    values.append(value)
                }
            }
        }
        value = values.joined(separator: " / ")
        _onSelected?(values)
    }
}
