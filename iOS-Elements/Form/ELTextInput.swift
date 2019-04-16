//
//  ELTextInput.swift
//
//  Created by conjur on 2019/4/8.
//
//

/*****************************************************************
 * ELTextInput
 * 字符输入控件
 *
 *
 * [v] 1.支持插槽
 * [v] 2.支持本地和远程搜索建议，并且支持debounce
 ******************************************************************/

import UIKit

public extension ELTextInput {
    /// Type of contents for slot view
    enum SlotType {
        case text(String)
        case icon(ELIcon.Name)
        case image(UIImage)
        case countDown(String, Int, String?)
    }
    
    typealias ResultOfKeys = (([String]?) -> Void)
    typealias Callback = (([Any]?) -> Void)
    typealias FetchSync = ((_ query: String?,_ keys: ResultOfKeys?, _ callback: Callback) -> Void)
    typealias FetchAsync = ((_ query: String?, _ keys: ResultOfKeys?, _ callback: @escaping Callback) -> Void)
}

public class ELTextInput: UITextField {

    /// 边框样式
    public override var borderStyle: UITextField.BorderStyle {
        get { return super.borderStyle }
        set {
            super.borderStyle = .none
            updateBorderStyle(with: newValue)
        }
    }
    
    /// 编辑时边框颜色(ELColor.primary)
    public var borderColorWhileEditing: UIColor! { willSet { if isEditing { layer.borderColor = newValue.cgColor } } }
    
    /// 未编辑时边框颜色(RGB: 210, 210, 210)
    public var borderColorEndEditing: UIColor! { willSet { if !isEditing { layer.borderColor = newValue.cgColor } } }
    
    /// 使能
    public override var isEnabled: Bool {
        willSet { createMaskView(if: newValue) }
    }
    
    /// 允许输入字符最大长度
    public var maxLength: Int?
    
    /// 允许输入字符最小长度
    public var minLength: Int?
    
    /// 表单验证是否成功(true)
    public var isValidated: Bool {
        get {
            guard shouldValidateWhileEditing else { return true }
            let len = text?.count ?? 0
            if let min = minLength, len < min {
                return false
            }
            if let max = maxLength, len > max {
                return false
            }
            return true
        }
    }
    
    /// 输入时是否触发表单验证(true)
    public var shouldValidateWhileEditing: Bool = true
    
    /// 在验证表单错误时的边框颜色(ELColor.danger)
    public var borderColorWhenErrorOccurred: UIColor!
    
    /// 本地搜索建议
    public var fetchSuggestions: FetchSync?
    
    /// 远程(服务器)搜索建议
    public var fetchSuggestionsAsync: FetchAsync?
    
    /// 输入结束后多少时间触发搜索(单位：毫秒)
    /// 类似'debounce'函数，搜索建议比较频繁的触发时，设置该属性表示在输入
    /// 结束后一定时间触发一次。
    public var debounceTimeForFetchingSuggestions: TimeInterval?
    
    /// 搜索建议弹出视图
    lazy var _poperView: ELTablePoper = {
        let poper = ELTablePoper(refrenceView: self, delegate: self)
        return poper
    }()
    
    /// 左插槽类型
    var leftSlotType: SlotType?
    
    /// 右插槽类型
    var rightSlotType: SlotType?
    
    /// 保存回调函数
    var savedCallbacks: [AnyHashable: Any]?
    
    /// 搜索建议触发定时器及时间记录
    var debounceTimer: Timer?
    var timeInterval: TimeInterval?
    
    /// 倒计时定时器
    lazy var countDownTimer: DispatchSourceTimer = {
        let timer = DispatchSource.makeTimerSource()
        return timer
    }()
    
    //MARK: - Initialize
    public override init(frame: CGRect) {
        super.init(frame: frame)
        borderStyle = .line
        borderColorWhileEditing = ELColor.primary
        borderColorEndEditing = ELColor.rgb(210, 210, 210)
        borderColorWhenErrorOccurred = ELColor.danger
        layer.borderColor = borderColorEndEditing.cgColor
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onTextInputBeganEdit),
                                               name: UITextField.textDidBeginEditingNotification,
                                               object: self)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onTextInputEndedEdit),
                                               name: UITextField.textDidEndEditingNotification,
                                               object: self)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onTextInputChanged),
                                               name: UITextField.textDidChangeNotification,
                                               object: self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        leftSlotType = nil
        rightSlotType = nil
        savedCallbacks = nil
        debounceTimer?.invalidate()
        debounceTimer = nil
        NotificationCenter.default.removeObserver(self)
    }
}

