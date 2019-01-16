//
//  LPCErrorPresenter.swift
//  Livepc
//
//  Created by Dmytro Platov on 1/16/19.
//  Copyright © 2019 Dmytro Platov. All rights reserved.
//

import UIKit

class LPCErrorPresenter {
    
    func showError(_ message: String = "Something went wrong", title: String = "Error", in controller: UIViewController) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        controller.present(alert, animated: true, completion: nil)
    }
}
