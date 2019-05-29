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
        case custom
    }
}

public class ELButton: UIControl {
    /// 样式(默认: .primary)
    public var style: Style = .primary {
        willSet {
            setStyle(with: newValue)
        }
    }
    
    /// 当前样式对应的按钮主题
    private(set) public var theme: ELButtonTheme!
    
    /// 图片位于字符右边(默认: false)
    public var layoutImageAtRight = false {
        willSet {
            setLayout(with: newValue)
        }
    }
    
    /// 是否为朴素按钮(默认: false)
    public var isPlained = false {
        willSet {
            setPlained(with: newValue)
        }
    }
    
    /// 是否微圆角,表示cornerRadius的值远小于按钮高度(默认: true)
    public var isTinyRounded = true {
        willSet {
            setTinyRounded(with: newValue)
        }
    }
    
    /// 是否圆角(默认: false)
    public var isRounded = false {
        willSet {
            setRounded(with: newValue)
        }
    }
    
    /// 是否圆形按钮(默认: false),此设置不可逆
    public var isCircled = false {
        willSet {
            setCircled(with: newValue)
        }
    }
    
    /// 是显示加载动画(默认: false)
    public var isLoading = false {
        willSet {
            setLoading(with: newValue)
        }
    }
    
    /// 使能
    public override var isEnabled: Bool {
        get { return super.isEnabled }
        set {
            setEnabled(with: newValue)
        }
    }
    
    /// 高亮
    public override var isHighlighted: Bool {
        get { return super.isHighlighted }
        set {
            setHighlighted(with: newValue)
        }
    }
    
    /// 选中
    public override var isSelected: Bool {
        get { return super.isSelected}
        set {
            setSelected(with: newValue)
        }
    }
    
    /// 字符标签; 注意：需要调用setTitle函数才会创建
    private(set) public var titleLabel: UILabel?
    
    /// 图片视图; 注意：需要调用setImage函数才会创建
    private(set) public var imageView: UIImageView?
    
    /// 管理主题
    private var themes = [UInt: ELButtonTheme]()
    
    /// 管理标题
    private lazy var titles = [UInt: String]()
    
    /// 管理图片
    private lazy var images = [UInt: UIImage]()
    
    /// 管理倒计时定时器
    private var timerSource: DispatchSourceTimer?
    
    /// Initialization
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        layer.cornerRadius = 5
        layer.masksToBounds = true
        themes[UIControl.State.normal.rawValue] = ELButtonTheme(style: .primary, forState: .normal)
        themes[UIControl.State.highlighted.rawValue] = ELButtonTheme(style: .primary, forState: .highlighted)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        timerSource?.cancel()
        timerSource = nil
    }
}

//MARK: - Settings
private extension ELButton {
    /// 设置style属性
    func setStyle(with newValue: Style) {
        guard style != newValue else { return }
        if newValue != .custom {
            themes[UIControl.State.normal.rawValue] = ELButtonTheme(style: newValue, forState: .normal)
            themes[UIControl.State.highlighted.rawValue] = ELButtonTheme(style: newValue, forState: .highlighted)
            setColor(for: state)
        }
    }
    
    /// 设置subviewsLayout属性
    func setLayout(with newValue: Bool) {
        guard layoutImageAtRight != newValue else { return }
    }
    
    /// 设置isPlained属性
    func setPlained(with newValue: Bool) {
        guard isPlained != newValue else { return }
        for theme in themes {
            if newValue {
                theme.value.plained()
            } else {
                theme.value.revertPlained()
            }
        }
        setColor(for: state)
    }
    
    /// 设置isTinyRounded属性
    func setTinyRounded(with newValue: Bool) {
        guard isTinyRounded != newValue else { return }
        layer.cornerRadius = newValue ? 5 : 0
        layer.masksToBounds = newValue
    }
    
    /// 设置isRounded属性
    func setRounded(with newValue: Bool) {
        guard isRounded != newValue else { return }
        layer.cornerRadius = newValue ? bounds.height / 2 : 0
        layer.masksToBounds = newValue
    }
    
    /// 设置isCircle属性
    func setCircled(with newValue: Bool) {
        guard isCircled != newValue else { return }
        frame.size.width = min(bounds.width, bounds.height)
        frame.size.height = frame.width
        layer.cornerRadius = frame.width / 2
    }
    
    /// 设置isLoading属性
    func setLoading(with newValue: Bool) {
        guard isLoading != newValue else { return }
        titleLabel?.isHidden = newValue
        imageView?.isHidden = newValue
        isEnabled = !newValue
        if newValue {
            let activity = UIActivityIndicatorView(frame: bounds)
            activity.style = (style == .normal || style == .text) ? .gray : .white
            activity.startAnimating()
            addSubview(activity)
        } else {
            _ = subviews.map({ ($0 is UIActivityIndicatorView) ? $0.removeFromSuperview() : nil })
        }
    }
    
    /// 设置使能
    func setEnabled(with newValue: Bool) {
        guard super.isEnabled != newValue else { return }
        super.isEnabled = newValue
        alpha = newValue ? 1 : 0.7
    }
    
    /// 高亮设置
    func setHighlighted(with newValue: Bool) {
        guard super.isHighlighted != newValue else { return }
        super.isHighlighted = newValue
        titleLabel?.text = titles[state.rawValue] ?? titleLabel?.text
        imageView?.image = images[state.rawValue] ?? imageView?.image
        setColor(for: state)
    }
    
