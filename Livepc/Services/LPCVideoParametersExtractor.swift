//
//  LPCVideoParametersExtractor.swift
//  Livepc
//
//  Created by Dmytro Platov on 1/16/19.
//  Copyright © 2019 Dmytro Platov. All rights reserved.
//

import UIKit
import AVFoundation

class LPCVideoParametersExtractor {
    
    func parameters(for video: URL) throws -> LCPVideoFileParameters {
        var parameters = LCPVideoFileParameters(resolution: .zero, fps: 0, isContainAudio: false)
        
        let videoAsset = AVAsset(url: video)
        parameters.isContainAudio = (videoAsset.tracks(withMediaType: AVMediaType.audio).first != nil)
        
        guard let videoAssetTrack = videoAsset.tracks(withMediaType: AVMediaType.video).first else {
            throw LPCFileExporterError.ExportError
        }
        
        parameters.fps = videoAssetTrack.nominalFrameRate
        parameters.resolution = videoAssetTrack.naturalSize
        
        return parameters
    }
}
