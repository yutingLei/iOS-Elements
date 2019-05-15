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
    /// 搜索建议取值所需的key值
    typealias ELTextInputResultsOfKeys = (([String]) -> Void)
    
    /// 搜索建议异步回调
    typealias ELTextInputFetchCallback = (([Any]?) -> Void)
    
    /// 定义同步搜索回调
    typealias ELTextInputFetchSync = ((_ queryString: String?, _ resultOfKeys: ELTextInputResultsOfKeys?) -> [Any]?)
    
    /// 定义异步搜索回调
    typealias ELTextInputFetchAsync = ((_ queryString: String?, _ resultOfKeys: ELTextInputResultsOfKeys?, _ callback: @escaping ELTextInputFetchCallback) -> Void)
    
    /// 边框样式
    enum BorderStyle {
        case none
        case line
        case rounded
        case roundedTiny
        case bottomLine
    }
}

public class ELTextInput: UIView {
    
    /// 边距(默认: top: 0, left: 8, bottom: 0, right: 8)
    public var margins: UIEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8) {
        didSet {
            layoutIfNeeded()
        }
    }
    
    /// 边框样式(默认: .roundedTiny)
    public var borderStyle: BorderStyle = .roundedTiny {
        willSet {
            setBorderStyle(with: newValue)
        }
    }
    
    /// 边框颜色(默认: 边框样式所展示的颜色)
    public var borderColor: UIColor? {
        get { return layer.borderColor == nil ? nil : UIColor(cgColor: layer.borderColor!) }
        set {
            setBorderColor(with: newValue)
        }
    }
    
    /// 使能(默认: true)
    public var isEnabled: Bool {
        get { return super.isUserInteractionEnabled }
        set {
            setEnabled(with: newValue)
        }
    }
    
    /// 输入领域对象
    private(set) public var field: UITextField!
    
    /// 占位符位于编辑框上方(默认: false),当isAnimatedWhenFocused = true时，在中间
    /// 聚焦时, 执行位置变更动画到顶部
    public var isPlacedPlaceholderAtTop = false {
        didSet {
            setLocationOfPlacehoder()
        }
    }
    
    /// 在输入框聚焦过程中，是否执行占位符转移动画, 这个需配合isPlacedPlaceholderAtTop = true使用
    public var isAnimatedWhenFocused = false {
        didSet {
            setLocationOfPlacehoder()
        }
    }
    
    /// 输入框默认值或当前输入的字符
    public var text: String? {
        get { return field.text }
        set {
            field.text = newValue
        }
    }
    
    /// 占位符
    public var placeholder: String? {
        get { return field.placeholder ?? _placeholderLabel.text }
        set {
            setPlaceholder(with: newValue)
        }
    }
    
    /// 同步输入建议
    public var syncFetchSuggestions: ELTextInputFetchSync?
    
    /// 异步(远程)输入建议
    public var asyncFetchSuggestions: ELTextInputFetchAsync?
    
    /// 是否在输入框聚焦时触发(默认: false)
    public var onStartingFetchWhenFocused = false
    
    /// 输入建议选中代理
    public var fetchTableDelegate: ELTablePoperProtocol? {
        get { return _suggestionsTable.delegate as? ELTablePoperProtocol }
        set { _suggestionsTable.delegate = newValue }
    }
    
    /// 输入建议调用间隔时间
    public var fetchDebounceTimeInterval: TimeInterval?
    private var _timeInterval: TimeInterval?
    
    /// 输入建议展示视图
    private lazy var _suggestionsTable: ELTablePoper = {
        let poper = ELTablePoper(refrenceView: field, withDelegate: self)
        poper.isContrasted = false
        return poper
    }()
    
    /// 定时器
    private var _debounceTimer: Timer?
    
    
    //MARK: - Privates & Init
    /// 占位符标签
    private lazy var _placeholderLabel: UILabel = {
        let label = UILabel()
        label.textColor = ELColor.placeholderText
        label.font = field.font
        addSubview(label)
        return label
    }()

    /// 左右视图回调
    private var _callbacks: [Int: (ELTextInputTouchBefore?, ELTextInputTouched?)]?
    
    /// Init
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        /// 设置参数
        setBorderStyle(with: borderStyle)
        
        let x = margins.left
        let y = margins.top
        let w = bounds.width - margins.right - x
        let h = bounds.height - margins.bottom - y
        
        /// 创建输入框
        field = UITextField(frame: CGRect(x: x, y: y, width: w, height: h))
        field.font = UIFont.systemFont(ofSize: 16)
        field.textColor = ELColor.primaryText
        addSubview(field)
        
        /// 添加观察者
        addNotificationCenterObserver()
    }
    
    /// Init error
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Deinit
    deinit {
        _debounceTimer?.invalidate()
        _debounceTimer = nil
        removeNotificationCenterObserver()
    }
}

