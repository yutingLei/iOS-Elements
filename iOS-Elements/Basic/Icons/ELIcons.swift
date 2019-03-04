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
    public enum Names: String {
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
//        case loading = "el-icon-loading"
    }


    /// 获取自带Icon图片
    ///
    /// - Parameters:
    ///   - type: icon类型
    ///   - tintColor: 绘制颜色, 不设置默认为black
    ///   - withSize: 绘制大小，不设置默认96x96
    /// - Returns: icon图片对象
    public class func get(_ name: Names, withColor tintColor: UIColor? = nil, andSize size: CGFloat? = nil) -> UIImage? {
        guard let iconsPath = iconsPath else { return nil }
        let iconFilePath = URL(fileURLWithPath: iconsPath + "/" + name.rawValue + ".png")
        do {
            let iconData = try Data(contentsOf: iconFilePath)
            var icon = UIImage(data: iconData)
            if let tintColor = tintColor {
                icon = icon?.render(with: tintColor, toSize: size)
            }
            return icon
        } catch {
            return nil
        }
    }
}
