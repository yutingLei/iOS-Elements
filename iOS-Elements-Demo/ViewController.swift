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
//        elButtons()
        
//        radios()
        
//        selections()
        
//        textInputs()
//        poper()
        
        numberInput()
    }
    
    func elButtons() {
        let properties = ["Nothing settings", "isTinyRound = true", "isRound = true", "isLoading = true", "isPlain = true", "With icon", "isCircle = true", "isImageInLeft = false"]
        let allStyles: [[ELButton.Style]] = [[.normal, .primary], [.success, .info], [.warning, .danger], [.info, .success], [.warning, .danger], [.normal, .primary], [.success, .info], [.success, .info]]
        let titles = [["默认按钮", "主要按钮"], ["成功按钮", "信息按钮"], ["警告按钮", "危险按钮"], ["信息按钮", "成功按钮"], ["警告按钮", "危险按钮"], ["默认按钮", "主要按钮"], ["成功按钮", "信息按钮"], ["成功按钮", "信息按钮"]]
        let iconNames: [ELIcon.Name] = [.tickets, .bell]
        var x: CGFloat = 20
        var y: CGFloat = 80
        let w = (view.bounds.width - 60) / 2
        let h: CGFloat = 45
        for i in 0..<properties.count {
            let label = UILabel.init(frame: CGRect.init(x: x, y: y, width: 300, height: 25))
            label.font = UIFont.boldSystemFont(ofSize: 18)
            label.text = properties[i]
            view.addSubview(label)
            y += 25
            
            for j in 0..<allStyles[i].count {
                let button = ELButton(frame: CGRect(x: x, y: y, width: w, height: h), withStyle: allStyles[i][j])
                button.addTarget(self, action: #selector(onTouch), for: .touchUpInside)
                button.setTitle(titles[i][j], for: .normal)
                view.addSubview(button)
                x += (w + 20)
                
                if i == 1 {
                    button.isTinyRound = true
                } else if i == 2 {
                    button.isRound = true
                } else if i == 3 {
                    button.isLoading = true
                } else if i == 4 {
                    button.isPlain = true
                } else if i == 5 {
                    button.setImage(iconNames[j], for: .normal)
                } else if i == 6 {
                    button.isCircle = true
                    button.setImage(iconNames[j], for: .normal)
                } else if i == 7 {
                    button.isImageInLeft = false
                    button.setImage(iconNames[j], for: .normal)
                }
            }
            x = 20
            y += (h + 20)
        }
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
        let x: CGFloat = 20
        var y: CGFloat = 80
        let w = view.bounds.width - 40
        let h: CGFloat = 40
        
        /// 边框(borderStyle)
        let borders: [UITextField.BorderStyle] = [.none, .line, .roundedRect, .bezel]
        let label = UILabel(frame: CGRect(x: x, y: y, width: w, height: 35))
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.text = "Border Styles"
        view.addSubview(label)
        y += 35
        for border in borders {
            let input = ELTextInput(frame: CGRect(x: x, y: y, width: w, height: h))
            input.borderStyle = border
            view.addSubview(input)
            y += 45
        }
        
        /// Prepend
        let slots1: [ELTextInput.SlotType] = [.text("https://"), .icon(.bell), .image(ELIcon.get(.date)!)]
        let label1 = UILabel(frame: CGRect(x: x, y: y, width: w, height: 35))
        label1.font = UIFont.boldSystemFont(ofSize: 18)
        label1.text = "Prepend"
        view.addSubview(label1)
        y += 35
        for slot in slots1 {
            let input = ELTextInput(frame: CGRect(x: x, y: y, width: w, height: h))
            input.prepend(slot) {
                print("Touched prepend: \(slot)")
            }
            view.addSubview(input)
            y += 45
        }
        
        /// Append
        let slots2: [ELTextInput.SlotType] = [.text(".com"), .icon(.search), .image(ELIcon.get(.document)!), .countDown("获取验证码", 10, nil)]
        let label2 = UILabel(frame: CGRect(x: x, y: y, width: w, height: 35))
        label2.font = UIFont.boldSystemFont(ofSize: 18)
        label2.text = "Append"
        view.addSubview(label2)
        y += 35
        for slot in slots2 {
            let input = ELTextInput(frame: CGRect(x: x, y: y, width: w, height: h))
            input.append(slot) {
                print("Touched append: \(slot)")
            }
            view.addSubview(input)
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
        view.addSubview(label3)
        y += 35
        let input3 = ELTextInput(frame: CGRect(x: x, y: y, width: w, height: h))
        input3.fetchSuggestions = { queryString, callback in
            if let queryString = queryString {
                callback(suggestions.map({ ($0["value"] as! String).contains(queryString) ? $0 : nil }).compactMap({ $0 }))
            } else {
                callback(suggestions)
            }
        }
        view.addSubview(input3)
        y += 45
        
        let label4 = UILabel(frame: CGRect(x: x, y: y, width: w, height: 35))
        label4.font = UIFont.boldSystemFont(ofSize: 18)
        label4.text = "远程搜索(fetchSuggestionsAsync)"
        view.addSubview(label4)
        y += 35
        let input4 = ELTextInput(frame: CGRect(x: x, y: y, width: w, height: h))
        input4.debounceTimeForFetchingSuggestions = 1000
        input4.fetchedSuggestionsResultOfSubtitleKey = "address"
        input4.fetchSuggestionsAsync = { queryString, callback in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: {
                if let queryString = queryString {
                    callback(suggestions.map({ ($0["value"] as! String).contains(queryString) ? $0 : nil }).compactMap({ $0 }))
                } else {
                    callback(suggestions)
                }
            })
        }
        view.addSubview(input4)
        y += 45
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
}

extension ViewController: ELPoperProtocol {
    @objc func onTouch(_ button: UIButton) {
        if button.tag == 11001 {
            let poperView = ELPoper(refrenceView: button, delegate: self)
//            poperView.contents = .image(ELIcon.get(.search)!)
//            poperView.contents = .text("Although similar questions have been asked quite often, I still couldn't find out the exact solution. What I am trying to do now is to remove the left and right border/margin in the TableCell entirely like the below.")
//            poperView.contents = .texts(["选项一", "选项二", "选项三"])
            poperView.animationStyle = .unfold
            poperView.show()
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                poperView.contents = .keyvalue([["title": "选项一", "address": "人民公园路左侧右拐"],
                                                ["title": "选项二", "address": "天府大道一段333号", "disabled": true]])
                poperView.show()
            }
        }
    }
    
    func onPoperSelectionSubtitleKey() -> String {
        return "address"
    }
}

