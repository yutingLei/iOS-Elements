//
//  ViewController.swift
//  iOS-Elements-Demo
//
//  Created by admin on 2019/2/20.
//  Copyright © 2019 Develop. All rights reserved.
//

import UIKit
import Elements

class ViewController: UIViewController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
//                buttons()
        
        //        radios()
        
        //        selections()
        
                textInputs()
        
        //        numberInput()
        
//        select()
//        poper()
    }
    
    func buttons() {
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 64, width: view.bounds.width, height: view.bounds.height - 64))
        view.addSubview(scrollView)
        
        var x: CGFloat = 20
        var y: CGFloat = 0
        let w = (view.bounds.width - 60) / 2
        let h: CGFloat = 45
        
        let styles: [ELButton.Style] = [.normal, .primary, .success, .info, .warning, .danger]
        let types = ["默认按钮", "主要按钮", "成功按钮", "信息按钮", "警告按钮", "危险按钮"]
        let settings = ["isPlained", "isTinyRound", "isRounded", "isCircled", "isLoading", "isEnabled", "setImage"]
        
        for i in 0..<settings.count {
            let label = UILabel(frame: CGRect(x: x, y: y, width: 300, height: 25))
            label.font = UIFont.boldSystemFont(ofSize: 18)
            label.text = settings[i]
            scrollView.addSubview(label)
            y += 25
            
            for j in 1...types.count {
                let button = ELButton(frame: CGRect(x: x, y: y, width: w, height: h))
                button.style = styles[j - 1]
                if i == settings.count - 1 {
                    button.setTitle(types[j - 1], for: .normal)
                    button.setImage(ELIcon.get(.search), for: .normal)
                    button.layoutImageAtRight = j % 2 == 0
                } else {
                    button.setTitle(types[j - 1], for: .normal)
                }
                
                switch i {
                case 0: button.isPlained = true
                case 1: button.isTinyRounded = true
                case 2: button.isRounded = true
                case 3: button.isCircled = true
                case 4: button.isLoading = true
                case 5: button.isEnabled = false
                default:break
                }
                
                scrollView.addSubview(button)
                
                x += (w + 20)
                if j % 2 == 0 {
                    x = 20
                    y += (h + 15)
                }
            }
            x = 20
        }
        scrollView.contentSize = CGSize(width: 0, height: y)
    }
    
    
    func selections() {
        let layouts: [ELSelection.Layout] = [.horizontal, .vertical, .justified, .matrix(row: 2, col: 2)]
        let titles = ["Horizontal", "Vertical", "Justified", "Matrix"]
        let texts = [["选项一", "选项二", "选项三", "选项四"],
                     ["选项一", "选项二", "选项三", "这是一个长选项，为了测试竖直排列时会出现什么情况"],
                     ["这是一个长选项，为了测试竖直排列时会出现什么情况", "选项一", "选项二", "选项三", "这是一个长选项，为了测试竖直排列时会出现什么情况"],
                     ["选项一", "选项二", "选项三", "选项四"],]
        let starts: [ELSelection.Start] = [.numeric(1), .upperChar("A"), .lowerChar("f"), .roman(17)]
        let x: CGFloat = 20
        var y: CGFloat = 80
        let w = view.bounds.width - 40
        var h: CGFloat = 50
        for i in 0..<layouts.count {
            let label = UILabel(frame: CGRect.init(x: x, y: y, width: w, height: 35))
            label.font = UIFont.boldSystemFont(ofSize: 18)
            label.text = titles[i]
            view.addSubview(label)
            y += 35
            
            let group = ELSelection(frame: CGRect(x: x, y: y, width: w, height: h), withLayout: layouts[i])
            group.texts = texts[i]
            group.mode = i % 2 == 0 ? .single : .multiple
            group.start = starts[i]
            group.itemSelectedColor = UIColor.orange
            group.disabledItem(at: 0, with: true)
            view.addSubview(group)
            y += h
            h = 150
        }
    }
    
    func textInputs() {
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 64, width: view.bounds.width, height: view.bounds.height - 64))
        view.addSubview(scrollView)
        
        let x: CGFloat = 20
        var y: CGFloat = 0
        let w = view.bounds.width - 40
        let h: CGFloat = 40
        
        /// 边框(borderStyle)
        let borders: [ELTextInput.BorderStyle] = [.none, .line, .roundedTiny, .rounded, .bottomLine]
        let label = UILabel(frame: CGRect(x: x, y: y, width: w, height: 35))
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.text = "Border Styles"
        scrollView.addSubview(label)
        y += 35
        for border in borders {
            let input = ELTextInput(frame: CGRect(x: x, y: y, width: w, height: h))
            input.borderStyle = border
            scrollView.addSubview(input)
            y += 45
        }
        
        /// Prepend
        let button1 = ELButton(frame: CGRect(x: 0, y: 0, width: 80, height: h))
        button1.isRounded = false
        button1.setTitle("https://", for: .normal)
        let slots: [Any] = ["https://", ELIcon.get(.search)!, button1]
        let label1 = UILabel(frame: CGRect(x: x, y: y, width: w, height: 35))
        label1.font = UIFont.boldSystemFont(ofSize: 18)
        label1.text = "Prepend"
        scrollView.addSubview(label1)
        y += 35
        for slot in slots {
            let input = ELTextInput(frame: CGRect(x: x, y: y, width: w, height: h))
            input.prepend(slot, beforeTouch: nil) {slotView in
                print("你点击了\(slotView)")
            }
            scrollView.addSubview(input)
            y += 45
        }
        
        /// Append
        let button2 = ELButton(frame: CGRect(x: 0, y: 0, width: 80, height: 30))
        button2.isPlained = true
        button2.isRounded = true
        button2.setTitle("获取验证码", for: .normal)
        let slots2: [Any] = [".com", ELIcon.get(.search)!, button2]
        let label2 = UILabel(frame: CGRect(x: x, y: y, width: w, height: 35))
        label2.font = UIFont.boldSystemFont(ofSize: 18)
        label2.text = "Append"
        scrollView.addSubview(label2)
        y += 35
        for slot in slots2 {
            let input = ELTextInput(frame: CGRect(x: x, y: y, width: w, height: h))
            input.append(slot, beforeTouch: nil) {slotView in
                print("你点击了\(slotView)")
            }
            scrollView.addSubview(input)
            y += 45
        }
        
        /// 本地搜索(fetchSuggestions)
        let suggestions = [[ "value": "三全鲜食（北新泾店）", "address": "长宁区新渔路144号", "disabled": "true"],
                           [ "value": "Hot honey 首尔炸鸡（仙霞路）", "address": "上海市长宁区淞虹路661号" ],
                           [ "value": "新旺角茶餐厅", "address": "上海市普陀区真北路988号创邑金沙谷6号楼113" ],
                           [ "value": "泷千家(天山西路店)", "address": "天山西路438号" ],
                           [ "value": "胖仙女纸杯蛋糕（上海凌空店）", "address": "上海市长宁区金钟路968号1幢18号楼一层商铺18-101" ],
                           [ "value": "贡茶", "address": "上海市长宁区金钟路633号" ],
                           [ "value": "豪大大香鸡排超级奶爸", "address": "上海市嘉定区曹安公路曹安路1685号" ],
                           [ "value": "茶芝兰（奶茶，手抓饼）", "address": "上海市普陀区同普路1435号" ],
                           [ "value": "十二泷町", "address": "上海市北翟路1444弄81号B幢-107" ],
                           [ "value": "星移浓缩咖啡", "address": "上海市嘉定区新郁路817号" ],]
        let label3 = UILabel(frame: CGRect(x: x, y: y, width: w, height: 35))
        label3.font = UIFont.boldSystemFont(ofSize: 18)
        label3.text = "本地搜索(fetchSuggestions)"
        scrollView.addSubview(label3)
        y += 35
        let input3 = ELTextInput(frame: CGRect(x: x, y: y, width: w, height: h))
        input3.syncFetchSuggestions = { queryString, resultOfKeys in
            resultOfKeys?(["value", "address"])
            if let queryString = queryString, queryString != "" {
                return (suggestions.map({ ($0["value"] as! String).contains(queryString) ? $0 : nil }).compactMap({ $0 }))
            } else {
                return suggestions
            }
        }
        scrollView.addSubview(input3)
        y += 45
        
        let label4 = UILabel(frame: CGRect(x: x, y: y, width: w, height: 35))
        label4.font = UIFont.boldSystemFont(ofSize: 18)
        label4.text = "远程搜索(fetchSuggestionsAsync)"
        scrollView.addSubview(label4)
        y += 35
        let input4 = ELTextInput(frame: CGRect(x: x, y: y, width: w, height: h))
        input4.fetchDebounceTimeInterval = 1000
        input4.asyncFetchSuggestions = { queryString, resultOfKeys, callback in
            resultOfKeys?(["value", "address"])
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: {
                if let queryString = queryString {
                    callback(suggestions.map({ ($0["value"] as! String).contains(queryString) ? $0 : nil }).compactMap({ $0 }))
                } else {
                    callback(suggestions)
                }
            })
        }
        scrollView.addSubview(input4)
        y += 45
        
        /// isPlacedPlaceholderAtTop
        let label5 = UILabel(frame: CGRect(x: x, y: y, width: w, height: 35))
        label5.font = UIFont.boldSystemFont(ofSize: 18)
        label5.text = "isPlacedPlaceholderAtTop = true"
        scrollView.addSubview(label5)
        y += 35
        let input5 = ELTextInput(frame: CGRect(x: x, y: y, width: w, height: 70))
        input5.isPlacedPlaceholderAtTop = true
        input5.placeholder = "手机号码"
        input5.borderStyle = .bottomLine
        scrollView.addSubview(input5)
        y += 75
        
        
        /// isAnimatedWhenFocused
        let label6 = UILabel(frame: CGRect(x: x, y: y, width: w, height: 35))
        label6.font = UIFont.boldSystemFont(ofSize: 18)
        label6.text = "isAnimatedWhenFocused = true"
        scrollView.addSubview(label6)
        y += 35
        let input6 = ELTextInput(frame: CGRect(x: x, y: y, width: w, height: 70))
        input6.isPlacedPlaceholderAtTop = true
        input6.isAnimatedWhenFocused = true
        input6.placeholder = "手机号码"
        input6.borderStyle = .bottomLine
        scrollView.addSubview(input6)
        y += 75
        
        scrollView.contentSize = CGSize.init(width: 0, height: y)
    }
    
    func poper() {
        let button = UIButton.init(frame: CGRect.init(x: 120, y: 650, width: 150, height: 40))
        button.addTarget(self, action: #selector(onTouch), for: .touchDown)
        button.backgroundColor = .orange
        button.tag = 11001
        view.addSubview(button)
    }
    
    func numberInput() {
        let texts = ["Normal", ".min = 1, .max = 10", ".step = 5", ".precision = 2, .step = 0.1", ".controlsPosition = .right"]
        let x: CGFloat = 20
        var y: CGFloat = 80
        let w: CGFloat = 150
        let h: CGFloat = 40
        
        for text in texts {
            let label = UILabel(frame: CGRect(x: x, y: y, width: 280, height: 30))
            label.font = UIFont.boldSystemFont(ofSize: 18)
            label.text = text
            view.addSubview(label)
            y += 35
            
            let input = ELNumberInput(frame: CGRect(x: x, y: y, width: w, height: h), value: 1)
            if text == ".min = 1, .max = 10" {
                input.min = 1
                input.max = 10
            }
            if text == ".step = 5" {
                input.step = 5
            }
            if text == ".precision = 2, .step = 0.1" {
                input.step = 0.1
                input.precision = 2
            }
            if text == ".controlsPosition = .right" {
                input.controlsPosition = .right
            }
            view.addSubview(input)
            y += 45
        }
    }
    
    func select() {
        let suggestions = [[ "value": "三全鲜食（北新泾店）", "address": "长宁区新渔路144号", "disabled": true],
                           [ "value": "Hot honey 首尔炸鸡（仙霞路）", "address": "上海市长宁区淞虹路661号" ],
                           [ "value": "新旺角茶餐厅", "address": "上海市普陀区真北路988号创邑金沙谷6号楼113" ],
                           [ "value": "泷千家(天山西路店)", "address": "天山西路438号" ],
                           [ "value": "胖仙女纸杯蛋糕（上海凌空店）", "address": "上海市长宁区金钟路968号1幢18号楼一层商铺18-101" ],
                           [ "value": "贡茶", "address": "上海市长宁区金钟路633号" ],
                           [ "value": "豪大大香鸡排超级奶爸", "address": "上海市嘉定区曹安公路曹安路1685号" ],
                           [ "value": "茶芝兰（奶茶，手抓饼）", "address": "上海市普陀区同普路1435号" ],
                           [ "value": "十二泷町", "address": "上海市北翟路1444弄81号B幢-107" ],
                           [ "value": "星移浓缩咖啡", "address": "上海市嘉定区新郁路817号" ]]
        
        let texts = ["Normal", "isDisabled = true", "isMultiple = true", "alignItems = .center"]
        let x: CGFloat = 20
        var y: CGFloat = 80
        let w: CGFloat = 250
        let h: CGFloat = 40
        
        for text in texts {
            let label = UILabel(frame: CGRect(x: x, y: y, width: 280, height: 30))
            label.font = UIFont.boldSystemFont(ofSize: 18)
            label.text = text
            view.addSubview(label)
            y += 35
            
            let select = ELSelect(frame: CGRect(x: x, y: y, width: w, height: h), onSelected: { value in
                print("Selected: \(value)")
            })
            select.placeholder = "请选择"
            select.contents = suggestions
            if text == "isDisabled = true" {
                select.isDisabled = true
            }
            if text == "isMultiple = true" {
                select.isMultiple = true
            }
            if text == "alignItems = .center" {
                select.alignItems = .center
            }
            view.addSubview(select)
            y += 45
        }
    }
}

