//
//  ELImagePoper.swift
//  图片Poper
//
//  Created by admin on 2019/4/15.
//  Copyright © 2019 Develop. All rights reserved.
//

/*****************************************************************
 * ELImagePoper
 * 视图层次结构
 * keyWindow
 *      - UIView
 *          - UIView(即contentView)
 *              - UIScrollView
 *                  - [UIImageView]
 *
 * 弹出视图之图片展示
 * [v] 1.支持远程图片展示
 * [v] 2.支持本地图片展示
 * [v] 3.支持全屏图片展示
 * [v] 4.支持多张图片展示
 * [v] 5.支持图片页数
 * [v] 6.支持站位图
 ******************************************************************/

import UIKit

@objc public protocol ELImagePoperProtocol: ELPoperProtocol {
    /// 远程图片大小
    @objc optional func remoteImageSize(at index: Int) -> CGSize
}

public class ELImagePoper: ELPoper {
    
    /// 显示图片页数指示器(false)
    public var showPageControl: Bool = false {
        didSet { setPageControl() }
    }
    
    /// 是否支持缩放(false)
    public var isZoomedWhenFullScreened = false {
        willSet {
            scrollView.bouncesZoom = newValue
        }
    }
    
    /// 缩放级别
    public var zoomScale: CGFloat? {
        willSet {
            scrollView.zoomScale = newValue ?? 1
        }
    }
    
    /// 图片占位图
    /// 若为nil，且展示远程图片时，自动创建加载指示器
    public var placeholderImage: UIImage?
    
    /// 本地图片集合
    public var images: [UIImage]? {
        willSet { shouldUpdateContentView = newValue.hashValue != images.hashValue }
    }
    
    /// 远程图片集合, 传入地址即可
    /// 'isFullScreen = true'时，无需实现'ELImagePoperProtocol'中的代理方法'remoteImageSize(at:)'
    /// 'isFullScreen = false'时，需手动实现'ELImagePoperProtocol'中的代理方法'remoteImageSize(at:)'
    public var remotePaths: [String]? {
        willSet { shouldUpdateContentView = newValue?.hashValue != remotePaths?.hashValue }
    }
    lazy var remoteQueue: DispatchQueue = { return DispatchQueue(label: "com.remote.image.poper") }()
    
    /// 是否更新视图
    var shouldUpdateContentView = true {
        willSet {
            if newValue {
                shouldUpdateContainerView = newValue
            }
        }
    }
    
