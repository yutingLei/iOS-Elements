//
//  ELColor+Extra.swift
//  iOS-Elements
//
//  Created by conjur on 2019/2/19.
//  扩展UIColor方法
//

import UIKit

extension UIColor {

    /// 传入RGB值，生成颜色
    ///
    /// - Parameter values: RGB值（1~255）
    class func rgb(_ values: CGFloat...) -> UIColor {
        assert(values.count == 3, "必须传入RGB值。")
        let rgbVal = values.map({ $0 > 1 ? $0 / 255.0 : $0 })
        return UIColor(red: rgbVal[0], green: rgbVal[1], blue: rgbVal[2], alpha: 1)
    }


    /// 传入RGBA值，生成颜色
    ///
    /// - Parameter values: RGBA值（1~255）
    class func rgba(_ values: CGFloat...) -> UIColor {
        assert(values.count == 4, "必须传入RGBA值。")
        let rgbaVal = values.map({ $0 > 1 ? $0 / 255.0 : $0 })
        return UIColor(red: rgbaVal[0], green: rgbaVal[1], blue: rgbaVal[2], alpha: rgbaVal[3])
    }

    /// 使当前颜色变深
    ///
    /// - Parameter deep: 深度：r = r - deep
    /// - Returns: 新和成的颜色对象
    func makeDeep(_ deep: CGFloat = 0.1) -> UIColor {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: nil)
        red -= deep
        green -= deep
        blue -= deep
        return UIColor.rgba(red, green, blue, 1)
    }
}
