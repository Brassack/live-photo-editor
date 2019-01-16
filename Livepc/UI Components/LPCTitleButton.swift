//
//  LPCTitleButton.swift
//  Livepc
//
//  Created by Dmytro Platov on 12/1/18.
//  Copyright © 2018 Dmytro Platov. All rights reserved.
//

import UIKit

@IBDesignable
class LPCTitleButton: LPCButton {
    @IBInspectable var title: String? {
        didSet{
            titleLabel.text = title
        }
    }
    
    let titleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubviews()
    }
    
    private func setupSubviews(){
    
        titleLabel.textColor = tintColor
        titleLabel.text = title
        
        addSubview(titleLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let constraints: [NSLayoutConstraint] = [
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }
}
