//
//  ELButton+Theme.swift
//  iOS-Elements
//
//  Created by conjur on 2019/2/20.
//  ELButton主题
//

import UIKit

public class ELButtonTheme {
    /// 主要颜色
    var mainColor = UIColor.rgb(96, 98, 102)

    /// 标题颜色
    public var titleColor = UIColor.rgb(96, 98, 102)

    /// 按钮高亮时标题颜色
    public var highlightTitleColor = ELColor.primary

    /// 按钮背景色
    public var backgroundColor = UIColor.white

    /// 按钮高亮时背景色
    public var highlightBackgroundColor = ELColor.primary.withAlphaComponent(0.2)

    /// 边框颜色
    public var borderColor: UIColor?

    /// 按钮高亮时边框颜色
    public var highlightBorderColor: UIColor?

    /// icon颜色
    public var iconColor: UIColor?

    /// 按钮高亮时icon的颜色
    public var highlightIconColor: UIColor?

    /// 转换为朴素风格
    func convertToPlain(with style: ELButton.Style) {
        switch style {
        case .text, .customer(_):
            print("'text', 'customer'不支持朴素风格...")
            return
        case .normal:
            highlightBackgroundColor = .white
        default:
            titleColor = mainColor
            highlightTitleColor = .white
            backgroundColor = mainColor.withAlphaComponent(0.2)
            highlightBackgroundColor = mainColor
            borderColor = mainColor.withAlphaComponent(0.8)
            highlightBorderColor = mainColor
        }
    }

    /// 从朴素风格还原
    func revertFromPlain(with style: ELButton.Style) {
        switch style {
        case .text, .customer(_):
            print("'text', 'customer'不支持朴素风格...")
            return
        case .normal:
            highlightBackgroundColor = ELColor.primary.withAlphaComponent(0.2)
        default:
            titleColor = .white
            highlightTitleColor = .white
            backgroundColor = mainColor
            highlightBackgroundColor = mainColor.makeDeep()
            borderColor = nil
        }
    }

    public init() {}
}

extension ELButton {
    /// 按钮默认主题
    var normalTheme: ELButtonTheme {
        get {
            return ELButton.makeTheme(for: .normal, mainColor: UIColor.rgb(96, 98, 102))
        }
    }

    /// 文字按钮主题
    var textTheme: ELButtonTheme {
        get {
            return ELButton.makeTheme(for: .text, mainColor: ELColor.primary)
        }
    }

    /// 主要主题
    var primaryTheme: ELButtonTheme {
        get {
            return ELButton.makeTheme(for: .primary, mainColor: ELColor.primary)
        }
    }

    /// 表示成功的主题
    var successTheme: ELButtonTheme {
        get {
            return ELButton.makeTheme(for: .success, mainColor: ELColor.success)
        }
    }

    /// 表示info的主题
    var infoTheme: ELButtonTheme {
        get {
            return ELButton.makeTheme(for: .info, mainColor: ELColor.info)
        }
    }

    /// 表示警告的主题
    var warningTheme: ELButtonTheme {
        get {
            return ELButton.makeTheme(for: .warning, mainColor: ELColor.warning)
        }
    }

    /// 表示危险操作的主题
    var dangerTheme: ELButtonTheme {
        get {
            return ELButton.makeTheme(for: .danger, mainColor: ELColor.danger)
        }
    }


    /// 根据风格创建合适的主题
    ///
    /// - Parameters:
    ///   - style: 按钮风格
    ///   - mainColor: 主题主要颜色
    /// - Returns: 主题对象
    static func makeTheme(for style: Style, mainColor: UIColor) -> ELButtonTheme {
        let theme = ELButtonTheme()
        theme.mainColor = mainColor
        switch style {
        case .text:
            theme.mainColor = mainColor
            theme.titleColor = mainColor
            theme.highlightTitleColor = mainColor.makeDeep()
        case .normal:
            theme.borderColor = mainColor.withAlphaComponent(0.8)
            theme.highlightBorderColor = ELColor.primary
            theme.iconColor = UIColor.gray
            theme.highlightIconColor = ELColor.primary
        default:
            theme.titleColor = UIColor.white
            theme.highlightTitleColor = UIColor.white
            theme.backgroundColor = mainColor
            theme.highlightBackgroundColor = mainColor.makeDeep()
            theme.iconColor = UIColor.white
        }
        return theme
    }
}