//MARK: - Append & Prepend contents
public extension ELTextInput {
    
    typealias ELTextInputTouchBefore = (() -> Bool)
    typealias ELTextInputTouched = ((UIView) -> Void)
    
    /// 在输入框右侧添加内容
    ///
    /// - Parameters:
    ///   - content: 被添加的内容，可以是一段字符/一张图片/一个自定义视图
    ///   - beforeTouch: 在点击按钮begin触发，如果返回false, 将不会触发onTouched；如果设置为nil，则直接触发onTouched
    ///   - onTouched: 点击该视图时根据beforeTouch返回值确定是否触发此函数
    func append(_ content: Any, beforeTouch: ELTextInputTouchBefore? = nil, onTouched: ELTextInputTouched? = nil) {
        if let slotView = createSlotView(with: content) {
            field.rightView = slotView
            field.rightViewMode = .always
            if beforeTouch != nil || onTouched != nil {
                slotView.addTarget(self, action: #selector(onSlotViewTouched), for: .touchUpInside)
                if _callbacks == nil {
                    _callbacks = [Int: (ELTextInputTouchBefore?, ELTextInputTouched?)]()
                }
                _callbacks?[slotView.hash] = (beforeTouch, onTouched)
            }
        }
    }
    
    /// 在输入框左侧添加内容
    ///
    /// - Parameters:
    ///   - content: 被添加的内容，可以是一段字符/一张图片/一个自定义视图
    ///   - beforeTouch: 在点击按钮begin触发，如果返回false, 将不会触发onTouched；如果设置为nil，则直接触发onTouched
    ///   - onTouched: 点击该视图时根据beforeTouch返回值确定是否触发此函数
    func prepend(_ content: Any, beforeTouch: ELTextInputTouchBefore? = nil, onTouched: ELTextInputTouched? = nil) {
        if let slotView = createSlotView(with: content) {
            field.leftView = slotView
            field.leftViewMode = .always
            if beforeTouch != nil || onTouched != nil {
                slotView.addTarget(self, action: #selector(onSlotViewTouched), for: .touchUpInside)
                if _callbacks == nil {
                    _callbacks = [Int: (ELTextInputTouchBefore?, ELTextInputTouched?)]()
                }
                _callbacks?[slotView.hash] = (beforeTouch, onTouched)
            }
        }
    }
    
    /// 创建内容
    private func createSlotView(with content: Any) -> UIControl? {
        var slotView: UIButton?
        
        let height = field.frame.height
        
        /// 一段字符
        if let text = content as? String {
            let textFont = UIFont.systemFont(ofSize: 15)
            let textWidth = (text as NSString).boundingRect(with: CGSize(width: CGFloat.infinity, height: height),
                                                            options: .usesLineFragmentOrigin,
                                                            attributes: [.font: textFont],
                                                            context: nil).width
            
            slotView = UIButton(frame: CGRect(x: 0, y: 0, width: textWidth + 16, height: height))
            slotView?.setTitle(text, for: .normal)
            slotView?.titleLabel?.font = textFont
            slotView?.setTitleColor(ELColor.secondaryText, for: .normal)
            return slotView
        }
        
        /// 一张图片
        if let image = content as? UIImage {
            slotView = UIButton(frame: CGRect(x: 0, y: height * 0.1, width: height * 0.8, height: height * 0.8))
            slotView?.setImage(image, for: .normal)
            slotView?.imageView?.contentMode = .scaleAspectFit
            return slotView
        }
        
        /// 一个自定义按钮
        if (content as AnyObject).isKind(of: UIControl.self) {
            return content as? UIControl
        }
        
        /// 一个自定义视图
        if let view = content as? UIView {
            slotView = UIButton(frame: view.bounds)
            view.center = CGPoint(x: slotView!.bounds.midX, y: slotView!.bounds.midY)
            slotView?.addSubview(view)
            return slotView
        }
        
        return slotView
    }
    
    /// 点击插槽视图触发
    @objc func onSlotViewTouched(_ button: UIButton) {
        if let funcs = _callbacks?[button.hash] {
            
            /// 如果需要在点击之前做判断
            var canTouched = true
            if let before = funcs.0 {
                canTouched = before()
            }
            if canTouched, let done = funcs.1 {
                unowned let weakButton = button
                done(weakButton)
            }
        }
    }
}

//MARK: - Settings
extension ELTextInput {
    /// 设置边框样式
    func setBorderStyle(with newStyle: BorderStyle) {
        switch newStyle {
        case .none:
            layer.borderWidth = 0
            layer.cornerRadius = 0
        case .line:
            layer.borderWidth = 1
            layer.borderColor = ELColor.secondLevelBorderColor.cgColor
            layer.cornerRadius = 0
            layer.masksToBounds = true
        case .rounded:
            layer.borderWidth = 1
            layer.borderColor = ELColor.secondLevelBorderColor.cgColor
            layer.cornerRadius = bounds.height / 2
            layer.masksToBounds = true
        case .roundedTiny:
            layer.borderWidth = 1
            layer.borderColor = ELColor.secondLevelBorderColor.cgColor
            layer.cornerRadius = 5
            layer.masksToBounds = true
        case .bottomLine:
            layer.borderWidth = 0
            layer.cornerRadius = 0
            let bottomLineLayer = CAShapeLayer()
            bottomLineLayer.fillColor = nil
            bottomLineLayer.strokeColor = borderColor?.cgColor ?? ELColor.secondLevelBorderColor.cgColor
            bottomLineLayer.zPosition = 1000
            bottomLineLayer.path = {
                let path = CGMutablePath()
                path.move(to: CGPoint(x: 0, y: bounds.height))
                path.addLine(to: CGPoint(x: bounds.width, y: bounds.height))
                return path
            }()
            layer.addSublayer(bottomLineLayer)
            return
        }
        _ = layer.sublayers?.map({ ($0 is CAShapeLayer) ? $0.removeFromSuperlayer() : nil })
    }
    
    /// 设置边框颜色
    func setBorderColor(with color: UIColor?) {
        guard borderColor != color else { return }
        layer.borderColor = color?.cgColor
    }
    
    /// 设置使能
    func setEnabled(with newValue: Bool) {
        guard super.isUserInteractionEnabled != newValue else { return }
        super.isUserInteractionEnabled = newValue
        alpha = newValue ? 1 : 0.7
    }
    
    /// 设置占位符是否居于视图左上方
    func setLocationOfPlacehoder() {
        let x = margins.left
        let y = margins.top
        let w = bounds.width - margins.right - x
        let h = bounds.height - margins.bottom - y
        
        if isPlacedPlaceholderAtTop && isAnimatedWhenFocused {
            _placeholderLabel.frame = CGRect(x: x, y: y + h * 0.3, width: w, height: h * 0.7)
            field.frame = _placeholderLabel.frame
        } else if isPlacedPlaceholderAtTop && !isAnimatedWhenFocused {
            _placeholderLabel.frame = CGRect(x: x, y: y, width: w, height: h * 0.3)
            field.frame = CGRect(x: x, y: y + h * 0.3, width: w, height: h * 0.7)
        } else {
            _placeholderLabel.isHidden = true
            field.frame = CGRect(x: x, y: y, width: w, height: h)
        }
    }
    
    /// 设置占位符
    func setPlaceholder(with text: String?) {
        if isPlacedPlaceholderAtTop {
            _placeholderLabel.text = text
            field.placeholder = nil
        } else {
            _placeholderLabel.isHidden = true
            field.placeholder = text
        }
    }
}

//MARK: - Notification & Fetch
extension ELTextInput {
    /// 添加观察者，观察输入框聚焦或输入情况
    func addNotificationCenterObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onFocused),
                                               name: UITextField.textDidBeginEditingNotification, object: field)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onUnfocused),
                                               name: UITextField.textDidEndEditingNotification, object: field)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onChange),
                                               name: UITextField.textDidChangeNotification, object: field)
    }
    
    /// 移除观察者 有添加必有移除
    func removeNotificationCenterObserver() {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// 输入框已聚焦
    @objc func onFocused(_ notifi: Notification) {
        /// 通知的时本输入框
        guard let obj = notifi.object as? UITextField, obj == field else { return }
        
        /// 是否执行动画
        if isPlacedPlaceholderAtTop && isAnimatedWhenFocused && (field.text == nil || field.text == "") {
            let x = margins.left
            let y = margins.top
            let w = bounds.width - margins.right - x
            let h = bounds.height - margins.bottom - y
            
            UIView.animate(withDuration: 0.35) {[unowned self] in
                self._placeholderLabel.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                self._placeholderLabel.frame  = CGRect(x: x, y: y, width: w, height: h * 0.3)
            }
        }
        
        /// 是否触发动画
        if (asyncFetchSuggestions != nil || syncFetchSuggestions != nil) && onStartingFetchWhenFocused {
            onCreateFetchTimer()
        }
    }
    
    /// 输入框变为不聚焦
    @objc func onUnfocused(_ notifi: Notification) {
        /// 通知的时本输入框
        guard let obj = notifi.object as? UITextField, obj == field else { return }
        
        if isPlacedPlaceholderAtTop && isAnimatedWhenFocused && (field.text == nil || field.text == "") {
            let x = margins.left
            let y = margins.top
            let w = bounds.width - margins.right - x
            let h = bounds.height - margins.bottom - y
            
            UIView.animate(withDuration: 0.35) {[unowned self] in
                self._placeholderLabel.transform = CGAffineTransform.identity
                self._placeholderLabel.frame  = CGRect(x: x, y: y + h * 0.3, width: w, height: h * 0.7)
            }
        }
    }
    
    /// 输入框字符变化时
    @objc func onChange(_ notifi: Notification) {
        /// 通知的时本输入框
        guard let obj = notifi.object as? UITextField, obj == field else { return }
        
        onCreateFetchTimer()
    }
}

