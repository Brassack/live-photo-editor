//
//  LPCFileType.swift
//  Livepc
//
//  Created by Dmytro Platov on 1/13/19.
//  Copyright © 2019 Dmytro Platov. All rights reserved.
//

import UIKit

enum LPCFileType {
    case video
    case gif
    case livePhoto(UIImage?, CGSize)
}
