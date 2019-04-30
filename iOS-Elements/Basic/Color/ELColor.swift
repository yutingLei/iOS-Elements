//
//  ELColor.swift
//  Colors
//
//  Created by conjur on 2019/2/19.
//

import UIKit

public class ELColor: UIColor {
    /// iOS-Elements主要颜色是蓝色
    public static let primary = ELColor.rgb(64, 158, 255)

    /// 成功场景使用的颜色
    public static let success = ELColor.rgb(103, 194, 58)

    /// 警告场景使用的颜色
    public static let warning = ELColor.rgb(230, 162, 60)

    /// 危险色
    public static let danger = ELColor.rgb(245, 108, 108)

    /// 消息提示色
    public static let info = ELColor.rgb(144, 147, 153)
    
    /// 主要文字颜色
    public static let primaryText = ELColor.withHex("#303133")
    
    /// 常规文字颜色
    public static let textColor = ELColor.withHex("#606266")
    
    /// 次要文字颜色
    public static let secondaryText = ELColor.withHex("#909399")
    
    /// 占位文字颜色
    public static let placeholderText = ELColor.withHex("#C0C4CC")
    
    /// 一级边框颜色
    public static let firstLevelBorderColor = ELColor.withHex("#DCDFE6")
    
    /// 二级边框颜色
    public static let secondLevelBorderColor = ELColor.withHex("#E4E7ED")
    
    /// 三级边框颜色
    public static let thirdLevelBorderColor = ELColor.withHex("#EBEEF5")
    
    /// 四级边框颜色
    public static let forthLevelBorderColor = ELColor.withHex("#F2F6FC")
}

//MARK: - Methods
public extension ELColor {
    
    /// 使用RGB值创建ELColor实例
    ///
    /// - Parameter values: 一系列CGFloat值，代表RGB
    /// - Returns: ELColor实例对象
    class func rgb(_ values: CGFloat...) -> ELColor {
        assert(values.count >= 3, "Please entered three values at least.")
        let rgb = values.map({ $0 > 1 ? $0 / 255 : $0 })
        return ELColor(red: rgb[0], green: rgb[1], blue: rgb[2], alpha: 1)
    }
    
    /// 使用RGB值创建ELColor实例
    ///
    /// - Parameter values: 一个含有RGB值的数组
    /// - Returns: ELColor实例对象
    class func rgb(_ values: [CGFloat]) -> ELColor {
        assert(values.count >= 3, "Please entered three values at least.")
        let rgb = values.map({ $0 > 1 ? $0 / 255 : $0 })
        return ELColor(red: rgb[0], green: rgb[1], blue: rgb[2], alpha: 1)
    }
    
    /// 使用RGBA值创建ELColor实例
    ///
    /// - Parameter values: 一系列CGFloat值，代表RGBA
    /// - Returns: ELColor实例对象
    class func rgba(_ values: CGFloat...) -> ELColor {
        assert(values.count >= 4, "Please entered three values at least.")
        let rgba = values.map({ $0 > 1 ? $0 / 255 : $0 })
        return ELColor(red: rgba[0], green: rgba[1], blue: rgba[2], alpha: rgba[3])
    }
    
    /// 使用RGBA值创建ELColor实例
    ///
    /// - Parameter values: 一个含有RGBA值的数组
    /// - Returns: ELColor实例对象
    class func rgba(_ values: [CGFloat]) -> ELColor {
        assert(values.count >= 4, "Please entered three values at least.")
        let rgba = values.map({ $0 > 1 ? $0 / 255 : $0 })
        return ELColor(red: rgba[0], green: rgba[1], blue: rgba[2], alpha: rgba[3])
    }
    
    /// 使用16进制创建ELColor实例
    /// 仅支持这些格式[0x|#|0X][RRGGBB | AARRGGBB]
    ///
    /// - Parameter value: 16进制值，或一个16进制字符串
    /// - Returns: ELColor实例对象
    class func withHex(_ value: String) -> ELColor {
        
        var rgba: [CGFloat] = [0, 0, 0, 1]
        
        /// 去掉'0x' | '0X' | '#' 这些字符
        var validValue = value.uppercased()
        validValue = validValue.replacingOccurrences(of: "0X", with: "")
        validValue = validValue.replacingOccurrences(of: "#", with: "")
        
        /// int ARGB
        if let intValue = UInt32(validValue, radix: 16) {
            if validValue.count == 8 {
                rgba[3] = CGFloat((0xff000000 & intValue) >> 24)
            }
            rgba[0] = CGFloat((0xff0000 & intValue) >> 16)
            rgba[1] = CGFloat((0xff00 & intValue) >> 8)
            rgba[2] = CGFloat((0xff & intValue))
        }
        
        return ELColor.rgba(rgba)
    }
    
    /// 颜色偏移
    ///
    /// - Parameters:
    ///   - rgb: RGB偏移值(0 ~ 1.0)
    ///   - da: 透明度偏移值(0 ~ 1.0)
    /// - Returns: 新的颜色对象
    func offset(delta rgb: CGFloat, da: CGFloat = 0) -> ELColor {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        r -= rgb
        g -= rgb
        b -= rgb
        a -= da
        return ELColor.rgba(r, g, b, a)
    }
}
