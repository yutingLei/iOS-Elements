//
//  ELTextPoper.swift
//  文字Poper
//
//  Created by admin on 2019/4/15.
//  Copyright © 2019 Develop. All rights reserved.
//

import UIKit

/*****************************************************************
 * ELTextPoper
 * 视图层次结构
 * keyWindow
 *      - UIView
 *          - UIView(即contentView)
 *              - UITextView
 *
 * 弹出视图之图片展示
 * [v] 1.支持全屏展示
 * [v] 2.支持字体修改
 ******************************************************************/

public class ELTextPoper: ELPoper {
    
    /// 弹出需要显示的字符
    public var text: String? {
        willSet { shouldUpdateContentView = newValue != text }
    }
    
    /// 字符颜色
    public var textColor: UIColor! { willSet { setTextView() } }
    
    /// 字符字体
    public var font: UIFont! {
        willSet { shouldUpdateContentView = newValue.pointSize != font.pointSize }
    }
    
    /// 文字视图
    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.showsVerticalScrollIndicator = false
        textView.showsHorizontalScrollIndicator = false
        textView.textContainerInset = UIEdgeInsets.zero
        containerView.effectsView.addSubview(textView)
        return textView
    }()
    
    /// 是否需要更新内容
    var shouldUpdateContentView = true {
        willSet {
            if newValue {
                shouldUpdateContainerView = true
            }
        }
    }
    
    public override init(refrenceView: UIView, withDelegate delegate: ELPoperProtocol?) {
        super.init(refrenceView: refrenceView, withDelegate: delegate)
        
        /// Create text view
        textColor = ELColor.withHex("8A898C")
        font = UIFont.systemFont(ofSize: 15)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public extension ELTextPoper {
    /// 显示
    override func show() {
        
        defer { super.show() }
        
        /// 是否更新
        guard shouldUpdateContentView else { return }
        shouldUpdateContentView = false
        
        /// 计算步骤:
        ///     1.计算内容所需大小
        ///     2.根据内容所需大小计算容器视图大小
        ///     3.计算容器视图大小及位置，并且过程中会适配屏幕
        ///     4.此时根据容器视图大小计算内容视图大小及位置
        calculateContainerViewsSize(with: calculateContentViewsSize(with: 0))
        calculateContainerViewsRect()
        calculateContentViewsRect()
        setTextView()
    }
}

extension ELTextPoper {
    
    /// Create text view
    func setTextView() {
        textView.text = text
        textView.font = font
        textView.textColor = textColor
    }
    
    /// 更新主题
    override func setTheme() {
        super.setTheme()
        if theme == .light {
            textView.backgroundColor = UIColor.white
        } else {
            textView.backgroundColor = ELColor.rgb(54, 55, 56)
        }
    }
}

//MARK: - Settings
extension ELTextPoper {
    
    /// 计算字符所需的宽度和高度
    func calculateContentViewsSize(with width: CGFloat) -> CGSize {
        if isFullScreen {
            return CGSize.zero
        }
        
        /// Has fixed size
        var contentSize = CGSize.zero
        if let fixedSize = fixedSize {
            if fixedSize.width != 0 {
                contentSize.width = fixedSize.width
            }
            if fixedSize.height != 0 {
                contentSize.height = fixedSize.height
            }
        }
        
        contentSize.width = contentSize.width > 0 ? contentSize.width : width
        let refRect = refrenceView.convert(refrenceView.bounds, to: UIApplication.shared.keyWindow)
        
        /// 计算宽度
        if contentSize.width <= 0 {
            if location == .left {
                contentSize.width = refRect.minX - padding.lar - suggestionArrowsHeight - margin.left
            } else if location == .right {
                contentSize.width = screenWidth - margin.right - padding.lar - suggestionArrowsHeight - refRect.maxX
            } else {
                contentSize.width = screenWidth - padding.lar - margin.lar
            }
        } else {
            if location == .left || location == .right {
                contentSize.width -= (padding.lar + suggestionArrowsHeight)
            } else {
                contentSize.width -= padding.lar
            }
        }
        
        /// 根据宽度计算高度
        if contentSize.height <= 0 {
            switch location {
            case .left, .right:
                if contentSize.width > 0, let text = text {
                    contentSize.height = text.height(withLimit: contentSize.width, fontSize: font.pointSize) + padding.tab
                }
            default:
                if let text = text {
                    let height = text.height(withLimit: contentSize.width, fontSize: font.pointSize)
                    /// 当高度大于宽度时，重新计算
                    if contentSize.width <= 0 && height > width {
                        return calculateContentViewsSize(with: contentSize.width + font.pointSize * 4)
                    }
                    contentSize.height = height
                }
            }
        } else {
            contentSize.height -= (suggestionArrowsHeight + padding.tab)
        }
        return contentSize
    }
    
    /// 计算内容真实大小及位置
    func calculateContentViewsRect() {
        textView.frame = containerView.bounds
        
        /// 如果是全屏
        if isFullScreen {
            textView.frame.origin.x = padding.left
            textView.frame.origin.y = statusBarHeight + 40
            textView.frame.size.width -= padding.lar
            textView.frame.size.height -= (statusBarHeight + 40 + padding.top)
            return
        }
        
        /// 根据位置计算
        switch location {
        case .left, .right:
            if location == .left {
                textView.frame.origin.x = padding.left
            } else {
                textView.frame.origin.x = padding.left + (isArrowed ? suggestionArrowsHeight : 0)
            }
            textView.frame.origin.y = padding.top
            textView.frame.size.width -= (padding.lar + (isArrowed ? suggestionArrowsHeight : 0))
            textView.frame.size.height -= padding.tab
        default:
            let refRect = refrenceView.convert(refrenceView.bounds, to: UIApplication.shared.keyWindow)
            if containerView.frame.midY > refRect.midY {
                textView.frame.origin.y = padding.top + (isArrowed ? suggestionArrowsHeight : 0)
            } else {
                textView.frame.origin.y = padding.top
            }
            textView.frame.origin.x = padding.left
            textView.frame.size.width -= padding.lar
            textView.frame.size.height -= (padding.tab + (isArrowed ? suggestionArrowsHeight : 0))
        }
    }
}

extension String {
    /// 快捷方式获取字符宽度
    func width(withLimit height: CGFloat, fontSize: CGFloat = 15) -> CGFloat {
        let limitSize = CGSize(width: CGFloat.infinity, height: height)
        let font = UIFont.systemFont(ofSize: fontSize)
        return (self as NSString).boundingRect(with: limitSize,
                                               options: .usesLineFragmentOrigin,
                                               attributes: [.font: font],
                                               context: nil).width
    }
    
    /// 快捷方式获取字符高度
    func height(withLimit width: CGFloat, fontSize: CGFloat = 15) -> CGFloat {
        let limitSize = CGSize(width: width, height: CGFloat.infinity)
        let font = UIFont.systemFont(ofSize: fontSize)
        return (self as NSString).boundingRect(with: limitSize,
                                               options: .usesLineFragmentOrigin,
                                               attributes: [.font: font],
                                               context: nil).height
    }
}
