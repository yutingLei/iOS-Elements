//
//  ELIcons.swift
//
//  Created by conjur on 2019/2/19.
//

import UIKit

public extension ELIcon {
    /// 定义所有icons类型
    /// 参考地址：http://element-cn.eleme.io/#/zh-CN/component/icon
    enum Name: String {
        case info = "el-icon-info"
        case error = "el-icon-error"
        case success = "el-icon-success"
        case warning = "el-icon-warning"
        case question = "el-icon-question"
        case back = "el-icon-back"
        case arrowLeft = "el-icon-arrow-left"
        case arrowDown = "el-icon-arrow-down"
        case arrowRight = "el-icon-arrow-right"
        case arrowUp = "el-icon-arrow-up"
        case caretLeft = "el-icon-caretLeft"
        case caretBottom = "el-icon-caret-bottom"
        case caretTop = "el-icon-caret-top"
        case caretRight = "el-icon-caret-right"
        case doubleArrowLeft = "el-icon-d-arrow-left"
        case doubleArrowRight = "el-icon-d-arrow-right"
        case subtract = "el-icon-minus"
        case add = "el-icon-plus"
        case remove = "el-icon-remove"
        case circlePlus = "el-icon-circle-plus"
        case removeOutline = "el-icon-remove-outline"
        case circlePlusOutline = "el-icon-circle-plus-outline"
        case close = "el-icon-close"
        case check = "el-icon-check"
        case circleClose = "el-icon-circle-close"
        case circleCheck = "el-icon-circle-check"
        case circleCloseOutline = "el-icon-circle-close-outline"
        case circleCheckOutline = "el-icon-circle-check-outline"
        case zoomOut = "el-icon-zoom-out"
        case zoomIn = "el-icon-zoom-in"
        
        //TODO: - Waitint add
//        case doubleCaret = "el-icon-d-caret"
//        case sort = "el-icon-sort"
//        case sortDown = "el-icon-sort-down"
//        case sortUp = "el-icon-sort-up"
        
        case tickets = "el-icon-tickets"
        case document = "el-icon-document"
        case goods = "el-icon-goods"
        case soldOut = "el-icon-sold-out"
        case news = "el-icon-news"
        case message = "el-icon-message"
        case date = "el-icon-date"
        case printer = "el-icon-printer"
        case time = "el-icon-time"
        case bell = "el-icon-bell"
        case mobilePhone = "el-icon-mobile-phone"
        case service = "el-icon-service"
        case view = "el-icon-view"
        case offView = "el-icon-off-view"
        case menu = "el-icon-menu"
        case more = "el-icon-more"
        case moreOutline = "el-icon-more-outline"
        case starOn = "el-icon-star-on"
        case starOff = "el-icon-star-off"
        case starHalf = "el-icon-star-half"
        case location = "el-icon-location"
        case locationOutline = "el-icon-location-outline"
        case phone = "el-icon-phone"
        case phoneOutline = "el-icon-phone-outline"
        case picture = "el-icon-picture"
        case pictureOutline = "el-icon-picture-outline"
        case delete = "el-icon-delete"
        case search = "el-icon-search"
        case edit = "el-icon-edit"
        case editOutline = "el-icon-edit-outline"
        case rank = "el-icon-rank"
        case refresh = "el-icon-refresh"
        case share = "el-icon-share"
        case setting = "el-icon-setting"
        case upload = "el-icon-upload"
        case upload2 = "el-icon-upload2"
        case download = "el-icon-download"
        
        //TODO: Waiting add
//        case loading = "el-icon-loading"
    }
    
    /// 所有图标的名称
    var availableNames: [String] {
        get {
            return [".info", ".error", ".success", ".warning", ".question", ".back",
                    ".arrowLeft", ".arrowDown", ".arrowRight", ".arrowUp", ".caretLeft", ".caretBottom",
                    ".caretTop", ".caretRight", ".doubleArrowLeft", ".doubleArrowRight", ".subtract", ".add",
                    ".remove", ".circlePlus", ".removeOutline", ".circlePlusOutline", ".close", ".check",
                    ".circleClose", ".circleCheck", ".circleCloseOutline", ".circleCheckOutline", ".zoomOut", ".zoomIn",
                    ".tickets", ".document",
                    ".goods", ".soldOut", ".news", ".message", ".date", ".printer",
                    ".time", ".bell", ".mobilePhone", ".service", ".view", ".menu",
                    ".more", ".moreOutline", ".starOn", ".starOff", ".location", ".locationOutline",
                    ".phone", ".phoneOutline", ".picture", ".pictureOutline", ".delete", ".search",
                    ".edit", ".editOutline", ".rank", ".refresh", ".share", ".setting",
                    ".upload", ".upload2", ".download"]
        }
    }
}

public class ELIcon: UIImage {
    
    /// 资源地址
    static let sourcePath = Bundle(for: ELIcon.self).path(forResource: "ELResources", ofType: "bundle")

    /// 获取图片
    ///
    /// - Parameter name: icon名称
    /// - Returns: 图片对象
    public class func get(_ name: Name) -> ELIcon? {
        guard let path = sourcePath else { return nil }
        
        // 文件路径
        let fileURL = URL(fileURLWithPath: "\(path)/\(name.rawValue).png")
        
        /// 获取文件
        do {
            let data = try Data(contentsOf: fileURL)
            return ELIcon(data: data)
        } catch {
            return nil
        }
    }
}

extension UIImage {
    
    /// 以给定颜色绘制
    ///
    /// - Parameter color: 绘制色
    /// - Returns: 新的图片
    func stroked(by color: UIColor) -> UIImage? {
        
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
    
    /// 缩放图片
    ///
    /// - Parameter newSize: 新图片的大小
    /// - Returns: 新图片
    func resize(to newSize: CGSize) -> UIImage? {
        /// Begin context
        UIGraphicsBeginImageContext(newSize)

        let rect = CGRect(origin: CGPoint.zero, size: newSize)
        
        /// Draw image
        draw(in: rect)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
    
    /// 等比缩放图片
    ///
    /// - Parameter size: 新图片大小
    /// - Returns: 新图片
    func scale(to size: CGFloat) -> UIImage? {
        return resize(to: CGSize(width: size, height: size))
    }
}
