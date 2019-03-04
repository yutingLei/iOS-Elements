//
//  ELButtonGroup.swift
//  iOS-Elements
//
//  Created by conjur on 2019/2/21.
//  ELButton组
//

import UIKit

public class ELButtonGroup: UIView {

    /// 管理/创建 按钮的个数
    /// 请使用'init(frame:count:)'函数初始化
    public var count: Int {
        get {
            print("请使用'init(frame:count:)'初始化...")
            return _allButtons.count
        }
    }

    /// 管理子视图
    var _allButtons: [ELButton] = []

    //MARK: - Init
    public override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 3
        layer.masksToBounds = true
        backgroundColor = .white
    }

    /// 创建ELButton管理组视图
    ///
    /// - Parameters:
    ///   - frame: 管理组视图的frame值
    ///   - count: 创建count个ELButton
    public convenience init(frame: CGRect, count: Int) {
        self.init(frame: frame)
        createChildren(count)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //MARK: - Create

    /// 创建子视图
    func createChildren(_ count: Int) {
        guard count > 0 else {
            print("count必须大于0...")
            return
        }

        guard bounds.width > 0 && bounds.height > 0 else {
            print("视图大小不能为0...")
            return
        }

        /// 创建ELButton
        var x: CGFloat = 0
        let w = (bounds.width - CGFloat(count - 1)) / CGFloat(count)
        let h = bounds.height
        for _ in 0..<count {
            let elButton = ELButton(frame: CGRect(x: x, y: 0, width: w, height: h))
            elButton.style = .primary
            _allButtons.append(elButton)
            addSubview(elButton)
            x += (w + 1)
        }
    }

    //MARK: - Settings

    /// 仅设置多个标题
    ///
    /// - Parameter titles: 标题数组
    public func setTitles(_ titles: [String]) {
        let fontSizes = [CGFloat](repeating: 14, count: titles.count)
        setTitles(titles, withFontSizes: fontSizes)
    }

    /// 设置多个特定位置的标题
    ///
    /// - Parameters:
    ///   - titles: 标题数组
    ///   - indexes: 标题对应的位置
    public func setTitles(_ titles: [String], atIndexes indexes: [Int]) {
        guard titles.count == indexes.count else {
            print("标题与下标数组不能一一对应...")
            print("单独设置某个标题请用'setTitle(_:atIndex:withFontSize:)'")
            return
        }
        let fontSizes = [CGFloat](repeating: 14, count: titles.count)
        setTitles(titles, withFontSizes: fontSizes, atIndexes: indexes)
    }

    /// 设置多个标题并配置字体大小
    ///
    /// - Parameters:
    ///   - titles: 标题数组
    ///   - fontSizes: 标题对应的字体大小
    public func setTitles(_ titles: [String], withFontSizes fontSizes: [CGFloat]) {
        guard titles.count == fontSizes.count else {
            print("标题与字体大小数组不能一一对应...")
            print("单独设置某个标题请用'setTitle(_:atIndex:withFontSize:)'")
            return
        }
        var indexes = [Int]()
        for i in 0..<titles.count {
            indexes.append(i)
        }
        setTitles(titles, withFontSizes: fontSizes, atIndexes: indexes)
    }

    /// 设置多个特定位置的标题并配置字体大小
    ///
    /// - Parameters:
    ///   - titles: 标题数组
    ///   - fontSizes: 标题对应的字体大小
    ///   - indexes: 标题对应的位置
    public func setTitles(_ titles: [String], withFontSizes fontSizes: [CGFloat], atIndexes indexes: [Int]) {
        guard titles.count == fontSizes.count && titles.count == indexes.count else {
            print("数组个数不能一一对应...")
            print("单独设置某个标题请用'setTitle(_:atIndex:withFontSize:)'")
            return
        }
        for i in 0..<min(count, titles.count) {
            setTitle(titles[i], atIndex: indexes[i], withFontSize: fontSizes[i])
        }
    }

    /// 设置单个特定位置的标题并配置字体大小
    ///
    /// - Parameters:
    ///   - title: 标题
    ///   - index: 字体大小
    ///   - fontSize: 标题位置
    public func setTitle(_ title: String, atIndex index: Int, withFontSize fontSize: CGFloat = 14) {
        _allButtons[index].setTitle(title, withFont: UIFont.systemFont(ofSize: fontSize))
    }

    /// 仅设置多个按钮的icon
    ///
    /// - Parameter icons: icons数组，支持(UIImage | ELIcons.Names)
    public func setIcons<Element>(_ icons: [Element]) {
        let isLefts = [Bool](repeating: true, count: icons.count)
        setIcons(icons, isLefts: isLefts)
    }

    /// 设置多个特定按钮的icon
    ///
    /// - Parameters:
    ///   - icons: icons数组，支持(UIImage | ELIcons.Names)
    ///   - indexes: icon对应的按钮位置
    public func setIcons<Element>(_ icons: [Element], atIndexes indexes: [Int]) {
        guard icons.count == indexes.count else {
            print("icon与位置不能一一对应...")
            print("若单个设置请使用'setIcon(_:atIndex:isLeft:)'")
            return
        }
        setIcons(icons, atIndexes: indexes, isLefts: [Bool](repeating: true, count: icons.count))
    }

    /// 设置多个按钮的icon，并且设置该icon相对于标题的位置
    ///
    /// - Parameters:
    ///   - icons: icons数组，支持(UIImage | ELIcons.Names)
    ///   - isLefts: 该icon相对标题的位置
    public func setIcons<Element>(_ icons: [Element], isLefts: [Bool]) {
        guard icons.count == isLefts.count else {
            print("icon与位置不能一一对应...")
            print("若单个设置请使用'setIcon(_:atIndex:isLeft:)'")
            return
        }
        var indexes = [Int]()
        for i in 0..<icons.count {
            indexes.append(i)
        }
        setIcons(icons, atIndexes: indexes, isLefts: isLefts)
    }

    /// 设置多个特定按钮的icon，并且设置该icon相对于标题的位置
    ///
    /// - Parameters:
    ///   - icons: icons数组，支持(UIImage | ELIcons.Names)
    ///   - indexes: icon的位置
    ///   - isLefts: icon相对于标题的位置
    public func setIcons<Element>(_ icons: [Element], atIndexes indexes: [Int], isLefts: [Bool]) {
        guard icons.count == indexes.count && icons.count == isLefts.count else {
            print("数组个数不能一一对应...")
            print("单独设置某个标题请用'setIcon(_:atIndex:isLeft:)'")
            return
        }
        for i in 0..<min(icons.count, count) {
            setIcon(icons[i], atIndex: indexes[i], isLeft: isLefts[i])
        }
    }

    /// 设置单个特定位置的按钮的icon，并且设置该icon相对于标题的位置
    ///
    /// - Parameters:
    ///   - icon: icon对象 支持(UIImage | ELIcons.Names)
    ///   - index: 按钮位置
    ///   - isLeft: 相对于标题的位置
    public func setIcon<Element>(_ icon: Element, atIndex index: Int, isLeft: Bool) {
        if let image = icon as? UIImage {
            _allButtons[index].setIcon(image)
        }
        if let iconName = icon as? ELIcons.Names, let image = ELIcons.get(iconName) {
            _allButtons[index].setIcon(image)
        }
    }

    /// 设置多个按钮样式
    ///
    /// - Parameter styles: 按钮样式数组
    public func setStyles(_ styles: [ELButton.Style]) {
        var indexes = [Int]()
        for i in 0..<styles.count {
            indexes.append(i)
        }
        setStyles(styles, atIndexes: indexes)
    }

    /// 设置多个特定位置按钮的样式
    ///
    /// - Parameters:
    ///   - styles: 按钮样式数组
    ///   - indexes: 按钮位置位置
    public func setStyles(_ styles: [ELButton.Style], atIndexes indexes: [Int]) {
        guard styles.count == indexes.count else {
            print("数组个数不能一一对应...")
            print("单独设置某个标题请用'setStyle(_:atIndex:)'")
            return
        }
        for i in 0..<min(count, styles.count) {
            setStyle(styles[i], atIndex: indexes[i])
        }
    }

    /// 设置单个特定按钮的样式
    ///
    /// - Parameters:
    ///   - style: 按钮样式
    ///   - index: 按钮的位置
    public func setStyle(_ style: ELButton.Style, atIndex index: Int) {
        _allButtons[index].style = style
    }
}
