//
//  LPCUnderlineTextField.swift
//  Livepc
//
//  Created by Dmytro Platov on 1/28/19.
//  Copyright © 2019 Dmytro Platov. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

extension Reactive where Base: LPCUnderlineTextField {
    /// Bindable sink for `hidden` property.
    var underlineColor: Binder<UIColor> {
        return Binder(self.base) { textField, underlineColor in
            textField.underlineColor = underlineColor
        }
    }
}

@IBDesignable
class LPCUnderlineTextField: UITextField {

    @IBInspectable var underlineColor: UIColor = .white {
        didSet{
            setNeedsDisplay()
        }
    }
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        super.draw(rect)
        underlineColor.set()
        UIRectFill(CGRect(x: 0, y: rect.size.height - 1, width: rect.size.width, height: 1))
    }

}
