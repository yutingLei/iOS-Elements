//
//  ELIcons+Extra.swift
//  iOS-Elements
//
//  Created by conjur on 2019/2/19.
//  扩展UIImage的方法
//

import UIKit

extension UIImage {
    func render(with color: UIColor, toSize newSize: CGFloat?) -> UIImage? {

        /// scale image?
        var renderSize = size
        if let newSize = newSize {
            renderSize = CGSize(width: newSize, height: newSize)
        }

        /// Begin context
        UIGraphicsBeginImageContextWithOptions(renderSize, false, 0)

        /// set fill color
        color.setFill()
        let rect = CGRect(origin: CGPoint.zero, size: renderSize)

        /// fill color
        UIRectFill(rect)

        /// Draw image
        draw(in: rect, blendMode: .overlay, alpha: 1)
        draw(in: rect, blendMode: .destinationIn, alpha: 1)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
}

