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
        elButtons()
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
    
    @objc func onTouch() {
        print("点击了默认按钮")
    }
}

