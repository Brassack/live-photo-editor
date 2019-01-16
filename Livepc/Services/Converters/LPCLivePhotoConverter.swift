//
//  LPCLivePhotoConverter.swift
//  Livepc
//
//  Created by Dmytro Platov on 1/15/19.
//  Copyright © 2019 Dmytro Platov. All rights reserved.
//

import UIKit
import Photos
import MobileCoreServices

class LPCLivePhotoConverter {

    private(set) var livePhoto: PHLivePhoto
    var progressFunction: ((Float) -> Void)?

    init?(url: URL) {
        guard let livePhoto = NSKeyedUnarchiver.unarchiveObject(withFile: url.path) as? PHLivePhoto else { return nil }
        self.livePhoto = livePhoto
    }
    
    func convert(to url :URL) throws -> UIImage? {

        var preview: UIImage?
        var resultError: Error?
        
        let group = DispatchGroup()
        
        let assetResources = PHAssetResource.assetResources(for: livePhoto)
        for resource in assetResources {
            
            if resource.type == .pairedVideo ||
                resource.type == .fullSizePairedVideo {
                
                let options = PHAssetResourceRequestOptions()
                options.progressHandler = { [weak self] (progress) in
                    self?.progressFunction?(Float(progress))
                }
                
                group.enter()
                PHAssetResourceManager.default().writeData(for: resource, toFile: url, options: options) { (error) in
                    resultError = error
                    group.leave()
                }
            }else if resource.type == .photo {
                
                group.enter()
                PHAssetResourceManager.default().requestData(for: resource, options: nil, dataReceivedHandler: { (data) in
                    preview = UIImage(data: data)
                }, completionHandler: { (error) in
                    resultError = error
                    group.leave()
                })
            }
        }
        
        group.wait()
        if let error = resultError {
            throw error
        }
        
        return preview
    }
}
