//
//  ELIcons.swift
//  iOS-Elements
//
//  Created by conjur on 2019/2/19.
//  定义常用图标
//

import UIKit

public class ELIcons: NSObject {
    /// icon资源文件地址
    static let iconsPath = Bundle(for: ELIcons.self).path(forResource: "ELResources", ofType: "bundle")

    /// 定义所有icons类型
    public enum ELIconTypes: String {
        case info = "el-icon-info.png"
    }

    /// 获取icon图片
    ///
    /// - Parameters:
    ///   - type: icon图片所属类型，大小为64x64
    /// - Returns: 获取的图片
    public class func get(_ type: ELIconTypes, tintColor: UIColor? = nil) -> UIImage? {
        guard let iconsPath = iconsPath else { return nil }
        let iconFilePath = URL(fileURLWithPath: iconsPath + "/" + type.rawValue)
        do {
            let iconData = try Data(contentsOf: iconFilePath)
            var icon = UIImage(data: iconData)
            if let tintColor = tintColor {
                icon = icon?.withTintColor(tintColor)
            }
            return icon
        } catch {
            return nil
        }
    }
}
