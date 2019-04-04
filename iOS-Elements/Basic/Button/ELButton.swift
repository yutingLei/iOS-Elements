//
//  ELButton.swift
//
//  Created by conjur on 2019/2/20.
//

import UIKit

public extension ELButton {
    /// 按钮样式
    enum Style {
        case normal
        case text
        case primary
        case success
        case info
        case warning
        case danger
        case custom(Any)
    }
}

public class ELButton: UIButton {
    
    /// 按钮样式(default `.normal`)
    private(set) public var style: Style!
    
    /// 按钮主题
    private(set) public var theme: ELButtonTheme!
    
    /// 朴素按钮(default `false`)
    public var isPlain: Bool! {
        willSet {
            newValue ? theme.plained() : theme.revertPlain()
            setTitleColor(theme.textColor, for: .normal)
            setTitleColor(theme.highlightTextColor, for: .highlighted)
            setImage(imageView?.image, for: .normal)
            setImage(imageView?.image, for: .highlighted)
            updateTheme()
        }
    }
    
    /// 微微圆角(default `true`)
    public var isTinyRound: Bool! {
        willSet {
            layer.cornerRadius = newValue ? 5 : (isRound ? bounds.height / 2 : 0)
            layer.masksToBounds = true
        }
    }
    
    /// 圆角(default `false`)
    public var isRound: Bool! {
        willSet {
            layer.cornerRadius = newValue ? bounds.height / 2 : (isTinyRound ? 5 : 0)
            layer.masksToBounds = true
        }
    }
    
    /// 圆形(default `false`)，注意：设置true后无法恢复，谨慎使用
    public var isCircle: Bool! {
        willSet {
            if newValue {
                frame.size.width = min(bounds.width, bounds.height)
                frame.size.height = min(bounds.width, bounds.height)
                layer.cornerRadius = min(bounds.width, bounds.height) / 2
                layer.masksToBounds = true
                setNeedsLayout()
            }
        }
    }
    
    /// 加载中(default `false`), 会自动改变isEnabled属性
    public var isLoading: Bool! {
        willSet {
            isEnabled = !newValue
            for view in subviews {
                view.alpha = (newValue && view.tag != 10001) ? 0 : 1
            }
            if newValue {
                insertSubview({
                    let loading = UIActivityIndicatorView(frame: bounds)
                    loading.center = CGPoint(x: bounds.midX, y: bounds.midY)
                    switch style! {
                    case .normal: loading.style = .gray
                    default: loading.style = .white
                    }
                    loading.startAnimating()
                    loading.tag = 10002
                    return loading
                }(), at: 0)
            } else {
                viewWithTag(10002)?.removeFromSuperview()
            }
        }
    }
    
    /// icon | image 位置(default `true`)
    public var isImageInLeft: Bool! {
        didSet {
            setNeedsLayout()
        }
    }
    
    /// 使能
    public override var isEnabled: Bool {
        willSet {
            isUserInteractionEnabled = newValue
            if !newValue {
                addSubview({
                    let maskView = UIView(frame: bounds)
                    maskView.backgroundColor = UIColor.white.withAlphaComponent(0.2)
                    maskView.tag = 10001
                    addSubview(maskView)
                    return maskView
                }())
            } else {
                viewWithTag(10001)?.removeFromSuperview()
            }
        }
    }
    
    //MARK: Private vars
    private var _title: String?
    private var _hasImage: Bool = false
    private struct Rects {
        var title = CGRect.zero
        var image = CGRect.zero
    }
    private var _rects: Rects {
        get {
            var rects = Rects()
            if isCircle {
                rects.image = CGRect(x: 0, y: 0, width: 15, height: 15)
                rects.image.origin.x = (bounds.width - 15) / 2
                rects.image.origin.y = (bounds.height - 15) / 2
                return rects
            }
            /// 布局方式: 图片宽(15), 左右边距(共16), 字符与图片间距(8)
            
            /// 计算标题布局位置
            if let text = _title {
                let textSize = (text as NSString).boundingRect(with: CGSize(width: CGFloat.infinity, height: bounds.width),
                                                               options: .usesLineFragmentOrigin,
                                                               attributes: [.font: UIFont.systemFont(ofSize: 15)],
                                                               context: nil).size
                rects.title.size = textSize
                rects.title.origin.y = (bounds.height - textSize.height) / 2
            }
            
            /// 计算图片布局
            if _hasImage {
                rects.title.size.width = min(bounds.width - 16 - 15 - 8, rects.title.width)
                rects.image.size = CGSize(width: 15, height: 15)
                rects.image.origin.y = (bounds.height - 15) / 2
            }
            
            /// 布局计算
            let total = rects.title.width + rects.image.width + (_hasImage ? 8 : 0)
            let x = (bounds.width - total) / 2
            if isImageInLeft {
                rects.image.origin.x = x
                rects.title.origin.x = (x + rects.image.width + (_hasImage ? 8 : 0))
            } else {
                rects.title.origin.x = x
                rects.image.origin.x = (x + total - 15)
            }
            return rects
        }
    }
    
