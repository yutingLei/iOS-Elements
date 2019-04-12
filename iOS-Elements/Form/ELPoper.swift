//
//  ELPoper.swift
//  弹出视图
//
//  Created by Conjur on 2019/3/27.
//  Copyright © 2019 yutingLei. All rights reserved.
//

import UIKit

/// 弹出视图代理
@objc public protocol ELPoperProtocol: NSObjectProtocol {
    
    /// 视图已显示
    @objc optional func onPoperShown()
    
    /// 已选择选项内容
    @objc optional func onPoperSelect(_ text: String)
    
    /// 已隐藏
    @objc optional func onPoperDismissed()
    
    //-------------------- 选项 ------------------------
    /// 选项样式
    @objc optional func onPoperSelectionStyle() -> UITableViewCell.CellStyle
    
    /// 获取标题值的key, 默认"value"字段
    @objc optional func onPoperSelectionTitleKey() -> String
    
    /// 获取子标题值的key, 默认"subvalue"字段
    @objc optional func onPoperSelectionSubtitleKey() -> String
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
    
    /// 展示内容的类型
    enum ContentType {
        case image(UIImage)
        case text(String)
        case texts([String])
        case keyvalue([[String: Any]])
        
        static func ==(lhs: ContentType, rhs: ContentType) -> Bool {
            /// Hasher for left-hand side
            var lHash = 0
            switch lhs {
            case .image(let image):
                lHash = image.hashValue
            case .text(let text):
                lHash = text.hashValue
            case .texts(let texts):
                lHash = texts.hashValue
            case .keyvalue(var textsInfo):
                var hasher = Hasher()
                hasher.combine(bytes: withUnsafeBytes(of: &textsInfo) { $0 })
                lHash = hasher.finalize()
            }
            
            /// Hasher for right-hand side
            var rHash = 0
            switch rhs {
            case .image(let image):
                rHash = image.hashValue
            case .text(let text):
                rHash = text.hashValue
            case .texts(let texts):
                rHash = texts.hashValue
            case .keyvalue(var textsInfo):
                var hasher = Hasher()
                hasher.combine(bytes: withUnsafeBytes(of: &textsInfo) { $0 })
                rHash = hasher.finalize()
            }
            
            return lHash == rHash
        }
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
    
    /// 弹出的内容
    public var contents: ContentType?
    
    /// 在没有内容时，是否显示加载图标
    public var showActivityIndicatorWhileNullContents = true
    
    /// 展示内容固定大小
    public var contentsFixedSize: CGSize?
    
    /// 内容视图
    fileprivate(set) public var contentView: UIView!
    
    //MARK: - Lazy vars
    /// 加载动画视图
    lazy var loadingView: UIActivityIndicatorView = {
        let loading = UIActivityIndicatorView(frame: CGRect.zero)
        return loading
    }()
    
    /// 当contents类型为.image时，用于图片展示的视图
    lazy var imageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect.zero)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    /// 当contents类型为.text时，用于纯文字展示的视图
    lazy var textView: UITextView = {
       let textView = UITextView(frame: CGRect.zero)
        textView.font = UIFont.systemFont(ofSize: 14)
        textView.isEditable = false
        return textView
    }()
    
