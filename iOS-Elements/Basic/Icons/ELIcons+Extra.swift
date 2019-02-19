//
//  ELIcons+Extra.swift
//  iOS-Elements
//
//  Created by conjur on 2019/2/19.
//  扩展UIImage的方法
//

import UIKit

extension UIImage {
    func withTintColor(_ color: UIColor) -> UIImage? {
        /// Begin context
        UIGraphicsBeginImageContextWithOptions(size, false, 0)

        /// set fill color
        color.setFill()
        let rect = CGRect(origin: CGPoint.zero, size: size)

        /// fill color
        UIRectFill(rect)

        /// Draw image
        draw(in: rect, blendMode: .destinationIn, alpha: 1)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
}

