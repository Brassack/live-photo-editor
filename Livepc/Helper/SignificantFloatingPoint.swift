//
//  SignificantFloatingPoint.swift
//  Livepc
//
//  Created by Dmytro Platov on 1/24/19.
//  Copyright © 2019 Dmytro Platov. All rights reserved.
//

import Foundation

extension Double {
    var roundedToSignificant: Double {
        return (self*10_000).rounded()/10_000
    }
}
