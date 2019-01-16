//
//  LPCVideoConverter.swift
//  Livepc
//
//  Created by Dmytro Platov on 1/16/19.
//  Copyright © 2019 Dmytro Platov. All rights reserved.
//

import UIKit
import AVFoundation

enum LPCVideoConverterError: Error {
    case ConvertError
}

class LPCVideoConverter {
    
    private let videoAsset: AVAsset
    
    private var progressTimer: Timer?
    var progressFunction: ((Float) -> Void)?

    init?(url: URL) {
        videoAsset = AVAsset(url: url)
        guard videoAsset.tracks(withMediaType: AVMediaType.video).count > 0 else {
            return nil
        }
    }
    
    func convert(to url :URL) throws -> LCPVideoFileParameters {
        var parameters = LCPVideoFileParameters(resolution: .zero, fps: 0, isContainAudio: false)

        
        let composition = AVMutableComposition()
        
        guard let videoAssetTrack = videoAsset.tracks(withMediaType: AVMediaType.video).first else {
            throw LPCVideoConverterError.ConvertError
        }
        
        guard let compositionVideoTrack = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw LPCVideoConverterError.ConvertError
        }
        
        do {
            try compositionVideoTrack.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: videoAsset.duration), of: videoAssetTrack, at: CMTime.zero)
        }catch{
            throw LPCVideoConverterError.ConvertError
        }
        
        if let audioTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
            do {
                try audioTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: videoAsset.duration),
                                               of: videoAsset.tracks(withMediaType: AVMediaType.audio).first! ,
                                               at: .zero)
                parameters.isContainAudio = true
            }catch{
                throw LPCVideoConverterError.ConvertError
            }
        }
        
        
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: videoAsset.duration)
        
        let firstInstruction = videoCompositionInstruction(compositionVideoTrack, asset: videoAsset)
        
        mainInstruction.layerInstructions = [firstInstruction.instruction]
        let mainComposition = AVMutableVideoComposition()
        mainComposition.instructions = [mainInstruction]
        
        mainComposition.frameDuration = CMTimeMake(value: 1, timescale: Int32(videoAssetTrack.nominalFrameRate))
        
        let s = videoAssetTrack.naturalSize.applying(firstInstruction.transform)
        mainComposition.renderSize = CGSize(width: abs(s.width), height: abs(s.height))
        
        guard let assetExport = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            throw LPCVideoConverterError.ConvertError
        }
        assetExport.videoComposition = mainComposition
        assetExport.outputFileType = AVFileType.mov
        assetExport.outputURL = url
        
        parameters.fps = videoAssetTrack.nominalFrameRate
        parameters.resolution = mainComposition.renderSize
        
        let timer = Timer(timeInterval: 0.1, repeats: true, block: { [weak self] (timer) in
            self?.progressFunction?(assetExport.progress)
        })
        RunLoop.main.add(timer, forMode: .default)
        progressTimer = timer
        
        let group = DispatchGroup()
        group.enter()
        
        var error: Error?
        
        assetExport.exportAsynchronously { [weak self] in
            
            self?.progressTimer?.invalidate()
            
            switch assetExport.status {
            case .cancelled, .failed:
                error = assetExport.error
            default:
                break
            }
            group.leave()
        }
        
        group.wait()
        
        if let error = error {
            throw error
        }
        
        return parameters
    }
    
    //Orientation fix
    internal func videoCompositionInstruction(_ track: AVCompositionTrack, asset: AVAsset)
        -> (instruction: AVMutableVideoCompositionLayerInstruction, transform: CGAffineTransform) {
            let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
            let assetTrack = asset.tracks(withMediaType: .video)[0]
            
            let transform = assetTrack.preferredTransform
            let assetInfo = orientationFromTransform(transform)
            var resultTransform = transform
            
            let scaleToFitRatio = (UIScreen.main.bounds.width * UIScreen.main.scale) / assetTrack.naturalSize.width
            if assetInfo.isPortrait {
                let scaleFactor = CGAffineTransform(scaleX: scaleToFitRatio, y: scaleToFitRatio)
                resultTransform = assetTrack.preferredTransform.concatenating(scaleFactor)
                
            } else {
                let scaleFactor = CGAffineTransform(scaleX: scaleToFitRatio, y: scaleToFitRatio)
                var concat = assetTrack.preferredTransform.concatenating(scaleFactor)
                    .concatenating(CGAffineTransform(translationX: 0, y: 0))
                if assetInfo.orientation == .down {
                    let fixUpsideDown = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
                    let windowBounds = UIScreen.main.bounds
                    let yFix = assetTrack.naturalSize.height + windowBounds.height
                    let centerFix = CGAffineTransform(translationX: assetTrack.naturalSize.width, y: yFix)
                    concat = fixUpsideDown.concatenating(centerFix).concatenating(scaleFactor)
                }
                resultTransform = concat
            }
            
            instruction.setTransform(resultTransform, at: CMTime.zero)
            
            return (instruction: instruction, transform: resultTransform)
    }
    
    internal func orientationFromTransform(_ transform: CGAffineTransform)
        -> (orientation: UIImage.Orientation, isPortrait: Bool) {
            var assetOrientation = UIImage.Orientation.up
            var isPortrait = false
            if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
                assetOrientation = .right
                isPortrait = true
            } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
                assetOrientation = .left
                isPortrait = true
            } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
                assetOrientation = .up
            } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
                assetOrientation = .down
            }
            return (assetOrientation, isPortrait)
    }
}