extension ViewController: ELPoperProtocol {
    @objc func onTouch(_ button: UIButton) {
        if button.tag == 11001 {
                        let imagePoper = ELImagePoper(refrenceView: button, withDelegate: nil)
                        imagePoper.images = [ELIcon.get(.search), ELIcon.get(.add), ELIcon.get(.bell)] as! [UIImage]
                        imagePoper.showPageControl = true
                        imagePoper.isFullScreen = true
                        imagePoper.show()
            
//            let textPoper = ELTextPoper.init(refrenceView: button, withDelegate: nil)
//            textPoper.text = "动画看起来是用来显示一段连续的运动过程，但实际上当在固定位置上展示像素的时候并不能做到这一点。一般来说这种显示都无法做到连续的移动，能做的仅仅是足够快地展示一系列静态图片，只是看起来像是做了运动。"
//            textPoper.animationStyle = .unfold
//            textPoper.show()
            
//            let tablePoper = ELTablePoper.init(refrenceView: button, withDelegate: self)
//            tablePoper.contents =  [[
//                "value": "yizhi",
//                "label": "一致"
//                ], [
//                    "value": "fankui",
//                    "label": "反馈"
//                ], [
//                    "value": "xiaolv",
//                    "label": "效率"
//                ], [
//                    "value": "动画看起来是用来显示一段连续的运动过程",
//                    "label": "可控",
//                    "disabled": true
//                ]]
//            tablePoper.isMultipleSelection = true
//            tablePoper.selectedColor = UIColor.orange
//            tablePoper.isArrowCentered = true
//            tablePoper.fixedSizeOfContainerView = CGSize(width: button.frame.width, height: 0)
//            tablePoper.show()
        }
    }
    
