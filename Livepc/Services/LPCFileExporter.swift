//
//  LPCFileExporter.swift
//  Livepc
//
//  Created by Dmytro Platov on 1/13/19.
//  Copyright © 2019 Dmytro Platov. All rights reserved.
//

import UIKit
import RxSwift
import AVFoundation

enum LPCFileExporterError: Error {
    case ExportError
}

class LPCFileExporter {
//DI
    var pathBuilder = LPCPathBuilder()
    var parametersExtractor = LPCVideoParametersExtractor()
    
    func export(_ file: LCPSourceFile) -> Observable<LPCProcessingStatus<LPCVideoFile>> {
        
        let progressSubject = BehaviorSubject<Float>(value: 0)
        let progressStream = progressSubject.map { LPCProcessingStatus<LPCVideoFile>.processing($0) }.observeOn(MainScheduler())
        
        let resultStream = Observable<LCPSourceFile>.from([file])
            .observeOn(SerialDispatchQueueScheduler(internalSerialQueueName: "export"))
            .map({ [weak self] (source) -> LPCVideoFile in
                
                guard let self = self
                    , let destinationURL = self.pathBuilder.tempURL("\(UUID().uuidString).MOV")
                    else {
                        throw LPCFileExporterError.ExportError
                }
                
                switch source.type {
                case .video:
                    
                    progressSubject.onNext(1.0)
                    
                    let videoParameters = try self.parametersExtractor.parameters(for: source.url)
                    let file = LPCVideoFile(source: source, url: source.url, parameters: videoParameters)
                    
                    return file
                case .gif:
                    
                    guard let converter = LPCGIFConverter(url: source.url) else {
                        throw LPCFileExporterError.ExportError
                    }
                    converter.progressFunction = { progressSubject.onNext($0) }
                    try converter.convert(to: destinationURL)
                    
                    let videoParameters = LCPVideoFileParameters(resolution: converter.videoSize,
                                                                 fps: Float(converter.gif.duration/TimeInterval(converter.gif.framesCount)),
                                                                 isContainAudio: false,
                                                                 duration: converter.gif.duration)
                    let file = LPCVideoFile(source: source, url: destinationURL, parameters: videoParameters)
                    
                    return file
                case .livePhoto( _, let size):
                    
                    guard let converter = LPCLivePhotoConverter(url: source.url) else {
                        throw LPCFileExporterError.ExportError
                    }
                    converter.progressFunction = { progressSubject.onNext($0) }
                    
                    var source = source
                    let extractedPreview = try converter.convert(to: destinationURL)
                    
                    if extractedPreview != nil {
                        source.type = .livePhoto(extractedPreview, size)
                    }
                    
                    var videoParameters = try self.parametersExtractor.parameters(for: destinationURL)
                    videoParameters.resolution = size
                    
                    let file = LPCVideoFile(source: source, url: destinationURL, parameters: videoParameters)
                    return file
                }
            })
            .observeOn(MainScheduler())
            .map {  LPCProcessingStatus<LPCVideoFile>.finished($0) }
        
        
        return Observable<LPCProcessingStatus<LPCVideoFile>>.merge([progressStream, resultStream])
    }
}