    /// 滚动视图，视图所有图片视图的容器
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.isPagingEnabled = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        containerView.effectsView.addSubview(scrollView)
        return scrollView
    }()
    
    /// 页数指示器
    private lazy var pageControl: UILabel = {
        let pageControl = UILabel()
        pageControl.textAlignment = .center
        pageControl.font = UIFont.systemFont(ofSize: 15)
        containerView.effectsView.addSubview(pageControl)
        return pageControl
    }()
    
    public init(refrenceView: UIView, withDelegate delegate: ELImagePoperProtocol?) {
        super.init(refrenceView: refrenceView, withDelegate: delegate)
        showPageControl = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public extension ELImagePoper {
    /// 展示视图
    override func show() {
        /// 显示
        defer { super.show() }
        
        /// 需要更新
        guard shouldUpdateContentView else { return }
        shouldUpdateContentView = false
        
        /// 计算步骤:
        ///     1.计算内容所需大小
        ///     2.根据内容所需大小计算容器视图大小
        ///     3.计算容器视图大小及位置，并且过程中会适配屏幕
        ///     4.此时根据容器视图大小计算内容视图大小及位置
        calculateContainerViewsSize(with: calculateContentViewsSize())
        calculateContainerViewsRect()
        calculateContentViewsRect()
        
        /// 创建图片
        createImageViews()
        
        /// 设置主题
        setTheme()
    }
}

//MARK: - Settings
extension ELImagePoper {
    
    /// 设置主题颜色
    override func setTheme() {
        super.setTheme()
        if theme == .light {
            scrollView.backgroundColor = UIColor.white
            if showPageControl {
                pageControl.isHidden = false
                pageControl.textColor = UIColor.black
            }
        } else {
            scrollView.backgroundColor = UIColor.black
            if showPageControl {
                pageControl.isHidden = false
                pageControl.textColor = .white
            }
        }
    }
    
    /// 设置页面指示器
    func setPageControl() {
        pageControl.isHidden = !showPageControl
        if showPageControl {
            if pageControl.superview == nil {
                pageControl.frame = CGRect(x: 0, y: scrollView.bounds.height - 45, width: scrollView.bounds.width, height: 20)
            }
        }
    }
    
    /// 计算内容所需大小
    func calculateContentViewsSize() -> CGSize {
        if isFullScreen {
            return CGSize.zero
        }
        
        var contentSize = CGSize.zero
        
        /// 计算内容视图大小
        if let images = images {
            for image in images {
                if image.size > contentSize {
                    contentSize = image.size
                }
            }
        } else if let paths = remotePaths {
            if let delegate = delegate as? ELImagePoperProtocol, delegate.responds(to: #selector(delegate.remoteImageSize(at:))) {
                for i in 0..<paths.count {
                    if let size = delegate.remoteImageSize?(at: i), size > contentSize {
                        contentSize = size
                    }
                }
            } else {
                assertionFailure("展示远程图片且'isFullScreen = false'，必须实现'remoteImageSize(at:)'方法")
            }
        }
        return contentSize
    }
    
    /// 计算内容真实大小及位置
    func calculateContentViewsRect() {
        scrollView.frame = containerView.bounds
        
        /// 如果是全屏
        if isFullScreen {
            scrollView.frame.origin.x = padding.top
            scrollView.frame.origin.y = statusBarHeight + 40
            scrollView.frame.size.width -= padding.tab
            scrollView.frame.size.height -= (statusBarHeight + 40 + padding.top)
            return
        }
        
        /// 根据位置计算
        switch location {
        case .left, .right:
            if location == .left {
                scrollView.frame.origin.x = padding.left
            } else {
                scrollView.frame.origin.x = padding.left + (isArrowed ? suggestionArrowsHeight : 0)
            }
            scrollView.frame.origin.y = padding.top
            scrollView.frame.size.width -= (padding.lar + (isArrowed ? suggestionArrowsHeight : 0))
            scrollView.frame.size.height -= padding.tab
        default:
            if containerView.frame.minY > screenWidth / 2 {
                scrollView.frame.origin.y = padding.top + (isArrowed ? suggestionArrowsHeight : 0)
            } else {
                scrollView.frame.origin.y = padding.top
            }
            scrollView.frame.origin.x = padding.left
            scrollView.frame.size.width -= padding.lar
            scrollView.frame.size.height -= (padding.tab + (isArrowed ? suggestionArrowsHeight : 0))
        }
    }
    
    /// 创建图片视图
    func createImageViews() {
        /// 移除旧图片视图
        _ = scrollView.subviews.map({ ($0 is UIImageView) ? $0.removeFromSuperview() : nil })
        
        /// 创建新图片视图
        var x: CGFloat = 0
        let w = scrollView.bounds.width
        let h = scrollView.bounds.height
        if let images = images {
            for image in images {
                let imageView = UIImageView(frame: CGRect(x: x, y: 0, width: w, height: h))
                imageView.contentMode = .scaleAspectFit
                imageView.image = image
                scrollView.addSubview(imageView)
                x += w
            }
            scrollView.contentSize = CGSize(width: CGFloat(images.count) * w, height: 0)
            if showPageControl {
                pageControl.text = "\(Int(scrollView.contentOffset.x / scrollView.frame.width))/\(images.count)"
            }
        }
        else if let remotePaths = remotePaths {
            for path in remotePaths {
                let imageView = UIImageView(frame: CGRect(x: x, y: 0, width: w, height: h))
                imageView.contentMode = .scaleAspectFit
                scrollView.addSubview(imageView)
                
                if let placeholderImage = placeholderImage {
                    imageView.image = placeholderImage
                } else {
                    let activityIndicator = UIActivityIndicatorView.init(frame: imageView.bounds)
                    activityIndicator.style = theme == .light ? .gray : .white
                    activityIndicator.startAnimating()
                    imageView.addSubview(activityIndicator)
                }
                
                x += w
                remoteQueue.async {[unowned imageView] in
                    if let url = URL(string: path), let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                        DispatchQueue.main.async {[unowned imageView] in
                            _ = imageView.subviews.map({ ($0 is UIActivityIndicatorView) ? $0.removeFromSuperview() : nil })
                            imageView.image = image
                        }
                    }
                }
            }
            scrollView.contentSize = CGSize(width: CGFloat(remotePaths.count) * w, height: 0)
            if showPageControl {
                pageControl.text = "\(Int(scrollView.contentOffset.x / scrollView.frame.width))/\(remotePaths.count)"
            }
        }
    }
}

extension ELImagePoper: UIScrollViewDelegate {
    /// 滑动图片结束后触发
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if showPageControl {
            if let images = images {
                pageControl.text = "\(Int(scrollView.contentOffset.x / scrollView.frame.width) + 1)/\(images.count)"
            }
            if let paths = remotePaths {
                pageControl.text = "\(Int(scrollView.contentOffset.x / scrollView.frame.width) + 1)/\(paths.count)"
            }
        }
    }
    
    /// 缩放图片
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        guard isFullScreen else { return nil }
        let index = Int(scrollView.contentOffset.x / bounds.width)
        if index >= 0 && index < scrollView.subviews.count {
            return scrollView.subviews[index]
        }
        return nil
    }
}

extension CGSize {
    
    /// 对比两个CGSize的大小
    static func >(lhs: CGSize, rhs: CGSize) -> Bool {
        return (lhs.width > rhs.width) && (lhs.height > rhs.height)
    }
    
    /// 两个CGSize是否相等
    static func ==(lhs: CGSize, rhs: CGSize) -> Bool {
        return (lhs.width == rhs.width) && (lhs.height == rhs.height)
    }
}
