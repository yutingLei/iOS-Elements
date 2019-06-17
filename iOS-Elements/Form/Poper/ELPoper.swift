//
//  ELPoper.swift
//  弹出视图
//
//  Created by Conjur on 2019/3/27.
//  Copyright © 2019 yutingLei. All rights reserved.
//

/*****************************************************************
 * ELPoper
 * 弹出视图抽象类
 *
 * 具体子类：
 *      图片弹出视图 ELImagePoper
 *      字符弹出视图 ELTextsPoper
 *      持有可选项弹出视图 ELSelectPoper
 ******************************************************************/

import UIKit

/// 弹出视图代理
@objc public protocol ELPoperProtocol: NSObjectProtocol {
    
    /// 视图将要显示
    @objc optional func onShowingPoper(_ poper: ELPoper)
    
    /// 视图已弹出
    @objc optional func onShownPoper(_ poper: ELPoper)
    
    /// 视图将要隐藏
    @objc optional func onHidingPoper(_ poper: ELPoper)
    
    /// 视图已隐藏
    @objc optional func onHiddenPoper(_ poper: ELPoper)
}

public extension ELPoper {
    
    /// 弹出位置(相对参考视图)
    enum Location {
        case left
        case right
        case top
        case auto
    }
    
    /// 执行弹出动画样式
    enum AnimationStyle {
        case fade
        case unfold
    }
    
    /// 内容主题
    enum Theme {
        case light
        case dark
    }
    
    /// 统一定义对齐方式
    enum Alignment {
        case left
        case center
        case right
    }
}

public class ELPoper: UIView {
    
    /// 代理
    public weak var delegate: ELPoperProtocol?
    
    /// 弹出位置(相对参考视图)
    public var location: Location = .auto
    
    /// 执行弹出/隐藏动画样式(默认：.fade)
    public var animationStyle: AnimationStyle = .fade
    
    /// 内容容器视图主题(默认：.light)
    public var theme: Theme = .light { didSet { setTheme() } }
    
    /// 是否全屏(默认：false)
    public var isFullScreen: Bool = false { didSet { createCloseButton() } }
    
    /// 是否占据屏幕宽度(默认：false)
    /// 当此属性为true时，containerViewLayoutMargin同样生效，所以真正的全屏需设置containerViewLayoutMargin = 0
    public var isFullWidth: Bool = false
    
    /// 容器视图是否为圆角(默认：true)
    public var isRounded: Bool = true
    
    /// 是否使用箭头指向参考视图(默认：true)
    public var isArrowed: Bool = true
    
    /// 当isContainedArrow = true时, 设置箭头对齐方式(默认: .left)
    public var arrowAlignment: Alignment = .left
    
    /// 当显示弹出内容时，是否形成鲜明对比(默认：true)
    public var isContrasted: Bool = true { didSet { setContrast() } }
    
    /// 设置箭头高度(默认：8)
    public var suggestionArrowsHeight: CGFloat = 8
    
    /// 容器视图固定大小, 当isFullScreen/isFullWidth = true时，设置此属性无效
    /// 如果设置的size中宽或高为0,表示根据内容自定义宽度或高度
    public var fixedSize: CGSize?
    
    /// 参考视图
    private(set) public weak var refrenceView: UIView!
    
    /// 设置内容视图与容器视图的边距(默认：8)
    public var padding: UIEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    
    /// 容器视图与屏幕边距(默认：8)
    /// 如果有"刘海"，表示距"刘海"的距离
    public var margin: UIEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    
    /// 内容容器视图(get only)
    private(set) var containerView: ELShadowView!
    
    /// 全屏时，关闭Poper的按钮
    private(set) public var closeButton: UIButton?
    
    /// 屏幕宽度/高度
    var screenWidth = UIScreen.main.bounds.width
    var screenHeight = UIScreen.main.bounds.height
    
    /// 状态栏高度
    var statusBarHeight = UIApplication.shared.statusBarFrame.height
    
