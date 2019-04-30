//
//  ELButtonTheme.swift
//  ELButton's theme
//
//  Created by admin on 2019/4/4.
//  Copyright © 2019 Develop. All rights reserved.
//

import UIKit

public class ELButtonTheme {
    
    /// 按钮状态
    private(set) public var state: UIControl.State!
    
    /// 样式
    private(set) public var style: ELButton.Style!
    
    /// 文字颜色
    public var textColor: UIColor!
    
    /// 背景颜色
    public var backgroundColor: UIColor!
    
    /// 边框颜色
    public var borderColor: UIColor?
    
    /// 图片颜色
    public var imageColor: UIColor?
    
    /// 保留颜色，用于朴素转换
    private var reservedColor: ELColor?
    
    /// 初始化主题
    ///
    /// - Parameters:
    ///   - style: 样式
    ///   - state: 按钮状态
    public init(style: ELButton.Style, forState state: UIControl.State) {
        self.state = state
        self.style = style
        switch style {
        case .normal:
            textColor = state == .normal ? ELColor.textColor : ELColor.primary
            backgroundColor = state == .normal ? UIColor.white : ELColor.primary.withAlphaComponent(0.2)
            borderColor = state == .normal ? ELColor.firstLevelBorderColor : ELColor.primary.withAlphaComponent(0.8)
            imageColor = state == .normal ? ELColor.textColor : ELColor.primary
            return
        case .text, .custom:
            textColor = state == .normal ? ELColor.textColor : ELColor.primary
            backgroundColor = UIColor.white
            imageColor = state == .normal ? ELColor.textColor : ELColor.primary
            return
        case .primary:
            reservedColor = ELColor.primary
            backgroundColor = state == .normal ? ELColor.primary : ELColor.primary.offset(delta: 0.2)
        case .success:
            reservedColor = ELColor.success
            backgroundColor = state == .normal ? ELColor.success : ELColor.success.offset(delta: 0.2)
        case .info:
            reservedColor = ELColor.info
            backgroundColor = state == .normal ? ELColor.info : ELColor.info.offset(delta: 0.2)
        case .warning:
            reservedColor = ELColor.warning
            backgroundColor = state == .normal ? ELColor.warning : ELColor.warning.offset(delta: 0.2)
        case .danger:
            reservedColor = ELColor.danger
            backgroundColor = state == .normal ? ELColor.danger : ELColor.danger.offset(delta: 0.2)
        }
        textColor = .white
        imageColor = .white
    }
    
    /// 能否朴素化
    public class func canPlained(with style: ELButton.Style?) -> Bool {
        if style == nil || style == .text || style == .custom {
            return false
        }
        return true
    }
    
    /// 朴素化
    public func plained() {
        guard ELButtonTheme.canPlained(with: style) else { return }
        
        if state == .normal {
            if let style = style {
                switch style {
                case .primary, .success, .info, .warning, .danger:
                    textColor = reservedColor
                    backgroundColor = reservedColor!.withAlphaComponent(0.2)
                    borderColor = reservedColor!.withAlphaComponent(0.8)
                    imageColor = reservedColor
                default: return
                }
            }
        }
        
        else if state == .highlighted || state == .selected {
            if let style = style {
                switch style {
                case .normal:
                    backgroundColor = UIColor.white
                case .primary, .success, .info, .warning, .danger:
                    textColor = .white
                    backgroundColor = reservedColor
                    borderColor = reservedColor
                    imageColor = .white
                default: return
                }
            }
        }
    }
    
    /// 逆朴素化
    public func revertPlained() {
        guard ELButtonTheme.canPlained(with: style) else { return }
        
        if state == .normal {
            if let style = style {
                switch style {
                case .primary, .success, .info, .warning, .danger:
                    textColor = .white
                    backgroundColor = reservedColor
                    borderColor = nil
                    imageColor = .white
                default: return
                }
            }
        }
            
        else if state == .highlighted || state == .selected {
            if let style = style {
                switch style {
                case .normal:
                    backgroundColor = ELColor.primary.withAlphaComponent(0.2)
                case .primary, .success, .info, .warning, .danger:
                    textColor = .white
                    backgroundColor = reservedColor!.offset(delta: 0.2)
                    borderColor = nil
                    imageColor = .white
                default: return
                }
            }
        }
    }
}
