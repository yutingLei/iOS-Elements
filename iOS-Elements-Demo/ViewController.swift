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
        /// 测试ELButton
        // testELButton()

        /// 测试ELRadio
        testELRadio()
    }

    func testELButton() {
        var x: CGFloat = 0
        var y: CGFloat = 100
        let w = view.bounds.width / 6
        let h: CGFloat = 50
        let styles: [ELButton.Style] = [.normal, .primary, .info, .success, .warning, .danger]

        let contentView1 = UIView(frame: CGRect(x: x, y: y, width: view.bounds.width, height: h))
        view.addSubview(contentView1)
        for i in 0..<6 {
            let elButton = ELButton(frame: CGRect(x: x + 5, y: 3, width: w - 10, height: 44))
            elButton.style = styles[i]
            elButton.setTitle("按钮")
            contentView1.addSubview(elButton)
            x += w
        }

        x = 0
        y += 55
        let contentView2 = UIView(frame: CGRect(x: x, y: y, width: view.bounds.width, height: h))
        view.addSubview(contentView2)
        for i in 0..<6 {
            let elButton = ELButton(frame: CGRect(x: x + 5, y: 3, width: w - 10, height: 44))
            elButton.style = styles[i]
            elButton.isRound = true
            elButton.setTitle("按钮")
            contentView2.addSubview(elButton)
            x += w
        }

        x = 0
        y += 55
        let contentView3 = UIView(frame: CGRect(x: x, y: y, width: view.bounds.width, height: h))
        view.addSubview(contentView3)
        for i in 0..<6 {
            let elButton = ELButton(frame: CGRect(x: x + 5, y: 3, width: w - 10, height: 44))
            elButton.style = styles[i]
            elButton.isPlain = true
            elButton.setTitle("按钮")
            contentView3.addSubview(elButton)
            x += w
        }

        x = 0
        y += 55
        let contentView4 = UIView(frame: CGRect(x: x, y: y, width: view.bounds.width, height: h))
        view.addSubview(contentView4)
        for i in 0..<6 {
            let elButton = ELButton(frame: CGRect(x: x + 5, y: 3, width: w - 10, height: 44))
            elButton.style = styles[i]
            elButton.isCircle = true
            elButton.setIcon(ELIcons.get(.search)!, atLeft: true)
            contentView4.addSubview(elButton)
            x += w
        }

        x = 0
        y += 55
        let contentView5 = UIView(frame: CGRect(x: x, y: y, width: view.bounds.width, height: h))
        view.addSubview(contentView5)
        for i in 0..<6 {
            let elButton = ELButton(frame: CGRect(x: x + 5, y: 3, width: w - 10, height: 44))
            elButton.style = styles[i]
            elButton.isEnabled = false
            elButton.setTitle("按钮")
            contentView5.addSubview(elButton)
            x += w
        }

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3) {
            (contentView5.subviews[1] as? ELButton)?.isEnabled = true
            (contentView5.subviews[3] as? ELButton)?.isEnabled = true
            (contentView5.subviews[5] as? ELButton)?.isEnabled = true
        }

        x = 0
        y += 55
        let elButton = ELButton(frame: CGRect(x: x + 5, y: y, width: view.bounds.width - 10, height: 45))
        elButton.isRound = true
        elButton.style = .customer({
            let theme = ELButtonTheme()
            theme.titleColor = UIColor.blue
            theme.highlightTitleColor = UIColor.white
            theme.backgroundColor = UIColor.green
            theme.highlightBackgroundColor = UIColor.orange
            theme.borderColor = UIColor.red
            theme.highlightBorderColor = UIColor.purple
            return theme
            }())
        elButton.setTitle("按钮")
        view.addSubview(elButton)

        y += 55
        let elButtonGroup = ELButtonGroup(frame: CGRect(x: x + 5, y: y, width: view.bounds.width - 10, height: 45), count: 3)
        elButtonGroup.setIcons([ELIcons.get(.edit, withColor: UIColor.white),
                                ELIcons.get(.share, withColor: UIColor.white),
                                ELIcons.get(.delete, withColor: UIColor.white)])
        elButtonGroup.setStyles([.success, .info, .warning])
        view.addSubview(elButtonGroup)
    }

    func testELRadio() {
        let elRadio = ELRadio(title: "备选项")
        elRadio.frame.origin = CGPoint(x: 100, y: 100)
        view.addSubview(elRadio)

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3) {
            elRadio.isEnabled = false
        }

        let rect = CGRect.init(x: 5, y: 150, width: view.bounds.width - 10, height: 150)
        if let elRadioGroup = ELRadioGroup(frame: rect, titles: ["备选项1", "备选项2", "备选项3"], horizontal: false) {
            view.addSubview(elRadioGroup)
        }
    }
}