//MARK: - Fetch suggestions
extension ELTextInput: ELTablePoperProtocol {
    /// 同步/异步输入建议返回对象取值所需的key
    @objc func onFetchResultsKeys(_ keys: [String]?) {
        _suggestionsTable.keysToContents = keys
    }
    
    /// 开始同步/异步输入建议
    @objc func onFetching() {
        
        /// 执行同步输入建议
        if let syncFunc = syncFetchSuggestions {
            _suggestionsTable.contents = syncFunc(field.text, onFetchResultsKeys)
            _suggestionsTable.show()
        }
            
            /// 执行异步输入建议
        else if let asyncFunc = asyncFetchSuggestions {
            asyncFunc(field.text, onFetchResultsKeys) {[unowned self] contents in
                self._suggestionsTable.contents = contents
                self._suggestionsTable.show()
            }
        }
        
        /// 暂停定时器
        _debounceTimer?.fireDate = Date.distantFuture
    }
    
    /// 输入建议定时器
    func onCreateFetchTimer() {
        guard let milliseconds = fetchDebounceTimeInterval else {
            onFetching()
            return
        }
        if _debounceTimer == nil {
            _debounceTimer = Timer.scheduledTimer(timeInterval: milliseconds / 1000,
                                                  target: self,
                                                  selector: #selector(onFetching),
                                                  userInfo: nil,
                                                  repeats: true)
        }
        /// 当前时间 - 上次输入时间 < 间隔时间，暂停定时器，重新计时
        if let interval = _timeInterval, (Date.timeIntervalSinceReferenceDate - interval) * 1000 < milliseconds {
            _debounceTimer?.fireDate = Date.distantFuture
        }
        _timeInterval = Date.timeIntervalSinceReferenceDate
        
        /// 设置'debountTime'毫秒后触发
        _debounceTimer?.fireDate = Date().addingTimeInterval(milliseconds / 1000)
        
    }
    
    /// 选中选项时触发
    public func tablePoper(_ poper: ELTablePoper, didSelectedRowsAt indexes: [Int], with values: [String]) {
        field.text = values.joined(separator: "/")
    }
}