    func keyvalues() -> [Any] {
        return [[
            "value": "zhinan",
            "label": "指南",
            "children": [[
                "value": "shejiyuanze",
                "label": "设计原则",
                "children": [[
                    "value": "yizhi",
                    "label": "一致"
                    ], [
                        "value": "fankui",
                        "label": "反馈"
                    ], [
                        "value": "xiaolv",
                        "label": "效率"
                    ], [
                        "value": "kekong",
                        "label": "可控"
                    ]]
                ], [
                    "value": "daohang",
                    "label": "导航",
                    "children": [[
                        "value": "cexiangdaohang",
                        "label": "侧向导航"
                        ], [
                            "value": "dingbudaohang",
                            "label": "顶部导航"
                        ]]
                ]]
            ], [
                "value": "zujian",
                "label": "组件",
                "children": [[
                    "value": "basic",
                    "label": "Basic",
                    "children": [[
                        "value": "layout",
                        "label": "Layout 布局"
                        ], [
                            "value": "color",
                            "label": "Color 色彩"
                        ], [
                            "value": "typography",
                            "label": "Typography 字体"
                        ], [
                            "value": "icon",
                            "label": "Icon 图标"
                        ], [
                            "value": "button",
                            "label": "Button 按钮"
                        ]]
                    ], [
                        "value": "form",
                        "label": "Form",
                        "children": [[
                            "value": "radio",
                            "label": "Radio 单选框"
                            ], [
                                "value": "checkbox",
                                "label": "Checkbox 多选框"
                            ], [
                                "value": "input",
                                "label": "Input 输入框"
                            ], [
                                "value": "input-number",
                                "label": "InputNumber 计数器"
                            ], [
                                "value": "select",
                                "label": "Select 选择器"
                            ], [
                                "value": "cascader",
                                "label": "Cascader 级联选择器"
                            ], [
                                "value": "switch",
                                "label": "Switch 开关"
                            ], [
                                "value": "slider",
                                "label": "Slider 滑块"
                            ], [
                                "value": "time-picker",
                                "label": "TimePicker 时间选择器"
                            ], [
                                "value": "date-picker",
                                "label": "DatePicker 日期选择器"
                            ], [
                                "value": "datetime-picker",
                                "label": "DateTimePicker 日期时间选择器"
                            ], [
                                "value": "upload",
                                "label": "Upload 上传"
                            ], [
                                "value": "rate",
                                "label": "Rate 评分"
                            ], [
                                "value": "form",
                                "label": "Form 表单"
                            ]]
                    ], [
                        "value": "data",
                        "label": "Data",
                        "children": [[
                            "value": "table",
                            "label": "Table 表格"
                            ], [
                                "value": "tag",
                                "label": "Tag 标签"
                            ], [
                                "value": "progress",
                                "label": "Progress 进度条"
                            ], [
                                "value": "tree",
                                "label": "Tree 树形控件"
                            ], [
                                "value": "pagination",
                                "label": "Pagination 分页"
                            ], [
                                "value": "badge",
                                "label": "Badge 标记"
                            ]]
                    ], [
                        "value": "notice",
                        "label": "Notice",
                        "children": [[
                            "value": "alert",
                            "label": "Alert 警告"
                            ], [
                                "value": "loading",
                                "label": "Loading 加载"
                            ], [
                                "value": "message",
                                "label": "Message 消息提示"
                            ], [
                                "value": "message-box",
                                "label": "MessageBox 弹框"
                            ], [
                                "value": "notification",
                                "label": "Notification 通知"
                            ]]
                    ], [
                        "value": "navigation",
                        "label": "Navigation",
                        "children": [[
                            "value": "menu",
                            "label": "NavMenu 导航菜单"
                            ], [
                                "value": "tabs",
                                "label": "Tabs 标签页"
                            ], [
                                "value": "breadcrumb",
                                "label": "Breadcrumb 面包屑"
                            ], [
                                "value": "dropdown",
                                "label": "Dropdown 下拉菜单"
                            ], [
                                "value": "steps",
                                "label": "Steps 步骤条"
                            ]]
                    ], [
                        "value": "others",
                        "label": "Others",
                        "children": [[
                            "value": "dialog",
                            "label": "Dialog 对话框"
                            ], [
                                "value": "tooltip",
                                "label": "Tooltip 文字提示"
                            ], [
                                "value": "popover",
                                "label": "Popover 弹出框"
                            ], [
                                "value": "card",
                                "label": "Card 卡片"
                            ], [
                                "value": "carousel",
                                "label": "Carousel 走马灯"
                            ], [
                                "value": "collapse",
                                "label": "Collapse 折叠面板"
                            ]]
                    ]]
            ], [
                "value": "ziyuan",
                "label": "资源",
                "children": [[
                    "value": "axure",
                    "label": "Axure Components"
                    ], [
                        "value": "sketch",
                        "label": "Sketch Templates"
                    ], [
                        "value": "jiaohu",
                        "label": "组件交互文档"
                    ]]
            ]]
    }
}

extension ViewController: ELTablePoperProtocol {
    func onSingleSelected(_ poper: ELTablePoper, at index: Int) {
        print("\(index)")
    }
}
