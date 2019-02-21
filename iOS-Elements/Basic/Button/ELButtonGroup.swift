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

    /// 设置管理组中按钮的标题
    /// 注意：标题按顺序设置
    ///
    /// - Parameters:
    ///   - texts: 标题数组，元素为nil表示不设置，下同
    ///   - atLefts: 标题相对于icon的位置(默认在icon的右边)，元素为nil表示不设置
    public func setTitles(_ texts: [String?], atLefts lefts: [Bool?]? = nil) {
        if lefts != nil && texts.count != lefts?.count {
            print("'texts'与'atLefts'两个数组个数不一致，无法设置...")
            return
        }
        let num = min(texts.count, count)
        for i in 0..<num {
            if let text = texts[i] {
                _allButtons[i].setTitle(text, atLeft: lefts?[i] ?? false)
            }
        }
    }

    /// 设置管理组中按钮的icon
    /// 注意：icon按顺序设置
    ///
    /// - Parameters:
    ///   - icons: icon图片，为nil表示不设置
    ///   - atLefts: 该图片相对于标题的位置(默认在标题的左边)，为nil表示不设置
    public func setIcons(_ icons: [UIImage?], atLefts lefts: [Bool?]? = nil) {
        if lefts != nil && icons.count != lefts?.count {
            print("'texts'与'atLefts'两个数组个数不一致，无法设置...")
            return
        }
        let num = min(icons.count, count)
        for i in 0..<num {
            if let icon = icons[i] {
                _allButtons[i].setIcon(icon, atLeft: lefts?[i] ?? true)
            }
        }
    }

    /// 设置管理组中按钮的风格
    /// 注意：风格是按顺序设置
    ///
    /// - Parameter styles: 按钮风格数组
    public func setStyles(_ styles: [ELButton.Style]) {
        let num = min(_allButtons.count, styles.count)
        for i in 0..<num {
            _allButtons[i].style = styles[i]
        }
    }
}