    /// 当contents类型为.texts时，用于多行文字展示的表格视图
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: CGRect.zero)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()
    
    //MARK: - Init
    /// 初始化弹出视图
    public init(refrenceView: UIView, delegate: ELPoperProtocol?) {
        super.init(frame: UIScreen.main.bounds)
        backgroundColor = UIColor.black.withAlphaComponent(0.02)
        
        self.refrenceView = refrenceView
        self.delegate = delegate
        
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
    func show() {
        /// Add myself into keyWindow after calculated rects
        defer {
            createMaskLayer()
            if superview == nil {
                UIApplication.shared.keyWindow?.addSubview(self)
                startAnimation(forShow: true) {[unowned self] _ in
                    self.delegate?.onPoperShown?()
                }
            }
        }
        
        /// 内容为空, 且showActivityIndicatorWhileNullContents=false时，不显示任何内容
        if contents == nil && !showActivityIndicatorWhileNullContents {
            removeFromSuperview()
            return
        }
        
        let sizes = suggestionSizes(of: contents)
        let rects = suggestionRects(with: sizes)
        
        /// 内容为空, 但showActivityIndicatorWhileNullContents = true时，显示加载视图
        if contents == nil && showActivityIndicatorWhileNullContents {
            layoutLoading(with: rects)
            return
        }
        
        if let contents = contents {
            switch contents {
            case .image(let image):
                layoutImageView(with: rects, image: image)
            case .text(let text):
                layoutTextView(with: rects, text: text)
            case .texts(_):
                layoutTableView(with: rects)
            case .keyvalue(_):
                layoutTableView(with: rects)
            }
        }
    }
    
    /// 隐藏弹出视图
    /// 注意：多数时候无需手动调用(输入框情况除外)
    ///      当参考视图是一个输入框时，点击输入框区域将不会自动隐藏
    func dismiss() {
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

//MARK: - Loading Activity Indicator
extension ELPoper {
    /// Add loading indicator view
    func layoutLoading(with rects: (CGRect, CGRect)) {
        _ = contentView.subviews.map({ $0.isHidden = !($0 is UIActivityIndicatorView) })
        
        if loadingView.superview == nil {
            contentView.addSubview(loadingView)
        }
        
        loadingView.style = theme == .light ? .gray : .white
        loadingView.startAnimating()
        loadingView.frame = rects.0
        contentView.frame = rects.1
    }
}

//MARK: - The contents is UIImage
extension ELPoper {
    /// Layout image view
    func layoutImageView(with rects: (CGRect, CGRect), image: UIImage) {
        _ = contentView.subviews.map({ $0.isHidden = !($0 is UIImageView) })
        
        if imageView.superview == nil {
            contentView.addSubview(imageView)
        }
        
        contentView.frame = rects.1
        imageView.frame = rects.0
        imageView.image = image
        updateTheme(with: imageView)
    }
}

//MARK: - The contents is 'text'
extension ELPoper {
    /// Layout text view
    func layoutTextView(with rects: (CGRect, CGRect), text: String) {
        _ = contentView.subviews.map({ $0.isHidden = !($0 is UITextView) })
        
        if  textView.superview == nil {
            contentView.addSubview(textView)
        }
        
        contentView.frame = rects.1
        textView.frame = rects.0
        textView.text = text
        updateTheme(with: textView)
    }
}

//MARK: - The contents is 'texts' or 'keyvalue'
extension ELPoper {
    /// Suggestion size for texts
    func suggestionSize(of texts: [String]) -> CGSize {
        var size = CGSize(width: 0, height: texts.count * 35)
        for text in texts {
            let textWidth = text.widthWithLimitHeight(35)
            if textWidth > size.width {
                size.width = textWidth
            }
        }
        size.width += 36
        return size
    }
    
    /// Suggestion size for keyvalue
    func suggestionSize(of texts: [[String: Any]]) -> CGSize {
        let cellStyle = suggestionTableViewCellStyle()
        var size = CGSize(width: 0, height: texts.count * (cellStyle == .subtitle ? 50 : 35))
        let titleKey = delegate?.onPoperSelectionTitleKey?() ?? "value"
        let subtitleKey = delegate?.onPoperSelectionSubtitleKey?() ?? "subvalue"
        
        for text in texts {
            var currentWidth: CGFloat = 0
            if let value = text[titleKey] as? String {
                let textWidth = value.widthWithLimitHeight(50, fontSize: 16)
                currentWidth = textWidth
            }
            if let value = text[subtitleKey] as? String {
                switch cellStyle {
                case .subtitle:
                    let textWidth = value.widthWithLimitHeight(50, fontSize: 13)
                    if textWidth > currentWidth {
                        currentWidth = textWidth
                    }
                case .value1, .value2:
                    let textWidth = value.widthWithLimitHeight(35, fontSize: 13)
                    currentWidth += (textWidth + 20)
                default:
                    break
                }
            }
            if currentWidth > size.width {
                size.width = currentWidth
            }
        }
        size.width += 36
        return size
    }
    
    /// Layout table view
    func layoutTableView(with rects: (CGRect, CGRect)) {
        _ = contentView.subviews.map({ $0.isHidden = !($0 is UITableView) })
        
        if tableView.superview == nil {
            contentView.addSubview(tableView)
        }
        
        contentView.frame = rects.1
        tableView.frame = rects.0
        tableView.reloadData()
        updateTheme(with: tableView)
    }
}



//MARK: - Calculate subview's rect of contentView
extension ELPoper {
    /// 计算内容视图的大小及其子视图的大小
    func suggestionSizes(of contents: ContentType?) -> (CGSize, CGSize) {
        /// 左右上下边距(8), 箭头宽高(10)
        if let fixedSize = contentsFixedSize {
            switch area {
            case .left, .right:
                return (CGSize(width: fixedSize.width - 26, height: fixedSize.height - 16), fixedSize)
            default:
                return (CGSize(width: fixedSize.width - 16, height: fixedSize.height - 26), fixedSize)
            }
        }
        
        var subviewSize: CGSize
        var contentSize: CGSize = CGSize.zero
        if contents == nil {
            subviewSize = CGSize(width: 120, height: 120)
        } else {
            switch contents! {
            case .image(let image):
                subviewSize = image.size
            case .text(let text):
                subviewSize = text.sizeWithLimits(bounds.width / 2)
            case .texts(let texts):
                subviewSize = suggestionSize(of: texts)
            case .keyvalue(let textsInfo):
                subviewSize = suggestionSize(of: textsInfo)
            }
        }
        
        /// Margin Left&Right = 8
        /// Margin Top&Bottom = 8
        /// Arrow's width&height = 10
        switch area {
        case .left, .right:
            contentSize.width += (subviewSize.width + 26)
            contentSize.height += (subviewSize.height + 16)
        default:
            contentSize.width += (subviewSize.width + 16)
            contentSize.height += (subviewSize.height + 26)
        }
        
        return (subviewSize, contentSize)
    }
    
    /// 计算弹出视图的位置及大小
    func suggestionRects(with sizes: (CGSize, CGSize)) -> (CGRect, CGRect) {
        
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
        updateTheme(with: nil)
    }

    /// 更新内容视图主题
    func updateTheme(with subview: UIView?) {
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
            if let subview = subview {
                if let textView = subview as? UITextView {
                    textView.textColor = ELColor.withHex("333333")
                    textView.backgroundColor = .white
                }
                if let imageView = subview as? UIImageView {
                    imageView.backgroundColor = .white
                }
                if let tableView = subview as? UITableView {
                    tableView.backgroundColor = .white
                    tableView.separatorColor = ELColor.rgb(230, 230, 230)
                }
            } else {
                if borderLayer == nil {
                    borderLayer = CAShapeLayer()
                    borderLayer?.fillColor = nil
                    contentView.layer.addSublayer(borderLayer!)
                }
                borderLayer?.frame = contentView.bounds
                borderLayer?.path = (contentView.layer.mask as? CAShapeLayer)?.path
                borderLayer?.strokeColor = ELColor.rgb(200, 200, 200).cgColor
                contentView.backgroundColor = .white
            }
        case .dark:
            if let subview = subview {
                if let textView = subview as? UITextView {
                    textView.textColor = ELColor.withHex("898A8C")
                    textView.backgroundColor = ELColor.rgb(54, 55, 56)
                }
                if let imageView = subview as? UIImageView {
                    imageView.backgroundColor = ELColor.rgb(54, 55, 56)
                }
                if let tableView = subview as? UITableView {
                    tableView.backgroundColor = ELColor.rgb(54, 55, 56)
                    tableView.separatorColor = ELColor.rgb(120, 120, 120)
                    tableView.separatorInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
                }
            } else {
                borderLayer?.removeFromSuperlayer()
                contentView.backgroundColor = ELColor.rgb(54, 55, 56)
            }
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

//
extension ELPoper: UITableViewDataSource, UITableViewDelegate {
    /// 建议cell样式
    func suggestionTableViewCellStyle() -> UITableViewCell.CellStyle {
        if let style = delegate?.onPoperSelectionStyle?() {
            return style
        }
        if let contents = contents {
            switch contents {
            case .keyvalue(_):
                return .subtitle
            default:
                break
            }
        }
        return .default
    }
    
    /// 选项个数
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let contents = contents {
            switch contents {
            case .texts(let texts):
                return texts.count
            case .keyvalue(let textsInfo):
                return textsInfo.count
            default:
                return 0
            }
        }
        return 0
    }

    /// 选项视图
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "kOSSelectCell")
        if cell == nil {
            cell = UITableViewCell(style: suggestionTableViewCellStyle(), reuseIdentifier: "kOSSelectCell")
            cell?.textLabel?.font = UIFont.systemFont(ofSize: 16)
            cell?.detailTextLabel?.font = UIFont.systemFont(ofSize: 13)
            cell?.selectionStyle = .none
        }
        
        /// 通过contents赋值
        var isDisabled = false
        if let contents = contents {
            switch contents {
            case .texts(let texts):
                cell?.textLabel?.text = texts[indexPath.row]
            case .keyvalue(let textsInfo):
                let titleKey = delegate?.onPoperSelectionTitleKey?() ?? "value"
                let subtitleKey = delegate?.onPoperSelectionSubtitleKey?() ?? "subvalue"
                cell?.textLabel?.text = textsInfo[indexPath.row][titleKey] as? String
                cell?.detailTextLabel?.text = textsInfo[indexPath.row][subtitleKey] as? String
                /// 禁止？
                if let disabled = textsInfo[indexPath.row]["disabled"],
                    (disabled as? Bool) == true || (disabled as? String) == "true"
                {
                    isDisabled = true
                }
            default: break
            }
        }
        
        /// 根据Theme设置选项颜色
        if isDisabled {
            cell?.textLabel?.textColor = theme == .light ? ELColor.withHex("898A8C") : ELColor.withHex("333333")
            cell?.detailTextLabel?.textColor = theme == .light ? ELColor.withHex("A9AAAC") : ELColor.withHex("222222")
        } else {
            cell?.textLabel?.textColor = theme == .light ? ELColor.withHex("333333") : ELColor.withHex("898A8C")
            cell?.detailTextLabel?.textColor = theme == .light ? ELColor.withHex("666666") : ELColor.withHex("696A6C")
        }
        cell?.backgroundColor = theme == .light ? ELColor.white : ELColor.rgb(54, 55, 56)
        
        return cell!
    }
    
    /// 选项高度
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let style = suggestionTableViewCellStyle()
        if style == .subtitle {
            return 50
        }
        return 35
    }

    /// 点击选项触发
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let contents = contents {
            switch contents {
            case .texts(let texts):
                delegate?.onPoperSelect?(texts[indexPath.row])
            case .keyvalue(let textsInfo):
                if let disabled = textsInfo[indexPath.row]["disabled"],
                    (disabled as? Bool) == true || (disabled as? String) == "true"
                {
                    return
                }
                if let value = textsInfo[indexPath.row]["value"] as? String {
                    delegate?.onPoperSelect?(value)
                }
                
            default:break
            }
        }
        dismiss()
    }
}

//MARK: - String Extensions
extension String {
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
