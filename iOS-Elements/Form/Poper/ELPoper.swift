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
    
    /// 视图已显示
    @objc optional func onPoperShown()
    
    /// 已隐藏
    @objc optional func onPoperDismissed()
}

public extension ELPoper {
    /// 相对参考视图弹出的位置
    enum Area {
        case left
        case right
        case auto
    }
    
    /// 弹出时动画样式
    enum AnimationStyle {
        case fade
        case unfold
    }
    
    /// 弹出视图主题
    enum Theme {
        case light
        case dark
//        case custom(UIColor, UIColor, UIColor)
    }
}

//MARK: - PoperView
public class ELPoper: UIView {
    
    /// 代理
    private(set) public weak var delegate: ELPoperProtocol?
    
    /// 相对于参考视图弹出位置(.auto)
    public var area: Area = .auto
    
    /// 弹出动画样式(.fade)
    public var animationStyle: AnimationStyle = .fade
    
    /// 内容主题(.light), 在下一次调用'show'方法后更新
    public var theme: Theme = .light
    
    /// 参考视图
    private(set) public weak var refrenceView: UIView!
    
    /// 是否全屏展示(false), 注意：此属性比contentsFixedSize拥有更高的优先级
    public var isFullScreen: Bool!
    
    /// 全屏时，关闭按钮
    lazy var closeBtn: UIButton = {
        let statusFrame = UIApplication.shared.statusBarFrame
        let button = UIButton(frame: CGRect(x: bounds.width - 45, y: statusFrame.height + 25, width: 25, height: 25))
        button.addTarget(self, action: #selector(dismiss), for: .touchUpInside)
        button.setImage(ELIcon.get(.close), for: .normal)
        return button
    }()
    
    /// 展示内容固定大小
    public var contentsFixedSize: CGSize?
    
    /// 内容视图
    fileprivate(set) public var contentView: UIView!
    
    //MARK: - Init
    /// 初始化弹出视图
    public init(refrenceView: UIView, delegate: ELPoperProtocol?) {
        super.init(frame: UIScreen.main.bounds)
        backgroundColor = UIColor.black.withAlphaComponent(0.02)
        
        self.refrenceView = refrenceView
        self.delegate = delegate
        isFullScreen = false
        
        contentView = UIView()
        contentView.layer.masksToBounds = true
        addSubview(contentView)
    }
    
    /// 点击空白的地方，取消显示
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if refrenceView.isKind(of: UITextField.self) {
            let refRect = refrenceView.convert(refrenceView.bounds, to: UIApplication.shared.keyWindow)
            if let touch = touches.first {
                let point = touch.location(in: self)
                if refRect.contains(point) {
                    return
                }
            }
        }
        dismiss()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

////MARK: - Pop & Dismiss
public extension ELPoper {
    
    /// 显示弹出视图
    /// 未dismiss之前再次调用相当于更新视图，可能会改变大小
    @objc func show() {

        if !isFullScreen {
            if let sublayers = contentView.layer.sublayers {
                _ = sublayers.map({ ($0 is CAShapeLayer) ? $0.removeFromSuperlayer() : nil })
            }
            contentView.layer.mask = nil
            createMaskLayer()
        }
        
        if superview == nil {
            UIApplication.shared.keyWindow?.addSubview(self)
            startAnimation(forShow: true) {[unowned self] _ in
                self.delegate?.onPoperShown?()
            }
        }
    }
    
    /// 隐藏弹出视图
    /// 注意：多数时候无需手动调用(输入框情况除外)
    ///      当参考视图是一个输入框时，点击输入框区域将不会自动隐藏
    @objc func dismiss() {
        if let keyWindow = UIApplication.shared.keyWindow {
            for subview in keyWindow.subviews {
                if subview is ELPoper {
                    startAnimation(forShow: false) {[unowned self] _ in
                        self.delegate?.onPoperDismissed?()
                        subview.removeFromSuperview()
                    }
                }
            }
        }
    }
}

//MARK: - Calculate subview's rect of contentView
extension ELPoper {
    /// 根据内容计算内容视图的大小
    func suggestionContentSize(of size: CGSize) -> (CGSize, CGSize) {
        if isFullScreen {
            return (bounds.size, bounds.size)
        }
        
        /// 左右上下边距(8), 箭头宽高(10)
        if let fixedSize = contentsFixedSize {
            switch area {
            case .left, .right:
                return (CGSize(width: fixedSize.width - 26, height: fixedSize.height - 16), fixedSize)
            default:
                return (CGSize(width: fixedSize.width - 16, height: fixedSize.height - 26), fixedSize)
            }
        }
        
        var contentSize = CGSize.zero
        /// Margin Left&Right = 8
        /// Margin Top&Bottom = 8
        /// Arrow's width&height = 10
        switch area {
        case .left, .right:
            contentSize.width += (size.width + 26)
            contentSize.height += (size.height + 16)
        default:
            contentSize.width += (size.width + 16)
            contentSize.height += (size.height + 26)
        }
        
        return (size, contentSize)
    }
    
    /// 计算弹出视图的位置及大小
    func suggestionRects(with sizes: (CGSize, CGSize)) -> (CGRect, CGRect) {
        
        if isFullScreen {
            return (CGRect(origin: CGPoint.zero, size: sizes.0), CGRect(origin: CGPoint.zero, size: sizes.1))
        }
        
        let refRect = refrenceView.convert(refrenceView.bounds, to: UIApplication.shared.keyWindow)
        
        /// 屏幕宽高及状态栏高度
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let statusBarHeight = UIApplication.shared.statusBarFrame.height
        
        let subviewSize = sizes.0
        let contentSize = sizes.1
        
        /// 根据位置计算弹出的选择框视图位置
        var subviewRect = CGRect(origin: CGPoint.zero, size: subviewSize)
        var contentRect = CGRect(origin: CGPoint.zero, size: contentSize)
        switch area {
        case .left:
            subviewRect.origin.x = 8
            subviewRect.origin.y = 8
            contentRect.origin.x = refRect.minX - contentSize.width
            contentRect.origin.y = refRect.midY - contentSize.height / 2
            if contentRect.minX < 10, contentsFixedSize == nil {
                contentRect.origin.x = 10
                contentRect.size.width = refRect.minX - 10
            }
        case .right:
            subviewRect.origin.x = 18
            subviewRect.origin.y = 8
            contentRect.origin.x = refRect.maxX
            contentRect.origin.y = refRect.midY - contentSize.height / 2
            if contentRect.maxX > screenWidth - 10, contentsFixedSize == nil {
                contentRect.size.width = screenWidth - 10 - refRect.maxX
            }
        default:
            if (refRect.midY > screenHeight / 2) {
                subviewRect.origin.x = 8
                subviewRect.origin.y = 8
                contentRect.origin.x = refRect.minX
                contentRect.origin.y = refRect.minY - contentSize.height
                if contentRect.minY < statusBarHeight {
                    contentRect.origin.y = statusBarHeight + 10
                    contentRect.size.height = refRect.minY - contentRect.origin.y
                }
            } else {
                subviewRect.origin.x = 8
                subviewRect.origin.y = 18
                contentRect.origin.x = refRect.minX
                contentRect.origin.y = refRect.maxY
                if contentRect.maxY > screenHeight - 20 {
                    contentRect.size.height = screenHeight - 20 - refRect.maxY
                }
            }
        }
        
        /// 位置在左右时，适配高度
        if area == .left || area == .right {
            if contentRect.minY < statusBarHeight + 10 {
                contentRect.origin.y = statusBarHeight + 10
                if contentRect.maxY > screenHeight - 20 {
                    contentRect.size.height = screenHeight - contentRect.origin.y - 20
                }
            }
            
            if contentRect.maxY > screenHeight - 20 {
                contentRect.origin.y -= (contentRect.maxY - screenHeight + 20)
                if contentRect.minY > statusBarHeight + 10 {
                    contentRect.origin.y = statusBarHeight + 10
                    contentRect.size.height = (screenHeight - statusBarHeight - 30)
                }
            }
            subviewRect.size.width = contentRect.width - 26
            subviewRect.size.height = contentRect.height - 16
        }
            
        /// 位置在上下时，适配宽度
        else {
            if contentRect.maxX > screenWidth - 10 {
                contentRect.origin.x -= (contentRect.maxX - screenWidth + 10)
                if contentRect.minX < 10, contentsFixedSize == nil {
                    contentRect.origin.x = 10
                    contentRect.size.width = screenWidth - 20
                }
            }
            
            if contentRect.minX < 10, contentsFixedSize == nil {
                contentRect.origin.x = 10
                if contentRect.maxX > screenWidth - 10 {
                    contentRect.size.width = screenWidth - 20
                }
            }
            subviewRect.size.width = contentRect.width - 16
            subviewRect.size.height = contentRect.height - 26
        }
        return (subviewRect, contentRect)
    }

    /// 创建遮罩
    func createMaskLayer() {
        
        let refRect = refrenceView.convert(refrenceView.bounds, to: UIApplication.shared.keyWindow)

        /// 内容视图特殊点
        let leftTop = CGPoint(x: 0, y: 0)
        let rightTop = CGPoint(x: contentView.bounds.maxX, y: 0)
        let leftBottom = CGPoint(x: 0, y: contentView.bounds.maxY)
        let rightBottom = CGPoint(x: contentView.bounds.maxX, y: contentView.bounds.maxY)
        let leftCenter = CGPoint(x: 0, y: contentView.bounds.midY)
        let rightCenter = CGPoint(x: contentView.bounds.maxX, y: contentView.bounds.midY)

        let path = UIBezierPath()
        path.lineWidth = 1.0
        switch area {
        case .left:
            path.move(to: rightCenter)
            path.addLine(to: rightCenter.offset(dx: -10, dy: -10))
            path.addLine(to: rightTop.offset(dx: -10, dy: 5))
            path.addQuadCurve(to: rightTop.offset(dx: -15), controlPoint: rightTop.offset(dx: -10))
            path.addLine(to: leftTop.offset(dx: 5))
            path.addQuadCurve(to: leftTop.offset(dy: 5), controlPoint: leftTop)
            path.addLine(to: leftBottom.offset(dy: -5))
            path.addQuadCurve(to: leftBottom.offset(dx: 5), controlPoint: leftBottom)
            path.addLine(to: rightBottom.offset(dx: -15))
            path.addQuadCurve(to: rightBottom.offset(dx: -10, dy: -5), controlPoint: rightBottom.offset(dx: -10))
            path.addLine(to: rightCenter.offset(dx: -10, dy: 10))
        case .right:
            path.move(to: leftCenter)
            path.addLine(to: leftCenter.offset(dx: 10, dy: -10))
            path.addLine(to: leftTop.offset(dx: 10, dy: 5))
            path.addQuadCurve(to: leftTop.offset(dx: 15), controlPoint: leftTop.offset(dx: 10))
            path.addLine(to: rightTop.offset(dx: -5))
            path.addQuadCurve(to: rightTop.offset(dy: 5), controlPoint: rightTop)
            path.addLine(to: rightBottom.offset(dy: -5))
            path.addQuadCurve(to: rightBottom.offset(dx: -5), controlPoint: rightBottom)
            path.addLine(to: leftBottom.offset(dx: 15))
            path.addQuadCurve(to: leftBottom.offset(dx: 10, dy: -5), controlPoint: leftBottom.offset(dx: 10))
            path.addLine(to: leftCenter.offset(dx: 10, dy: 10))
        default:
            let startX = (refRect.minX - contentView.frame.minX) + min(contentView.bounds.width / 2, 50)
            if contentView.frame.minY < refRect.minY {
                path.move(to: CGPoint(x: startX, y: contentView.bounds.maxY))
                path.addLine(to: CGPoint(x: startX + 10, y: contentView.bounds.maxY - 10))
                path.addLine(to: rightBottom.offset(dx: -5, dy: -10))
                path.addQuadCurve(to: rightBottom.offset(dy: -15), controlPoint: rightBottom.offset(dy: -10))
                path.addLine(to: rightTop.offset(dy: 5))
                path.addQuadCurve(to: rightTop.offset(dx: -5), controlPoint: rightTop)
                path.addLine(to: leftTop.offset(dx: 5))
                path.addQuadCurve(to: leftTop.offset(dy: 5), controlPoint: leftTop)
                path.addLine(to: leftBottom.offset(dy: -15))
                path.addQuadCurve(to: leftBottom.offset(dx: 5, dy: -10), controlPoint: leftBottom.offset(dy: -10))
                path.addLine(to: CGPoint.init(x: startX - 10, y: contentView.bounds.maxY - 10))
            } else {
                path.move(to: CGPoint(x: startX, y: 0))
                path.addLine(to: CGPoint(x: startX + 10, y: 10))
                path.addLine(to: rightTop.offset(dx: -5, dy: 10))
                path.addQuadCurve(to: rightTop.offset(dy: 15), controlPoint: rightTop.offset(dy: 10))
                path.addLine(to: rightBottom.offset(dy: -5))
                path.addQuadCurve(to: rightBottom.offset(dx: -5), controlPoint: rightBottom)
                path.addLine(to: leftBottom.offset(dx: 5))
                path.addQuadCurve(to: leftBottom.offset(dy: -5), controlPoint: leftBottom)
                path.addLine(to: leftTop.offset(dy: 15))
                path.addQuadCurve(to: leftTop.offset(dx: 5, dy: 10), controlPoint: leftTop.offset(dy: 10))
                path.addLine(to: CGPoint(x: startX - 10, y: 10))
            }
        }
        path.close()
        contentView.layer.mask = {
            let maskLayer = CAShapeLayer()
            maskLayer.path = path.cgPath
            return maskLayer
        }()
        updateTheme()
    }

    /// 更新内容视图主题
    @objc func updateTheme() {
        /// border layer
        var borderLayer: CAShapeLayer?
        if let contentSublayers = contentView.layer.sublayers {
            for contentSublayer in contentSublayers {
                if let shapeLayer = contentSublayer as? CAShapeLayer {
                    borderLayer = shapeLayer
                }
            }
        }

        switch theme {
        case .light:
            if borderLayer == nil {
                borderLayer = CAShapeLayer()
                borderLayer?.fillColor = nil
                contentView.layer.addSublayer(borderLayer!)
            }
            borderLayer?.frame = contentView.bounds
            borderLayer?.path = (contentView.layer.mask as? CAShapeLayer)?.path
            borderLayer?.strokeColor = ELColor.rgb(200, 200, 200).cgColor
            if isFullScreen {
                closeBtn.imageView?.image = ELIcon.get(.close)
            }
            contentView.backgroundColor = .white
        case .dark:
            borderLayer?.removeFromSuperlayer()
            if isFullScreen {
                closeBtn.imageView?.image = ELIcon.get(.close)?.stroked(by: UIColor.white)
            }
            contentView.backgroundColor = ELColor.rgb(54, 55, 56)
        }
    }

    /// 动画执行
    func startAnimation(forShow isShow: Bool, onCompletion: ((Bool) -> Void)?) {
        switch animationStyle {
        case .fade:
            if isShow {
                alpha = 0.1
            }
            UIView.animate(withDuration: 0.35, animations: {[unowned self] in
                self.alpha = isShow ? 1.0 : 0.1
            }, completion: onCompletion)
        case .unfold:
            var sourceRect = contentView.frame
            var destRect = contentView.frame
            switch area {
            case .left:
                sourceRect = isShow ? sourceRect.offset(dx: sourceRect.width) : sourceRect
                destRect = isShow ? destRect : destRect.offset(dx: destRect.width)
            case .right:
                sourceRect = isShow ? sourceRect.subtract(dw: sourceRect.width) : sourceRect
                destRect = isShow ? destRect : destRect.subtract(dw: destRect.width)
            default:
                let refRect = refrenceView.convert(refrenceView.bounds, to: UIApplication.shared.keyWindow)
                if sourceRect.minY < refRect.minY {
                    sourceRect = isShow ? sourceRect.offset(dy: sourceRect.height) : sourceRect
                    destRect = isShow ? destRect : destRect.offset(dy: destRect.height)
                } else {
                    sourceRect = isShow ? sourceRect.subtract(dh: sourceRect.height) : sourceRect
                    destRect = isShow ? destRect : destRect.subtract(dh: destRect.height)
                }
            }
            contentView.frame = sourceRect
            UIView.animate(withDuration: 0.35, animations: {[unowned self] in
                self.contentView.frame = destRect
                self.alpha = isShow ? 1.0 : 0.1
            }, completion: onCompletion)
        }
    }
}

//MARK: - String Extensions
internal extension String {
    /// Get text width with given limit height
    func widthWithLimitHeight(_ lh: CGFloat, fontSize: CGFloat = 15) -> CGFloat {
        return sizeWithLimits(lh: lh, fontSize: fontSize).width
    }
    
    /// Get text height with given limit width
    func heightWithLimitWidth(_ lw: CGFloat, fontSize: CGFloat = 15) -> CGFloat {
        return sizeWithLimits(lw, fontSize: fontSize).height
    }
    
    /// Get text size with given limits(width & height)
    func sizeWithLimits(_ lw: CGFloat = .infinity, lh: CGFloat = .infinity, fontSize: CGFloat = 15) -> CGSize {
        let limitSize = CGSize(width: lw, height: lh)
        let font = UIFont.systemFont(ofSize: fontSize)
        return (self as NSString).boundingRect(with: limitSize,
                                               options: .usesLineFragmentOrigin,
                                               attributes: [.font: font],
                                               context: nil).size
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

//MARK: - CGRect Extensions
extension CGRect {

    /// 偏移x,y
    ///
    /// - Parameters:
    ///   - dx: 偏移的x值
    ///   - dy: 偏移的y值
    ///   - sync: 是否同步减少宽度高度,默认true
    func offset(dx: CGFloat = 0, dy: CGFloat = 0, sync: Bool = true) -> CGRect {
        var newRect = self
        newRect.origin.x += dx
        newRect.origin.y += dy
        if sync {
            newRect.size.width -= dx
            newRect.size.height -= dy
        }
        return newRect
    }

    /// 减少Rect宽高
    ///
    /// - Parameters:
    ///   - dw: 减去的宽度
    ///   - dh: 减去的高度
    /// - Returns: 新的Rect
    func subtract(dw: CGFloat = 0, dh: CGFloat = 0) -> CGRect {
        var newRect = self
        newRect.size.width -= dw
        newRect.size.height -= dh
        return newRect
    }
}
