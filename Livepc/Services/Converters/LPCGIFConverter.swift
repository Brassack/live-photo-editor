//
//  LPCGIFConverter.swift
//  Livepc
//
//  Created by Dmytro Platov on 1/15/19.
//  Copyright © 2019 Dmytro Platov. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation
import ImageIO
import MobileCoreServices

enum LPCGIFConverterError: Error {
    case ConverterError
}
//  GIF -> MOV Based on
//  GIF2MP4.swift
//
//  Created by PowHu Yang on 2017/1/24.
//  Copyright © 2017 PowHu Yang. All rights reserved.
//https://gist.github.com/powhu/00acd9d34fa8d61d2ddf5652f19cafcf

class LPCGIFConverter {
    //Private stuff
    private(set) var gif: GIF
    private(set) var videoWriter: AVAssetWriter!
    private(set) var videoWriterInput: AVAssetWriterInput!
    private(set) var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor!
    //Interface
    var videoSize : CGSize {
        //The size of the video must be a multiple of 16
        return CGSize(width: floor(gif.size.width / 16) * 16, height: floor(gif.size.height / 16) * 16)
    }
    var progressFunction: ((Float) -> Void)?
    
    // MARK: init
    init?(url: URL) {
        guard let gif = GIF(url: url) else { return nil }
        self.gif = gif
    }
    
    // MARK: Interface
    func convert(to url :URL) throws {
        try prepare(outputURL: url)
        
        var index = 0
        var delay = 0.0 - gif.frameDurations[0]
        let queue = DispatchQueue(label: "mediaInputQueue")
        
        let group = DispatchGroup()
        group.enter()
        
        var writerError: Error?
        videoWriterInput.requestMediaDataWhenReady(on: queue) { [weak self] in
            guard let self = self else { return }
            var isFinished = true
            
            while index < self.gif.framesCount {
                if self.videoWriterInput.isReadyForMoreMediaData == false {
                    isFinished = false
                    break
                }
                
                if let cgImage = self.gif.getFrame(at: index) {
                    let frameDuration = self.gif.frameDurations[index]
                    delay += Double(frameDuration)
                    let presentationTime = CMTime(seconds: delay, preferredTimescale: 600)
                    let result = self.addImage(image: UIImage(cgImage: cgImage), withPresentationTime: presentationTime)
                    if result == false {
                        writerError = LPCGIFConverterError.ConverterError
                        isFinished = true
                    } else {
                        index += 1
                    }
                }
                self.progressFunction?(Float(index)/Float(self.gif.framesCount))
            }
            
            if isFinished {
                self.videoWriterInput.markAsFinished()
                self.videoWriter.finishWriting() {
                    group.leave()
                }
            }
        }
        
        group.wait()
        if let error = writerError {
            throw error
        }
    }
    
    // MARK: Private methods
    private func prepare(outputURL: URL) throws {
        try? FileManager.default.removeItem(at: outputURL)
        
        let avOutputSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: NSNumber(value: Float(videoSize.width)),
            AVVideoHeightKey: NSNumber(value: Float(videoSize.height))
        ]
        
