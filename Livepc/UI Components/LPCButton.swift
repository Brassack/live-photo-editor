//
//  LPCButton.swift
//  Livepc
//
//  Created by Dmytro Platov on 1/12/18.
//  Copyright © 2018 Dmytro Platov. All rights reserved.
//

import UIKit

@IBDesignable
class LPCButton: UIControl {

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        UIView.animate(withDuration: 0.1) { [weak self] () in
            self?.transform = .init(scaleX: 0.99, y: 0.99)
        }
        super.touchesBegan(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let location = touches.first?.location(in: self) {
            print(bounds.contains(location))
        }
        transform = .identity
        super.touchesEnded(touches, with: event)
    }
}