    /// 选中设置
    func setSelected(with newValue: Bool) {
        guard super.isSelected != newValue else { return }
        super.isSelected = newValue
        titleLabel?.text = titles[state.rawValue]
        imageView?.image = images[state.rawValue]
        setColor(for: state)
    }
    
    /// 设置颜色
    func setColor(for state: State = .normal) {
        guard let theme = themes[state.rawValue] else { return }
        backgroundColor = theme.backgroundColor
        layer.borderColor = theme.borderColor?.cgColor
        layer.borderWidth = layer.borderColor == nil ? 0 : 1
        
        titleLabel?.textColor = theme.textColor
        if let imageColor = theme.imageColor {
            imageView?.image = imageView?.image?.stroked(by: imageColor)
        }
    }
}

//MARK: - Title & Image
public extension ELButton {
    /// 设置标题
    func setTitle(_ text: String?, for state: State) {
        guard let text = text else { return }
        
        if titleLabel == nil {
            titleLabel = UILabel()
            titleLabel?.font = UIFont.systemFont(ofSize: 17)
        }
        titles[state.rawValue] = text
        titleLabel?.text = text
        setColor()
        
        /// 计算字符串width
        let textWidth = (text as NSString).boundingRect(with: CGSize(width: CGFloat.infinity, height: bounds.height),
                                                        options: .usesLineFragmentOrigin,
                                                        attributes: [.font: UIFont.systemFont(ofSize: 17)],
                                                        context: nil).width
        titleLabel?.frame.size = CGSize(width: textWidth, height: bounds.height)
        
        if titleLabel?.superview == nil {
            addSubview(titleLabel!)
        } else {
            layoutIfNeeded()
        }
    }
    
    /// 设置图片
    func setImage(_ image: UIImage?, for state: State) {
        guard let image = image else {
            imageView?.frame = CGRect.zero
            layoutIfNeeded()
            return
        }
        
        if imageView == nil {
            imageView = UIImageView()
            imageView?.contentMode = .scaleAspectFit
        }
        images[state.rawValue] = image
        imageView?.image = image
        setColor()
        
        imageView?.frame.size.width = min(bounds.width, bounds.height) / 2
        imageView?.frame.size.height = imageView!.frame.width
        imageView?.frame.origin.y = (bounds.height - imageView!.frame.height) / 2
        
        if imageView?.superview == nil {
            addSubview(imageView!)
        } else {
            layoutIfNeeded()
        }
    }
    
    /// 设置主题
    func setTheme(_ theme: ELButtonTheme, forState state: State) {
        themes[state.rawValue] = theme
        setColor(for: self.state)
    }
    
    /// 开始倒计时
    /// Note: 开启倒计时后，按钮将会自动禁用；计时结束后，按钮禁用解除
    ///
    /// - Parameters:
    ///   - seconds: 计时时间，单位秒
    ///   - formatter: 显示时间格式, 例如: "/@/秒", 其中"/@/"将会由倒计时间代替
    func startCountingDown(_ seconds: Int,
                           formatter: String = "/@/秒") {
        /// 保存原来的标题
        let originTitle = titleLabel?.text
        
        /// 禁用按钮
        isEnabled = false
        
        /// 配置定时器
        var count = seconds
        timerSource = DispatchSource.makeTimerSource()
        timerSource?.schedule(wallDeadline: .now(), repeating: .seconds(1), leeway: .seconds(0))
        timerSource?.setEventHandler {[unowned self] in
            if count <= 0 {
                self.timerSource?.cancel()
                self.timerSource = nil
                DispatchQueue.main.async {
                    self.isEnabled = true
                    self.setTitle(originTitle, for: .normal)
                }
            } else {
                let title = formatter.replacingOccurrences(of: "/@/", with: "\(count)")
                DispatchQueue.main.async {
                    self.setTitle(title, for: .normal)
                }
            }
            count -= 1
        }
        
        /// 启动定时器
        timerSource?.resume()
    }
}

//MARK: - Override
public extension ELButton {
    /// 布局子视图
    override func layoutSubviews() {
        let titleSize = titleLabel?.frame.size ?? CGSize.zero
        let imageSize = imageView?.frame.size ?? CGSize.zero
        
        let totalWidth = titleSize.width + imageSize.width + 8
        let x = totalWidth > bounds.width ? 0 : (bounds.width - totalWidth) / 2
        
        if layoutImageAtRight {
            titleLabel?.frame.origin.x = x
            imageView?.frame.origin.x = x + titleSize.width + 8
        } else {
            imageView?.frame.origin.x = x
            titleLabel?.frame.origin.x = x + imageSize.width + 8
        }
    }
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        if style != .custom && !isHighlighted && !isSelected {
            setColor(for: .highlighted)
        }
        return super.beginTracking(touch, with: event)
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        if style != .custom && !isHighlighted && !isSelected {
            setColor(for: .normal)
        }
        super.endTracking(touch, with: event)
    }
    
    override func cancelTracking(with event: UIEvent?) {
        if style != .custom && !isHighlighted {
            isHighlighted = false
        }
        super.cancelTracking(with: event)
    }
}