    /// 是否更新视图
    var shouldUpdateContainerView = true
    
    ///MARK: - Init poper
    public init(refrenceView: UIView, withDelegate delegate: ELPoperProtocol?) {
        super.init(frame: UIScreen.main.bounds)
        self.refrenceView = refrenceView
        self.delegate = delegate
        createContentView()
        setContrast()
        setTheme()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//MARK: - Create contentView
extension ELPoper {
    /// Create contentView
    func createContentView() {
        containerView = ELShadowView(frame: CGRect.zero)
        addSubview(containerView)
    }
    
    /// Create Close button when fullscreen
    func createCloseButton() {
        if closeButton == nil {
            closeButton = UIButton(frame: CGRect(x: screenWidth - 45, y: statusBarHeight + 15, width: 25, height: 25))
            closeButton?.addTarget(self, action: #selector(onCloseButtonTouched), for: .touchUpInside)
            closeButton?.setImage(ELIcon.get(.circleCloseOutline), for: .normal)
            addSubview(closeButton!)
        }
        closeButton?.isHidden = !isFullScreen
    }
    
    /// Create a borderLayer for containerView
    func createContainerViewsBorderLayer() {
        guard isArrowed else {
            containerView.effectsView.layer.mask = nil
            containerView.cornerRadius = isRounded ? 5 : 0
            return
        }
        containerView.cornerRadius = 0
        if containerView.effectsView.layer.mask == nil {
            containerView.effectsView.layer.mask = CAShapeLayer()
        }
        
        let refRect = refrenceView.convert(refrenceView.bounds, to: UIApplication.shared.keyWindow)
        
        /// 内容视图特殊点
        let arrowHeight = suggestionArrowsHeight
        
        /// lt: leftTop     lb: leftBottom      lc: leftCenter
        /// rt: rightTop    rb: rightBottom     rc: rightCenter
        let lt = CGPoint.zero
        let lb = CGPoint(x: 0, y: containerView.bounds.maxY)
        let lc = CGPoint(x: 0, y: refRect.midY - containerView.frame.minY)
        
        let rt = CGPoint(x: containerView.bounds.maxX, y: 0)
        let rb = CGPoint(x: containerView.bounds.maxX, y: containerView.bounds.maxY)
        let rc = CGPoint(x: containerView.bounds.maxX, y: refRect.midY - containerView.frame.minY)
        
        let bezierPath = UIBezierPath()
        bezierPath.lineWidth = 1
        
        switch location {
        case .left:
            bezierPath.move(to: rc)
            bezierPath.addLine(to: rc.offset(dx: -arrowHeight, dy: -arrowHeight))
            bezierPath.addLine(to: rt.offset(dx: -arrowHeight, dy: 5))
            bezierPath.addQuadCurve(to: rt.offset(dx: -(arrowHeight + 5)), controlPoint: rt.offset(dx: -arrowHeight))
            bezierPath.addLine(to: lt.offset(dx: 5))
            bezierPath.addQuadCurve(to: lt.offset(dy: 5), controlPoint: lt)
            bezierPath.addLine(to: lb.offset(dy: -5))
            bezierPath.addQuadCurve(to: lb.offset(dx: 5), controlPoint: lb)
            bezierPath.addLine(to: rb.offset(dx: -(arrowHeight + 5)))
            bezierPath.addQuadCurve(to: rb.offset(dx: -arrowHeight, dy: -5), controlPoint: rb.offset(dx: -arrowHeight))
            bezierPath.addLine(to: rc.offset(dx: -arrowHeight, dy: arrowHeight))
        case .right:
            bezierPath.move(to: lc)
            bezierPath.addLine(to: lc.offset(dx: arrowHeight, dy: -arrowHeight))
            bezierPath.addLine(to: lt.offset(dx: arrowHeight, dy: 5))
            bezierPath.addQuadCurve(to: lt.offset(dx: arrowHeight + 5), controlPoint: lt.offset(dx: arrowHeight))
            bezierPath.addLine(to: rt.offset(dx: -5))
            bezierPath.addQuadCurve(to: rt.offset(dy: 5), controlPoint: rt)
            bezierPath.addLine(to: rb.offset(dy: -5))
            bezierPath.addQuadCurve(to: rb.offset(dx: -5), controlPoint: rb)
            bezierPath.addLine(to: lb.offset(dx: arrowHeight + 5))
            bezierPath.addQuadCurve(to: lb.offset(dx: arrowHeight, dy: -5), controlPoint: lb.offset(dx: arrowHeight))
            bezierPath.addLine(to: lc.offset(dx: arrowHeight, dy: arrowHeight))
        default:
            let x: CGFloat
            if containerView.frame.width < refRect.width {
                x = containerView.frame.width / 2
            } else {
                switch arrowAlignment {
                case .right:
                    x = refRect.maxX - containerView.frame.minX - min(containerView.frame.width / 2, 30)
                case .center:
                    x = refRect.minX - containerView.frame.minX + refRect.width / 2
                default:
                    x = refRect.minX - containerView.frame.minX + min(containerView.frame.width / 2, 30)
                }
            }
            if containerView.frame.minY < refRect.minY {
                bezierPath.move(to: CGPoint(x: x, y: containerView.bounds.maxY))
                bezierPath.addLine(to: CGPoint(x: x + arrowHeight, y: containerView.bounds.maxY - arrowHeight))
                bezierPath.addLine(to: rb.offset(dx: -5, dy: -arrowHeight))
                bezierPath.addQuadCurve(to: rb.offset(dy: -(arrowHeight + 5)), controlPoint: rb.offset(dy: -arrowHeight))
                bezierPath.addLine(to: rt.offset(dy: 5))
                bezierPath.addQuadCurve(to: rt.offset(dx: -5), controlPoint: rt)
                bezierPath.addLine(to: lt.offset(dx: 5))
                bezierPath.addQuadCurve(to: lt.offset(dy: 5), controlPoint: lt)
                bezierPath.addLine(to: lb.offset(dy: -(arrowHeight + 5)))
                bezierPath.addQuadCurve(to: lb.offset(dx: 5, dy: -arrowHeight), controlPoint: lb.offset(dy: -arrowHeight))
                bezierPath.addLine(to: CGPoint(x: x - arrowHeight, y: containerView.bounds.maxY - arrowHeight))
            } else {
                bezierPath.move(to: CGPoint(x: x, y: 0))
                bezierPath.addLine(to: CGPoint(x: x + arrowHeight, y: arrowHeight))
                bezierPath.addLine(to: rt.offset(dx: -5, dy: arrowHeight))
                bezierPath.addQuadCurve(to: rt.offset(dy: arrowHeight + 5), controlPoint: rt.offset(dy: arrowHeight))
                bezierPath.addLine(to: rb.offset(dy: -5))
                bezierPath.addQuadCurve(to: rb.offset(dx: -5), controlPoint: rb)
                bezierPath.addLine(to: lb.offset(dx: 5))
                bezierPath.addQuadCurve(to: lb.offset(dy: -5), controlPoint: lb)
                bezierPath.addLine(to: lt.offset(dy: arrowHeight + 5))
                bezierPath.addQuadCurve(to: lt.offset(dx: 5, dy: arrowHeight), controlPoint: lt.offset(dy: arrowHeight))
                bezierPath.addLine(to: CGPoint(x: x - arrowHeight, y: arrowHeight))
            }
        }
        bezierPath.close()
        (containerView.effectsView.layer.mask as? CAShapeLayer)?.path = bezierPath.cgPath
    }
    
    /// On touched close button
    @objc func onCloseButtonTouched() { hide() }
}

//MARK: - Settings
extension ELPoper {
    /// The theme's setting
    @objc func setTheme() {
        switch theme {
        case .light:
            containerView.effectsView.backgroundColor = .white
            closeButton?.titleLabel?.textColor = ELColor.rgb(54, 55, 56)
            closeButton?.imageView?.image = closeButton?.imageView?.image?.stroked(by: UIColor.black)
        default:
            containerView.effectsView.backgroundColor = ELColor.rgb(54, 55, 56)
            closeButton?.titleLabel?.textColor = ELColor.rgb(54, 55, 56)
            closeButton?.imageView?.image = closeButton?.imageView?.image?.stroked(by: UIColor.white)
        }
    }
    
    /// Set contrast
    func setContrast() {
        backgroundColor = isContrasted ? UIColor.black.withAlphaComponent(0.15) : .clear
    }
    
    /// 根据需弹出的内容大小，计算容器内容视图的大小
    func calculateContainerViewsSize(with contentSize: CGSize) {
        
        /// 若果是全屏
        if isFullScreen {
            containerView.frame.size = UIScreen.main.bounds.size
            return
        }
        
        /// 声明容器视图大小
        var containerViewsSize = CGSize.zero
        
        /// 如果设置了全屏宽度
        if isFullWidth {
            containerViewsSize.width = screenWidth
        }
        
        /// 如果固定不为空大小
        if let fixedSize = fixedSize {
            if fixedSize.width != 0 {
                containerViewsSize.width = fixedSize.width
            }
            if fixedSize.height != 0 {
                containerViewsSize.height = fixedSize.height
            }
        }
        
        /// 根据弹出位置，设置容器视图的大小
        if containerViewsSize.width == 0 {
            containerViewsSize.width = contentSize.width + padding.lar + (location == .auto ? 0 : suggestionArrowsHeight)
        }
        if containerViewsSize.height == 0 {
            containerViewsSize.height = contentSize.height + padding.tab + (location == .auto ? suggestionArrowsHeight : 0)
        }
        containerView.frame.size = containerViewsSize
    }
    
    /// 计算容器视图以及内容视图的具体位置
    func calculateContainerViewsRect() {
        
        /// 参考视图位置及大小
        let refRect = refrenceView.convert(refrenceView.bounds, to: UIApplication.shared.keyWindow)
        
        /// 如果是全屏或屏幕宽度
        if isFullScreen || isFullWidth {
            containerView.frame.origin = CGPoint.zero
            if isFullWidth {
                if refRect.midY >= screenHeight / 2 || location == .top {
                    containerView.frame.origin.y = refRect.minY - containerView.frame.height
                } else {
                    containerView.frame.origin.y = refRect.maxY
                }
            }
            return
        }
        
        /// 根据弹出位置，计算容器视图位置
        switch location {
        case .left:
            containerView.frame.origin.x = refRect.minX - containerView.frame.width
            containerView.frame.origin.y = refRect.midY - containerView.frame.height / 2
        case .right:
            containerView.frame.origin.x = refRect.maxX
            containerView.frame.origin.y = refRect.midY - containerView.frame.height / 2
        default:
            if containerView.frame.width < refRect.width {
                if arrowAlignment == .left {
                    containerView.frame.origin.x = refRect.minX == 0 ? padding.left : refRect.minX
                } else if arrowAlignment == .center {
                    containerView.frame.origin.x = refRect.midX - (containerView.frame.width / 2)
                } else {
                    containerView.frame.origin.x = refRect.maxX == screenWidth ? (refRect.maxX - padding.right) : (refRect.maxX - containerView.frame.width)
                }
            } else {
                containerView.frame.origin.x = refRect.midX - (containerView.frame.width / 2)
            }
            if refRect.midY >= screenHeight / 2 || location == .top {
                containerView.frame.origin.y = refRect.minY - containerView.frame.height
            } else {
                containerView.frame.origin.y = refRect.maxY
            }
        }
        sizeContainerViewToScreen()
    }
    
    /// 已知容器视图的位置及大小，适配屏幕宽度和高度
    func sizeContainerViewToScreen() {
        guard !isFullScreen else { return }
        if isFullWidth {
            if containerView.frame.origin.y < (statusBarHeight + margin.top) {
                containerView.frame.size.height = (statusBarHeight + margin.top) - containerView.frame.origin.y
                containerView.frame.origin.y = statusBarHeight + margin.top
            } else if containerView.frame.maxY > screenHeight {
                containerView.frame.size.height -= (containerView.frame.maxY - screenHeight + margin.bottom)
            }
            return
        }
        
        /// 参考视图位置及大小
        let refRect = refrenceView.convert(refrenceView.bounds, to: UIApplication.shared.keyWindow)
        
        /// 根据弹出位置，适配容器视图大小及位置
        switch location {
        case .left, .right:
            /// 宽度适配
            if location == .left {
                if containerView.frame.origin.x < margin.left {
                    containerView.frame.origin.x = margin.left
                    containerView.frame.size.width = refRect.minX - containerView.frame.minX
                }
            } else {
                if containerView.frame.maxX > screenWidth {
                    containerView.frame.size.width = screenWidth - margin.right - refRect.maxX
                }
            }
            /// 高度适配
            if containerView.frame.origin.y < (statusBarHeight + margin.top) {
                containerView.frame.size.height = (statusBarHeight + margin.top) - containerView.frame.origin.y
                containerView.frame.origin.y = statusBarHeight + margin.top
            }
            if containerView.frame.maxY > screenHeight {
                containerView.frame.size.height -= (containerView.frame.maxY - screenHeight + margin.bottom)
            }
        default:
            /// 高度适配
            if containerView.frame.origin.y < (statusBarHeight + margin.top) {
                containerView.frame.size.height -= ((statusBarHeight + margin.top) - containerView.frame.origin.y)
                containerView.frame.origin.y = statusBarHeight + margin.top
            } else if containerView.frame.maxY > screenHeight {
                containerView.frame.size.height -= (containerView.frame.maxY - (screenHeight - margin.bottom))
            }
            
            /// 宽度适配
            if containerView.frame.maxX > (screenWidth - margin.right) {
                containerView.frame.origin.x -= (containerView.frame.maxX - (screenWidth - margin.right))
            }
            if containerView.frame.minX < margin.left {
                containerView.frame.origin.x = margin.left
                containerView.frame.size.width = screenWidth - margin.lar
            }
        }
    }
}

//MARK: - Animations while showing and hiding
extension ELPoper {
    /// Animation for showing
    func showsAnimate(_ completed: ((Bool) -> Void)?) {
        if animationStyle == .fade {
            alpha = 0.1
            containerView.effectsView.frame = containerView.bounds
            UIView.animate(withDuration: 0.35, animations: {[unowned self] in
                self.alpha = 1.0
            }, completion: completed)
        } else {
            let refRect = refrenceView.convert(refrenceView.bounds, to: UIApplication.shared.keyWindow)
            var fromRect = containerView.bounds
            let toRect = containerView.bounds
            if location == .left {
                fromRect.origin.x = fromRect.maxX
                fromRect.size.width = 0
            } else if location == .right {
                fromRect.size.width = 0
            } else {
                if containerView.frame.midY <= refRect.midY {
                    fromRect.origin.y = fromRect.height
                }
                fromRect.size.height = 0
            }
            containerView.effectsView.frame = fromRect
            UIView.animate(withDuration: 0.35, animations: {[unowned self] in
                self.containerView.effectsView.frame = toRect
            }, completion: completed)
        }
    }
    
    /// Animation for hiding
    func hideAnimate(_ completed: ((Bool) -> Void)?) {
        if animationStyle == .fade {
            UIView.animate(withDuration: 0.35, animations: {[weak self] in
                self?.alpha = 0.1
            }, completion: completed)
        } else {
            let refRect = refrenceView.convert(refrenceView.bounds, to: UIApplication.shared.keyWindow)
            let fromRect = containerView.bounds
            var toRect = containerView.bounds
            if location == .left {
                toRect.origin.x = toRect.maxX
                toRect.size.width = 0
            } else if location == .right {
                toRect.size.width = 0
            } else {
                if containerView.frame.midY <= refRect.midY {
                    toRect.origin.y = fromRect.height
                }
                toRect.size.height = 0
            }
            containerView.effectsView.frame = fromRect
            UIView.animate(withDuration: 0.35, animations: {[weak self] in
                self?.containerView.effectsView.frame = toRect
            }, completion: completed)
        }
    }
}

//MARK: - Public functions
public extension ELPoper {
    /// 参考视图是输入框，且isEnabled = true，那么点击参考视图范围内，将不会隐藏Poper视图
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let refView = refrenceView as? UITextField, refView.isEnabled == false {
            let refRect = refrenceView.convert(refrenceView.bounds, to: UIApplication.shared.keyWindow)
            if let touch = touches.first {
                let point = touch.location(in: self)
                if refRect.contains(point) {
                    return
                }
            }
        }
        hide()
    }
    
    /// Show poper with given animation style
    @objc func show() {
        if shouldUpdateContainerView && isArrowed && !isFullScreen {
            shouldUpdateContainerView = false
            createContainerViewsBorderLayer()
        }
        
        if superview == nil {
            UIApplication.shared.keyWindow?.addSubview(self)
        }
        
        unowned let weakSelf = self
        showsAnimate {[unowned self] _ in
            self.delegate?.onShownPoper?(weakSelf)
        }
        
        delegate?.onShowingPoper?(weakSelf)
    }
    
    /// Hide poper with given animation style
    func hide() {
        if let keyWindow = UIApplication.shared.keyWindow {
            for view in keyWindow.subviews {
                if view is ELPoper {
                    unowned let weakSelf = self
                    delegate?.onHidingPoper?(weakSelf)
                    
                    hideAnimate {[weak self] _ in
                        view.removeFromSuperview()
                        if let strongSelf = self {
                            strongSelf.delegate?.onHiddenPoper?(strongSelf)
                        }
                    }
                }
            }
        }
    }
}

//MARK: - CGPoint Extensions
extension CGPoint {
    func offset(dx: CGFloat = 0, dy: CGFloat = 0) -> CGPoint {
        var newP = self
        newP.x += dx
        newP.y += dy
        return newP
    }
}

extension UIEdgeInsets {
    /// 左右距离和
    public var lar: CGFloat { get { return left + right } }
    /// 上下距离和
    public var tab: CGFloat { get { return top + bottom } }
}

class ELShadowView: UIView {
    /// The view that make shadow effectively
    var effectsView: UIView!
    
    /// Corner rounded
    var cornerRadius: CGFloat {
        get { return effectsView.layer.cornerRadius }
        set { effectsView.layer.cornerRadius = newValue }
    }
    
    /// Shadow radius
    var radius: CGFloat {
        get { return layer.shadowRadius }
        set { layer.shadowRadius = newValue }
    }
    
    /// Shadow opacity
    var opacity: Float {
        get { return layer.shadowOpacity }
        set { layer.shadowOpacity = newValue }
    }
    
    /// Shadow's color
    var color: CGColor? {
        get { return layer.shadowColor }
        set { layer.shadowColor = newValue }
    }
    
    /// Shadow's offset
    var offset: CGSize {
        get { return layer.shadowOffset }
        set { layer.shadowOffset = newValue }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .clear
        layer.shadowOpacity = 0.2
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowRadius = 3
        layer.shadowOffset = CGSize(width: 0, height: 0.5)
        
        createEffectsView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Create a view that make shadow effectively
    func createEffectsView() {
        effectsView = UIView(frame: bounds)
        effectsView.layer.masksToBounds = true
        effectsView.backgroundColor = .white
        addSubview(effectsView)
    }
}
