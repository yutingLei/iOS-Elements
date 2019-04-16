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
    @objc optional func remoteImageSize(at index: Int) -> CGSize
}

public class ELImagePoper: ELPoper {
    
    /// 显示图片页数指示器(false)
    public var showPageControl: Bool!
    
    /// 图片站位图
    /// 若为nil，且展示远程图片时，自动创建加载指示器
    public var placeholderImage: UIImage?
    
    /// 本地图片集合
    public var images: [UIImage]?
    
    /// 远程图片集合, 传入地址即可
    /// 'isFullScreen = true'时，无需实现'ELImagePoperProtocol'中的代理方法'remoteImageSize(at:)'
    /// 'isFullScreen = false'时，需手动实现'ELImagePoperProtocol'中的代理方法'remoteImageSize(at:)'
    public var remotePaths: [String]?
    lazy var remoteQueue: DispatchQueue = { return DispatchQueue(label: "com.remote.image.poper") }()
    
    /// 滚动视图，视图所有图片视图的容器
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.isPagingEnabled = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()
    
    /// 页数指示器
    private lazy var pageControl: UILabel = {
        let pageControl = UILabel()
        pageControl.textAlignment = .center
        pageControl.font = UIFont.systemFont(ofSize: 15)
        return pageControl
    }()
    
    public init(refrenceView: UIView, delegate: ELImagePoperProtocol?) {
        super.init(refrenceView: refrenceView, delegate: delegate)
        showPageControl = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public extension ELImagePoper {
    /// 展示视图
    override func show() {
        let sizes = suggestionSizes()
        let rects = suggestionRects(with: sizes)
        layoutScrollViews(with: rects)
        
        super.show()
    }
}

extension ELImagePoper {
    
    /// 计算内容视图的大小及其子视图的大小
    func suggestionSizes() -> (CGSize, CGSize) {
        if isFullScreen || contentsFixedSize != nil {
            return suggestionContentSize(of: CGSize.zero)
        }
        
        var subviewSize = CGSize.zero
        if let images = images {
            for image in images {
                if image.size.width > subviewSize.width && image.size.height >= subviewSize.height {
                    subviewSize = image.size
                }
            }
        }
        if let paths = remotePaths {
            if let delegate = delegate as? ELImagePoperProtocol, delegate.responds(to: #selector(delegate.remoteImageSize(at:))) {
                for i in 0..<paths.count {
                    if let size = delegate.remoteImageSize?(at: i), size.width > subviewSize.width && size.height >= subviewSize.height {
                        subviewSize = size
                    }
                }
            } else {
                assertionFailure("展示远程图片且'isFullScreen = false'，必须实现'remoteImageSize(at:)'方法")
            }
        }
        
        return suggestionContentSize(of: subviewSize)
    }
    
    /// 计算contentView以及scrollView的位置大小
    func layoutScrollViews(with rects: (CGRect, CGRect)) {
        _ = contentView.subviews.map({ $0.isHidden = !($0 is UIScrollView) })
        
        if scrollView.superview == nil {
            contentView.addSubview(scrollView)
        }
        
        contentView.frame = rects.1
        scrollView.frame = rects.0
        createImageViews()
        updateTheme()
        
        /// page control
        if showPageControl {
            if  pageControl.superview == nil {
                contentView.addSubview(pageControl)
            }
            pageControl.isHidden = false
            pageControl.frame = CGRect(x: 0, y: contentView.frame.height - 35, width: contentView.frame.width, height: 20)
        }
        
        /// Close control
        if isFullScreen {
            if closeBtn.superview == nil {
                contentView.addSubview(closeBtn)
                closeBtn.isHidden = false
            }
        }
    }
    
    /// 创建图片视图
    func createImageViews() {
        var x: CGFloat = 0
        let w = scrollView.bounds.width
        let h = scrollView.bounds.height
        if let images = images {
            for image in images {
                let imageView = UIImageView(frame: CGRect.init(x: x, y: 0, width: w, height: h))
                imageView.contentMode = .center
                imageView.image = image
                scrollView.addSubview(imageView)
                x += w
            }
            scrollView.contentSize = CGSize(width: CGFloat(images.count) * w, height: 0)
            if showPageControl {
                pageControl.text = "\(Int(scrollView.contentOffset.x / scrollView.frame.width))/\(images.count)"
            }
        }
        if let remotePaths = remotePaths {
            for path in remotePaths {
                let imageView = UIImageView(frame: CGRect.init(x: x, y: 0, width: w, height: h))
                imageView.contentMode = .center
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
    
    /// 设置主题颜色
    override func updateTheme() {
        if theme == .light {
            scrollView.backgroundColor = UIColor.white
            if showPageControl {
                pageControl.textColor = UIColor.black
            }
        } else {
            scrollView.backgroundColor = UIColor.black
            if showPageControl {
                pageControl.textColor = .white
            }
        }
        super.updateTheme()
    }
}

extension ELImagePoper: UIScrollViewDelegate {
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
    
//    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
//        if isFullScreen {
//            let index = Int(scrollView.contentOffset.x / scrollView.frame.width)
//            if index >= 0 && index < scrollView.subviews.count {
//                return scrollView.subviews[index]
//            }
//        }
//        return nil
//    }
//
//    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
//    }
}
