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
    public var text: String? { didSet { createTextView() } }
    
    /// 字符颜色
    public var textColor: UIColor! { didSet { createTextView() } }
    
    /// 字符字体
    public var font: UIFont! { didSet { createTextView() } }
    
    /// 文字视图
    private var textView: UITextView?
    
    public override init(refrenceView: UIView, delegate: ELPoperProtocol?) {
        super.init(refrenceView: refrenceView, delegate: delegate)
        
        /// Create text view
        textColor = ELColor.withHex("8A898C")
        font = UIFont.systemFont(ofSize: 15)
        createTextView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public extension ELTextPoper {
    /// 显示视图
    override func show() {
        let sizes = suggestionSizes()
        var rects = suggestionRects(with: sizes)
        if isFullScreen, sizes.0.width < rects.0.width || sizes.0.height < rects.0.height {
            rects.0.size.width = min(sizes.0.width, rects.0.width)
            rects.0.size.height = min(sizes.0.height, rects.0.height)
        }
        layoutTextView(with: rects)
        
        super.show()
    }
}

extension ELTextPoper {
    
    /// Create text view
    func createTextView() {
        if textView == nil {
            textView = UITextView()
            textView?.isEditable = false
            textView?.showsVerticalScrollIndicator = false
            textView?.showsHorizontalScrollIndicator = false
            textView?.textContainerInset = UIEdgeInsets.zero
        }
        textView?.text = text
        textView?.font = font
        textView?.textColor = textColor
        
        /// 更新视图
        if superview != nil {
            show()
        }
    }
    
    /// 布局textView
    func layoutTextView(with rects: (CGRect, CGRect)) {
        _ = contentView.subviews.map({ $0.isHidden = !($0 is UITextView) })
        
        if  textView?.superview == nil {
            contentView.addSubview(textView!)
        }
        
        contentView.frame = rects.1
        textView?.frame = rects.0
        updateTheme()
        
        if isFullScreen {
            if closeBtn.superview == nil {
                contentView.addSubview(closeBtn)
            }
            closeBtn.isHidden = false
            textView?.center = contentView.center
        }
    }
    
    /// 更新主题
    override func updateTheme() {
        if theme == .light {
            textView?.backgroundColor = UIColor.white
        } else {
            textView?.backgroundColor = ELColor.rgb(54, 55, 56)
        }
        super.updateTheme()
    }
}

extension ELTextPoper {
    
    /// 计算字符的宽高
    func calculateTextSize(fixedWidth width: CGFloat) -> CGSize {
        switch area {
        case .left:
            let refRect = refrenceView.convert(refrenceView.bounds, to: UIApplication.shared.keyWindow)
            let maxWidth = refRect.minX - 10 - 26
            if maxWidth > 0, let text = text {
                let height = text.heightWithLimitWidth(maxWidth, fontSize: font.pointSize)
                return CGSize(width: maxWidth, height: height)
            }
        case .right:
            let refRect = refrenceView.convert(refrenceView.bounds, to: UIApplication.shared.keyWindow)
            let maxWidth = UIScreen.main.bounds.width - 10 - 26 - refRect.maxX
            if maxWidth > 0, let text = text {
                let height = text.heightWithLimitWidth(maxWidth, fontSize: font.pointSize)
                return CGSize(width: maxWidth, height: height)
            }
        default:
            if let text = text {
                let height = text.heightWithLimitWidth(width, fontSize: font.pointSize)
                if height > width {
                    return calculateTextSize(fixedWidth: width + font.pointSize * 4)
                }
                return CGSize(width: width, height: height)
            }
        }
        return CGSize.zero
    }
    
    /// 计算视图的宽高
    func suggestionSizes() -> (CGSize, CGSize) {
        if isFullScreen || contentsFixedSize != nil {
            let textViewSize = calculateTextSize(fixedWidth: UIScreen.main.bounds.width - 16)
            return (textViewSize, suggestionContentSize(of: CGSize.zero).1)
        }
        
        let textViewSize = calculateTextSize(fixedWidth: font.pointSize * 12)
        return suggestionContentSize(of: textViewSize)
    }
}
