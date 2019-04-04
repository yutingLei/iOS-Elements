//
//  ELButtonTheme.swift
//  ELButton's theme
//
//  Created by admin on 2019/4/4.
//  Copyright © 2019 Develop. All rights reserved.
//

import UIKit

public class ELButtonTheme: Decodable {
    
    /// 保留颜色
    private var reservedColor: ELColor?
    
    /// 文字颜色
    public var textColor: UIColor?
    
    /// 文字高亮颜色
    public var highlightTextColor: UIColor?
    
    /// icon颜色
    public var iconColor: UIColor?
    
    /// icon高亮颜色
    public var highlightIconColor: UIColor?
    
    /// 边框颜色
    public var borderColor: UIColor?
    
    /// 边框高亮颜色
    public var highlightBorderColor: UIColor?
    
    /// 背景颜色
    public var backgroundColor: UIColor?
    
    /// 背景高亮颜色
    public var highlightBackgroundColor: UIColor?
    
    public required init(from decoder: Decoder) throws {}
    
    public init() {}
    
    /// 声明初始化
    class func from(style: ELButton.Style) -> ELButtonTheme? {
        let theme = ELButtonTheme()
        switch style {
        case .normal:
            theme.reservedColor = ELColor.primary
            theme.textColor = ELColor.withHex("303133")
            theme.highlightTextColor = ELColor.primary
            theme.iconColor = ELColor.withHex("303133")
            theme.highlightIconColor = ELColor.primary
            theme.borderColor = ELColor.rgb(96, 98, 102).withAlphaComponent(0.8)
            theme.highlightBorderColor = ELColor.primary
            theme.backgroundColor = .white
            theme.highlightBackgroundColor = ELColor.primary.withAlphaComponent(0.2)
            return theme
        case .text:
            theme.textColor = ELColor.primary
            theme.highlightTextColor = ELColor.primary.offset(delta: 0.1)
            return theme
        case .success:
            theme.reservedColor = ELColor.success
        case .info:
            theme.reservedColor = ELColor.info
        case .warning:
            theme.reservedColor = ELColor.warning
        case .danger:
            theme.reservedColor = ELColor.danger
        case .custom(let themeObj):
            if let data = themeObj as? Data {
                return try? JSONDecoder().decode(ELButtonTheme.self, from: data)
            } else if let string = themeObj as? String, let data = string.data(using: .utf8) {
                return try? JSONDecoder().decode(ELButtonTheme.self, from: data)
            } else if let dictionary = themeObj as? [String: Any],
                let data = try? JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted)
            {
                return try? JSONDecoder().decode(ELButtonTheme.self, from: data)
            }
        default:
            theme.reservedColor = ELColor.primary
        }
        
        theme.textColor = .white
        theme.highlightTextColor = .white
        theme.backgroundColor = theme.reservedColor
        theme.highlightBackgroundColor = theme.reservedColor?.offset(delta: 0.1)
        theme.iconColor = .white
        theme.highlightIconColor = .white
        return theme
    }
}

extension ELButtonTheme {
    /// 朴素化
    func plained() {
        if textColor == ELColor.withHex("303133") {
            highlightBackgroundColor = .white
        } else {
            textColor = reservedColor
            highlightTextColor = .white
            backgroundColor = reservedColor?.withAlphaComponent(0.2)
            highlightBackgroundColor = reservedColor
            borderColor = reservedColor?.withAlphaComponent(0.8)
            highlightBorderColor = reservedColor
            iconColor = reservedColor
            highlightIconColor = .white
        }
    }
    
    /// 反朴素化
    func revertPlain() {
        if textColor == ELColor.withHex("303133") {
            highlightBackgroundColor = reservedColor?.withAlphaComponent(0.2)
        } else {
            textColor = .white
            highlightTextColor = .white
            backgroundColor = reservedColor
            highlightBackgroundColor = reservedColor?.offset(delta: 0.1)
            borderColor = nil
            highlightBorderColor = nil
            iconColor = .white
            highlightIconColor = .white
        }
    }
}