    //MARK: Init
    /// 初始化按钮
    ///
    /// - Parameters:
    ///   - frame: 按钮位置及大小
    ///   - style: 按钮样式, 默认 `.normal`
    public init(frame: CGRect, withStyle style: ELButton.Style = .normal) {
        super.init(frame: frame)
        self.style = style
        theme = ELButtonTheme.from(style: style) ?? ELButtonTheme()
        isPlain = false
        isTinyRound = true
        isRound = false
        isCircle = false
        isLoading = false
        isImageInLeft = true
        
        if let backgroundColor = theme.backgroundColor {
            self.backgroundColor = backgroundColor
        }
        if let borderColor = theme.borderColor {
            layer.borderColor = borderColor.cgColor
            layer.borderWidth = 1
        }
    }
    
    /// 绘制
    func updateTheme() {
        if isHighlighted {
            if let highlightBorderColor = theme.highlightBorderColor {
                layer.borderColor = highlightBorderColor.cgColor
                layer.borderWidth = 1
            } else {
                layer.borderWidth = 0
            }
            if let highlightBackgroundColor = theme.highlightBackgroundColor {
                backgroundColor = highlightBackgroundColor
            }
        } else {
            if let borderColor = theme.borderColor {
                layer.borderColor = borderColor.cgColor
                layer.borderWidth = 1
            } else {
                layer.borderWidth = 0
            }
            if let backgroundColor = theme.backgroundColor {
                self.backgroundColor = backgroundColor
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {}
}

//MARK: Override
extension ELButton {
    /// 设置文字颜色，仅`.normal`, `.highlighted`两种状态
    public override func setTitleColor(_ color: UIColor?, for state: UIControl.State) {
        if state == .normal {
            theme.textColor = color ?? theme.textColor
            super.setTitleColor(theme.textColor, for: .normal)
        }
        if state == .highlighted {
            theme.highlightTextColor = color ?? theme.highlightTextColor
            super.setTitleColor(theme.highlightTextColor, for: .highlighted)
        }
    }
    
    /// 设置标题
    public override func setTitle(_ title: String?, for state: UIControl.State) {
        _title = title
        super.setTitle(title, for: .normal)
        setTitleColor(theme.textColor, for: .normal)
        setTitleColor(theme.highlightTextColor, for: .highlighted)
        titleLabel?.font = UIFont.systemFont(ofSize: 15)
    }
    
    /// 设置图片
    public override func setImage(_ image: UIImage?, for state: UIControl.State) {
        _hasImage = image != nil
        if state == .normal {
            if let iconColor = theme.iconColor {
                super.setImage(image?.stroked(by: iconColor), for: .normal)
            } else {
                super.setImage(image, for: .normal)
            }
        }
        if state == .highlighted {
            if let highlightIconColor = theme.highlightIconColor {
                super.setImage(image?.stroked(by: highlightIconColor), for: .highlighted)
            } else {
                super.setImage(image, for: .highlighted)
            }
        }
        imageView?.contentMode = .scaleAspectFit
    }
    
    /// 设置图片
    public func setImage(_ iconName: ELIcon.Name, for state: UIControl.State) {
        setImage(ELIcon.get(iconName), for: .normal)
        setImage(ELIcon.get(iconName), for: .highlighted)
    }
    
    /// 点击事件触发
    public override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        isHighlighted = true
        updateTheme()
        return super.beginTracking(touch, with: event)
    }
    
    /// 取消点击事件触发
    public override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        isHighlighted = false
        updateTheme()
    }
    
    public override func cancelTracking(with event: UIEvent?) {
        isHighlighted = false
        updateTheme()
    }
    
    /// 标题绘制区域
    public override func titleRect(forContentRect contentRect: CGRect) -> CGRect {
        return _rects.title
    }
    
    /// 图片绘制区域
    public override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        return _rects.image
    }
}
