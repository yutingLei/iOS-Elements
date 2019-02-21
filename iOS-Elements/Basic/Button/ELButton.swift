//
//  ELButton.swift
//  iOS-Elements
//
//  Created by conjur on 2019/2/20.
//  自定义按钮
//

import UIKit

public class ELButton: UIView {

    /// 定义按钮类型
    public enum Style {
        case normal
        case text
        case primary
        case success
        case info
        case warning
        case danger
        case customer(ELButtonTheme)
    }

    //MARK: - Setter
    /// 当前按钮风格
    var _currentTheme: ELButtonTheme!

    /// 设置按钮风格
    var _style: Style = .normal

    /// 按钮风格，默认'.text'
    public var style: Style {
        get { return _style }
        set {
            _style = newValue
            switch newValue {
            case .text:
                _currentTheme = textTheme
            case .primary:
                _currentTheme = primaryTheme
            case .success:
                _currentTheme = successTheme
            case .info:
                _currentTheme = infoTheme
            case .warning:
                _currentTheme = warningTheme
            case .danger:
                _currentTheme = dangerTheme
            case .customer(let theme):
                _currentTheme = theme
            default:
                _currentTheme = normalTheme
            }
            updateTheme()
        }
    }

    /// 是否为朴素按钮，默认为nil
    public var isPlain: Bool? {
        didSet {
            if let _isPlain = isPlain {
                if _isPlain {
                    _currentTheme.convertToPlain(with: _style)
                } else {
                    _currentTheme.revertFromPlain(with: _style)
                }
                updateTheme()
            }
        }
    }

    /// 按钮左右是否是圆弧形，默认false
    public var isRound: Bool = false {
        willSet {
            layer.cornerRadius = newValue ? frame.height / 2 : 3
            layer.masksToBounds = true
        }
    }

    /// 当该属性为true时，ELButton的宽高将变为一致(取两者之间最小)变为圆形
    /// 请注意：此设置不可逆，默认false
    public var isCircle: Bool = false {
        willSet {
            /// 设置大小并改变圆角
            let minWidthHeight = min(frame.width, frame.height)
            frame.size = CGSize(width: minWidthHeight, height: minWidthHeight)
            layer.cornerRadius = minWidthHeight / 2
            layer.masksToBounds = true

            /// 在有icon和标题时，隐藏标题
            if newValue {
                _titleLabel?.isHidden = true
                _iconImageView?.center = CGPoint(x: bounds.midX, y: bounds.midY)
            }
        }
    }

    /// 按钮能否点击
    /// 默认true
    public var isEnabled: Bool = true {
        willSet (newValue) {
            isUserInteractionEnabled = newValue
            if newValue {
                layer.mask = nil
            } else {
                layer.mask = {
                    let maskLayer = CAShapeLayer()
                    maskLayer.frame = bounds
                    maskLayer.backgroundColor = UIColor.white.withAlphaComponent(0.5).cgColor
                    return maskLayer
                }()
            }
        }
    }

