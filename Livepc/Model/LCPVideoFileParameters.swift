//
//  LCPVideoFileParameters.swift
//  Livepc
//
//  Created by Dmytro Platov on 1/16/19.
//  Copyright © 2019 Dmytro Platov. All rights reserved.
//

import UIKit

struct LCPVideoFileParameters {
    var resolution: CGSize
    var fps: Float
    var isContainAudio: Bool
    var duration: TimeInterval
    
    public static func empty() -> LCPVideoFileParameters {
        return LCPVideoFileParameters(resolution: .zero, fps: 0, isContainAudio: false, duration: 0.0)
    }
}
