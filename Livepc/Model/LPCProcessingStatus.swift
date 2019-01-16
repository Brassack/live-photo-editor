//
//  LPCProcessingStatus.swift
//  Livepc
//
//  Created by Dmytro Platov on 1/16/19.
//  Copyright © 2019 Dmytro Platov. All rights reserved.
//

import UIKit

enum LPCProcessingStatus<T> {
    case notProcessing
    case processing(Float)
    case finished(T)
}
