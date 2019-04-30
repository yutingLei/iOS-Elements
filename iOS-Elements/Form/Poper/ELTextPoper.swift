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
        calculateContainerViewsSize(with: calculateContentViewsSize(with: 150))
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
        if containerTheme == .light {
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
        
        var limitWidth: CGFloat = width
        let refRect = refrenceView.convert(refrenceView.bounds, to: UIApplication.shared.keyWindow)
        if location == .left {
            limitWidth = refRect.minX - contentViewLayoutMargin * 2 - suggestionArrowsHeight - containerViewLayoutMargin
        } else if location == .right {
            limitWidth = screenWidth - containerViewLayoutMargin - contentViewLayoutMargin * 2 - suggestionArrowsHeight - refRect.maxX
        }
        
        switch location {
        case .left, .right:
            if limitWidth > 0, let text = text {
                let height = text.height(withLimit: limitWidth, fontSize: font.pointSize)
                return CGSize(width: limitWidth, height: height)
            }
        default:
            if let text = text {
                let height = text.height(withLimit: limitWidth, fontSize: font.pointSize)
                /// 当高度大于宽度时，重新计算
                if height > width {
                    return calculateContentViewsSize(with: limitWidth + font.pointSize * 4)
                }
                return CGSize(width: width, height: height)
            }
        }
        return CGSize.zero
    }
    
    /// 计算内容真实大小及位置
    func calculateContentViewsRect() {
        textView.frame = containerView.bounds
        
        /// 如果是全屏
        if isFullScreen {
            textView.frame.origin.x = contentViewLayoutMargin
            textView.frame.origin.y = statusBarHeight + 40
            textView.frame.size.width -= contentViewLayoutMargin * 2
            textView.frame.size.height -= (statusBarHeight + 40 + contentViewLayoutMargin)
            return
        }
        
        /// 根据位置计算
        switch location {
        case .left, .right:
            if location == .left {
                textView.frame.origin.x = contentViewLayoutMargin
            } else {
                textView.frame.origin.x = contentViewLayoutMargin + (isContainedArrow ? suggestionArrowsHeight : 0)
            }
            textView.frame.origin.y = contentViewLayoutMargin
            textView.frame.size.width -= (contentViewLayoutMargin * 2 + (isContainedArrow ? suggestionArrowsHeight : 0))
            textView.frame.size.height -= (contentViewLayoutMargin * 2)
        default:
            let refRect = refrenceView.convert(refrenceView.bounds, to: UIApplication.shared.keyWindow)
            if containerView.frame.midY > refRect.midY {
                textView.frame.origin.y = contentViewLayoutMargin + (isContainedArrow ? suggestionArrowsHeight : 0)
            } else {
                textView.frame.origin.y = contentViewLayoutMargin
            }
            textView.frame.origin.x = contentViewLayoutMargin
            textView.frame.size.width -= (contentViewLayoutMargin * 2)
            textView.frame.size.height -= (contentViewLayoutMargin * 2 + (isContainedArrow ? suggestionArrowsHeight : 0))
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