    /// 加载视图，但isLoading为true时默认创建
    lazy var _activityView: UIActivityIndicatorView = {
        let activityView = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 15, height: 15))
        activityView.center = CGPoint(x: bounds.midX, y: bounds.midY)
        addSubview(activityView)
        return activityView
    }()
    /// 是否显示加载动画，此属性会影响isEnabled属性，并且隐藏标题和icon
    /// 默认false
    public var isLoading: Bool = false {
        willSet (newValue) {
            /// 若为文字按钮
            switch style {
            case .text:
                print("文字按钮不支持加载...")
                return
            case .normal:
                _activityView.style = .gray
            default:
                _activityView.style = .white
            }

            /// 使能/失能按钮
            isEnabled = !newValue

            /// 隐藏/显示 标题和icon
            _titleLabel?.isHidden = newValue
            _iconImageView?.isHidden = newValue

            if newValue {
                _activityView.startAnimating()
                addSubview(_activityView)
            } else {
                _activityView.stopAnimating()
                _activityView.removeFromSuperview()
            }
        }
    }

    /// 按钮点击触发回调
    public var onClick: ((ELButton) -> Void)?

    //MARK: - Title & Icon
    var _titleLabel: UILabel?
    public var titleLable: UILabel? { get { return _titleLabel } }

    var _iconImageView: UIImageView?
    public var iconImage: UIImage? { get { return _iconImageView?.image } }

    /// 设置按钮标题
    ///
    /// - Parameters:
    ///   - text: 按钮标题
    ///   - font: 按钮标题字体
    ///   - atLeft: 按钮相对于icon位置,默认在icon右边
    public func setTitle(_ text: String, withFont font: UIFont = UIFont.systemFont(ofSize: 15), atLeft: Bool = false) {
        if _titleLabel == nil {
            _titleLabel = UILabel()
            _titleLabel?.font = font
            addSubview(_titleLabel!)
        }
        let labelRect = (text as NSString).boundingRect(with: frame.size,
                                                        options: .usesLineFragmentOrigin,
                                                        attributes: [NSAttributedString.Key.font: font],
                                                        context: nil)
        _titleLabel?.frame = labelRect
        _titleLabel?.center = CGPoint(x: bounds.midX, y: bounds.midY)
        _titleLabel?.text = text
        layoutTitleAndIcon(atLeft)
        updateTheme()
    }

    /// 设置按钮的icon
    ///
    /// - Parameters:
    ///   - image: 图片对象
    ///   - atLeft: 此图片相对标题位置
    public func setIcon(_ image: UIImage, withSize: CGFloat = 20, atLeft: Bool = true) {
        switch style {
        case .text:
            print("文字按钮不支持icon...")
            return
        default:
            if _iconImageView == nil {
                _iconImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
                _iconImageView?.contentMode = .scaleAspectFill
                addSubview(_iconImageView!)
            }
            _iconImageView?.center = CGPoint.init(x: bounds.midX, y: bounds.midY)
            _iconImageView?.image = image
            layoutTitleAndIcon(atLeft)
            updateTheme()
        }
    }

    //MARK: - Init

    /// 初始化
    ///
    /// - Parameter frame: 视图的frame值
    public override init(frame: CGRect) {
        super.init(frame: frame)
        style = _style
    }

    /// 快捷初始化方法
    ///
    /// - Parameters:
    ///   - frame: 视图的frame值
    ///   - onClick: 按钮点击回调
    public convenience init(frame: CGRect, onClick: ((ELButton) -> Void)? = nil) {
        self.init(frame: frame)
        self.onClick = onClick
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 根据风格更新按钮主题
    func updateTheme() {

        /// 先设置标题颜色
        _titleLabel?.textColor = _currentTheme.titleColor

        /// 根据风格调整边框
        switch style {
        case .text:
            layer.borderWidth = 0
            return
        case .normal:
            layer.borderWidth = 1
        default:
            layer.borderWidth = (isPlain == true) ? 1 : 0
        }

        /// 其它风格的边框
        layer.borderColor = _currentTheme.borderColor?.cgColor

        /// icon渲染
        if let icon = _iconImageView, let iconColor = _currentTheme.iconColor {
            icon.image = icon.image?.render(with: iconColor)
        }

        /// 背景色
        backgroundColor = _currentTheme.backgroundColor
    }

    /// 排列标题和icon
    func layoutTitleAndIcon(_ iconAtLeft: Bool) {
        if let tFrame = _titleLabel?.frame, let iFrame = _iconImageView?.frame {
            let midX = bounds.midX
            let totalWidth = tFrame.width + iFrame.width
            var startX = midX - totalWidth / 2
            if startX < 0 {
                startX = 0
                _titleLabel?.frame.size.width = tFrame.width + startX
            }
            if iconAtLeft {
                _titleLabel?.frame.origin.x = startX + iFrame.width
                _iconImageView?.frame.origin.x = startX
            } else {
                _titleLabel?.frame.origin.x = startX
                _iconImageView?.frame.origin.x = startX + tFrame.width
            }
        }
    }

    //MARK: - Touch Delegate
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        _titleLabel?.textColor = _currentTheme.highlightTitleColor

        /// 若为文字按钮，此处可以直接返回
        switch style {
        case .text:
            return
        default:
            break
        }

        /// 是否渲染icon
        if let icon = _iconImageView, let iconColor = _currentTheme.highlightIconColor {
            icon.image = icon.image?.render(with: iconColor, toSize: nil)
        }

        /// 显示高亮的背景色
        backgroundColor = _currentTheme.highlightBackgroundColor

        /// 显示高亮的边框
        if layer.borderWidth != 0 {
            layer.borderColor = _currentTheme.highlightBorderColor?.cgColor
        }
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let location = touch.location(in: superview)
            if frame.contains(location) {
                unowned let weakSelf = self
                onClick?(weakSelf)
            }
        }
        updateTheme()
    }
}
