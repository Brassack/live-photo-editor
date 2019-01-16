//
//  LPCFileTypeDetector.swift
//  Livepc
//
//  Created by Dmytro Platov on 1/16/19.
//  Copyright © 2019 Dmytro Platov. All rights reserved.
//

import UIKit
import MobileCoreServices

class LPCFileTypeDetector {
    
    func url(_ url: URL, conformToType type: CFString) -> Bool {
        let extention = url.pathExtension
        guard let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, extention as CFString, nil)?.takeRetainedValue() else {
            return false
        }
        print("uti ", uti as String)
        return UTTypeConformsTo(uti, type)
    }
    
    func type(for url: URL) -> CFString? {
        let extention = url.pathExtension
        return UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, extention as CFString, nil)?.takeRetainedValue()
    }
}