public extension ELTextInput {
    /// 前置内容
    func prepend(_ slotType: SlotType, onTouched: (() -> Void)? = nil) {
        if let leftButton = createView(with: slotType, atLeft: true) {
            if let onTouched = onTouched {
                if savedCallbacks == nil {
                    savedCallbacks = [AnyHashable: Any]()
                }
                leftButton.addTarget(self, action: #selector(onTouched(_:)), for: .touchUpInside)
                savedCallbacks?[leftButton.hash] = onTouched
            }
        }
    }
    
    /// 附加内容
    func append(_ slotType: SlotType, onTouched: (() -> Void)? = nil) {
        if let rightButton = createView(with: slotType, atLeft: false) {
            if let onTouched = onTouched {
                if savedCallbacks == nil {
                    savedCallbacks = [AnyHashable: Any]()
                }
                rightButton.addTarget(self, action: #selector(onTouched(_:)), for: .touchUpInside)
                savedCallbacks?[rightButton.hash] = onTouched
            }
        }
    }
}

extension ELTextInput {
    
    /// 更新边框样式
    func updateBorderStyle(with style: UITextField.BorderStyle) {
        switch style {
        case .bezel:
            layer.cornerRadius = bounds.height / 2
            layer.borderWidth = 1
        case .line:
            layer.cornerRadius = 0
            layer.borderWidth = 1
        case .roundedRect:
            layer.cornerRadius = ceil(bounds.height * 0.2)
            layer.borderWidth = 1
        default:
            layer.cornerRadius = 0
            layer.borderWidth = 0
            backgroundColor = ELColor.rgb(230, 230, 230)
        }
    }
    
    /// 实现前置视图
    func createView(with slotType: SlotType, atLeft: Bool) -> UIButton? {
        
        var slot: UIButton?
        switch slotType {
        case .text(let text):
            let textWidth = (text as NSString).boundingRect(with: CGSize(width: CGFloat.infinity, height: bounds.height),
                                                            options: .usesLineFragmentOrigin,
                                                            attributes: [.font: UIFont.systemFont(ofSize: 14)],
                                                            context: nil).width + 20
            slot = UIButton(frame: CGRect(x: 0, y: 0, width: textWidth, height: bounds.height))
            slot?.setTitle(text, for: .normal)
            slot?.titleLabel?.font = UIFont.systemFont(ofSize: 14)
            slot?.setTitleColor(ELColor.rgb(96, 98, 102), for: .normal)
        case .icon(let icon):
            slot = UIButton(frame: CGRect(x: 0, y: 0, width: 35, height: bounds.height))
            slot?.setImage(ELIcon.get(icon)?.scale(to: 20), for: .normal)
        case .image(let image):
            slot = UIButton(frame: CGRect(x: 0, y: 0, width: 35, height: bounds.height))
            slot?.setImage(image.scale(to: min(bounds.height * 0.6, 96)), for: .normal)
        case .countDown(let text, _, _):
            let textWidth = (text as NSString).boundingRect(with: CGSize(width: CGFloat.infinity, height: bounds.height),
                                                            options: .usesLineFragmentOrigin,
                                                            attributes: [.font: UIFont.systemFont(ofSize: 14)],
                                                            context: nil).width + 20
            slot = UIButton(frame: CGRect(x: 0, y: 0, width: textWidth, height: bounds.height))
            slot?.setTitle(text, for: .normal)
            slot?.titleLabel?.font = UIFont.systemFont(ofSize: 14)
            slot?.setTitleColor(.white, for: .normal)
            slot?.backgroundColor = ELColor.primary
        }
        
        if atLeft {
            leftView = slot
            leftViewMode = .always
            leftSlotType = slotType
        } else {
            rightView = slot
            rightViewMode = .always
            rightSlotType = slotType
        }
        return slot
    }
    
    /// Add a mask view when disabled
    func createMaskView(if enabled: Bool) {
        isUserInteractionEnabled = enabled
        if enabled {
            layer.mask = nil
        } else {
            layer.mask = {
                let maskLayer = CAShapeLayer()
                maskLayer.frame = bounds
                maskLayer.backgroundColor = UIColor.white.withAlphaComponent(0.7).cgColor
                return maskLayer
            }()
        }
    }
}

//MARK: - Touched or Notification
extension ELTextInput {
    /// Did began edit
    @objc func onTextInputBeganEdit(_ notification: Notification) {
        if let obj = notification.object as? ELTextInput, obj == self {
            if !shouldValidateWhileEditing || isValidated {
                layer.borderColor = borderColorWhileEditing.cgColor
            }
            if let fetch = fetchSuggestions {
                fetch(text, onNeededKeys, onFetchedSuggestions)
            }
        }
    }
    
    /// Did ended edit
    @objc func onTextInputEndedEdit(_ notification: Notification) {
        if let obj = notification.object as? ELTextInput, obj == self {
            if !shouldValidateWhileEditing || isValidated {
                layer.borderColor = borderColorEndEditing.cgColor
            }
        }
    }
    
    /// Text input changed
    @objc func onTextInputChanged(_ notification: Notification) {
        if let obj = notification.object as? ELTextInput, obj == self {
            if shouldValidateWhileEditing && !isValidated {
                layer.borderColor = borderColorWhenErrorOccurred.cgColor
            } else {
                layer.borderColor = borderColorWhileEditing.cgColor
            }
            /// 'Debounce'模式
            if let time = debounceTimeForFetchingSuggestions {
                debounce(time)
            } else {
                onStartFetching()
            }
        }
    }
    
    /// On touched slot view
    @objc func onTouched(_ button: UIButton) {
        if button == leftView, let leftSlot = leftSlotType {
            switch leftSlot {
            case .countDown(let title, let seconds, let format):
                countingDown(button, title: title, seconds: seconds, format: format)
            default:
                break
            }
        }
        if button == rightView, let rightSlot = rightSlotType {
            switch rightSlot {
            case .countDown(let title, let seconds, let format):
                countingDown(button, title: title, seconds: seconds, format: format)
            default:
                break
            }
        }
        if let onTouched = savedCallbacks?[button.hash] as? (() -> Void) {
            onTouched()
        }
    }
    
    /// Counting down
    func countingDown(_ button: UIButton, title: String, seconds: Int, format: String?) {
        button.isEnabled = false
        var seconds = seconds
        let format = format ?? "/@/秒"
        button.backgroundColor = ELColor.rgb(96, 98, 102)
        countDownTimer.schedule(wallDeadline: .now(), repeating: .seconds(1))
        countDownTimer.setEventHandler {[unowned countDownTimer] in
            DispatchQueue.main.async {[unowned countDownTimer] in
                if seconds > 0 {
                    button.setTitle(format.replacingOccurrences(of: "/@/", with: "\(seconds)"), for: .normal)
                } else {
                    button.backgroundColor = ELColor.primary
                    button.setTitle(title, for: .normal)
                    button.isEnabled = true
                    countDownTimer.suspend()
                }
            }
            seconds -= 1
        }
        countDownTimer.resume()
    }
}

//MARK: - Fetch Suggestions
extension ELTextInput {
    /// Debounce
    func debounce(_ time: TimeInterval) {
        /// 创建定时器，设定'debounceTime'毫秒后触发
        if debounceTimer == nil {
            debounceTimer = Timer.scheduledTimer(timeInterval: time / 1000,
                                                 target: self,
                                                 selector: #selector(onStartFetching),
                                                 userInfo: nil,
                                                 repeats: true)
        }
        
        /// 当前时间 - 上次输入时间 < 间隔时间，暂停定时器，重新计时
        if let interval = timeInterval, (Date.timeIntervalSinceReferenceDate - interval) * 1000 < time {
            debounceTimer?.fireDate = Date.distantFuture
        }
        timeInterval = Date.timeIntervalSinceReferenceDate
        
        /// 设置'debountTime'毫秒后触发
        debounceTimer?.fireDate = Date().addingTimeInterval(time / 1000)
    }
    
    /// 搜索建议触发
    @objc func onStartFetching(_ timer: Timer? = nil) {
        if let fetch = fetchSuggestions {
            fetch(text, onNeededKeys, onFetchedSuggestions)
        }
        else if let fetchAsync = fetchSuggestionsAsync {
            fetchAsync(text, onNeededKeys, onFetchedSuggestions)
            _poperView.contents = nil
            _poperView.show()
        }
        debounceTimer?.fireDate = Date.distantFuture
    }
    
    /// 取搜索建议结果中的值所需的key
    @objc func onNeededKeys(_ keys: [String]?) {
        _poperView.valuesKeyInContents = keys
    }
    
    /// 远程搜索建议回调
    @objc func onFetchedSuggestions(_ texts: [Any]?) {
        if isFirstResponder {
            if let texts = texts as? [String] {
                if texts.count == 0 {
                    _poperView.removeFromSuperview()
                    return
                }
                _poperView.contents = texts
            }
            else if let textsInfo = texts as? [[String: Any]] {
                if textsInfo.count == 0 {
                    _poperView.removeFromSuperview()
                    return
                }
                _poperView.contents = textsInfo
            }
            _poperView.show()
        }
    }
}

//MARK: - Override functions
extension ELTextInput {
    
    /// Edit text in rect
    public override func editingRect(forBounds bounds: CGRect) -> CGRect {
        var textRect = bounds
        textRect.origin.x = (layer.cornerRadius == bounds.height / 2) ? 16 : 8
        
        if let leftView = leftView {
            textRect.origin.x = leftView.frame.maxX
            textRect.size.width = textRect.width - textRect.minX
        }
        if let rightView = rightView {
            textRect.size.width = textRect.width - rightView.frame.width
        }
        return textRect
    }
    
    /// Draw text in rect
    public override func textRect(forBounds bounds: CGRect) -> CGRect {
        return editingRect(forBounds: bounds)
    }
}

extension ELTextInput: ELTablePoperProtocol {
    /// 已选择建议内容
    public func onSelected(at index: Int, with content: Any) {
        if let content = content as? String {
            text = content
        }
        if let content = content as? [String: Any] {
            let keys = _poperView.valuesKeyInContents ?? ["value", "subvalue"]
            text = content[keys[0]] as? String
        }
    }
    
    /// 建议视图已隐藏
    public func onPoperDismissed() {
        resignFirstResponder()
    }
}