        let sourcePixelBufferAttributesDictionary = [
            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32ARGB),
            kCVPixelBufferWidthKey as String: NSNumber(value: Float(videoSize.width)),
            kCVPixelBufferHeightKey as String: NSNumber(value: Float(videoSize.height))
        ]
        
        videoWriter = try AVAssetWriter(outputURL: outputURL, fileType: AVFileType.mov)
        videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: avOutputSettings)
        videoWriter.add(videoWriterInput)
        
        pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput, sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)
        videoWriter.startWriting()
        videoWriter.startSession(atSourceTime: CMTime.zero)
    }
    
 
    
    private func addImage(image: UIImage, withPresentationTime presentationTime: CMTime) -> Bool {
        guard let pixelBufferPool = pixelBufferAdaptor.pixelBufferPool else {
            print("pixelBufferPool is nil ")
            return false
        }
        let pixelBuffer = pixelBufferFromImage(image: image, pixelBufferPool: pixelBufferPool, size: videoSize)
        return pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
    }
    
    private func pixelBufferFromImage(image: UIImage, pixelBufferPool: CVPixelBufferPool, size: CGSize) -> CVPixelBuffer {
        var pixelBufferOut: CVPixelBuffer?
        let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &pixelBufferOut)
        if status != kCVReturnSuccess {
            fatalError("CVPixelBufferPoolCreatePixelBuffer() failed")
        }
        let pixelBuffer = pixelBufferOut!
        
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
        
        let data = CVPixelBufferGetBaseAddress(pixelBuffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: data, width: Int(size.width), height: Int(size.height),
                                bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
        
        context!.clear(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        let horizontalRatio = size.width / image.size.width
        let verticalRatio = size.height / image.size.height
        let aspectRatio = max(horizontalRatio, verticalRatio) // ScaleAspectFill
        //let aspectRatio = min(horizontalRatio, verticalRatio) // ScaleAspectFit
        
        let newSize = CGSize(width: image.size.width * aspectRatio, height: image.size.height * aspectRatio)
        
        let x = newSize.width < size.width ? (size.width - newSize.width) / 2 : -(newSize.width-size.width)/2
        let y = newSize.height < size.height ? (size.height - newSize.height) / 2 : -(newSize.height-size.height)/2
        
        context!.draw(image.cgImage!, in: CGRect(x:x, y:y, width:newSize.width, height:newSize.height))
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
        
        return pixelBuffer
    }
}

// MARK: GIF type
extension LPCGIFConverter {
    class GIF {
        private let frameDelayThreshold = 0.02
        private(set) var duration = TimeInterval(0.0)
        private(set) var imageSource: CGImageSource!
        private(set) var framesCount: Int
        private(set) lazy var frameDurations = [TimeInterval]()
        var size = CGSize.zero

        private lazy var getFrameQueue: DispatchQueue = DispatchQueue(label: "gif.frame.queue", qos: .userInteractive)
        
        init?(url: URL) {
            guard let imgSource = CGImageSourceCreateWithURL(url as CFURL, nil), let imgType = CGImageSourceGetType(imgSource) , UTTypeConformsTo(imgType, kUTTypeGIF) else {
                return nil
            }
            self.imageSource = imgSource
            framesCount = CGImageSourceGetCount(imageSource)
            if framesCount > 0,
                let firstFrame = CGImageSourceCreateImageAtIndex(self.imageSource, 0, nil){
                size = CGSize(width: firstFrame.width, height: firstFrame.height)
            }

            for i in 0..<framesCount {
                let delay = getGIFFrameDuration(imgSource: imageSource, index: i)
                frameDurations.append(delay)
                duration += delay
            }
        }
        
        func getFrame(at index: Int) -> CGImage? {
            if index >= framesCount {
                return nil
            }
            let frame = CGImageSourceCreateImageAtIndex(imageSource, index, nil)
            return frame
        }
        
        private func getGIFFrameDuration(imgSource: CGImageSource, index: Int) -> TimeInterval {
            guard let frameProperties = CGImageSourceCopyPropertiesAtIndex(imgSource, index, nil) as? [AnyHashable: Any],
                let gifProperties = frameProperties[kCGImagePropertyGIFDictionary] as? NSDictionary,
                let unclampedDelay = gifProperties[kCGImagePropertyGIFUnclampedDelayTime] as? TimeInterval
                else { return 0.02 }
            
            var frameDuration = TimeInterval(0)
            
            if unclampedDelay < 0 {
                frameDuration = gifProperties[kCGImagePropertyGIFDelayTime] as? TimeInterval ?? 0.0
            } else {
                frameDuration = unclampedDelay
            }
            
            /* Implement as Browsers do: Supports frame delays as low as 0.02 s, with anything below that being rounded up to 0.10 s.
             http://nullsleep.tumblr.com/post/16524517190/animated-gif-minimum-frame-delay-browser-compatibility */
            
            if (frameDuration < frameDelayThreshold - Double.ulpOfOne) {
                frameDuration = 0.1;
            }
            
            return frameDuration
        }
    }
}
