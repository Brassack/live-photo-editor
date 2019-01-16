//
//  LPCPath.swift
//  Livepc
//
//  Created by Dmytro Platov on 1/14/19.
//  Copyright © 2019 Dmytro Platov. All rights reserved.
//

import UIKit

class LPCPathBuilder {
    
    func tempURL(_ append: String? = nil) -> URL? {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
        if let append = append {
            return url.appendingPathComponent(append)
        }else{
            return url
        }
    }
}
