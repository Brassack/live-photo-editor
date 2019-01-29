//
//  LPCHomeViewController.swift
//  Livepc
//
//  Created by Dmytro Platov on 12/1/18.
//  Copyright © 2018 Dmytro Platov. All rights reserved.
//

import UIKit
import MobileCoreServices
import Photos
import RxSwift
import RxCocoa

class LPCHomeViewController: UIViewController, UINavigationControllerDelegate {
//DI
    var model = LPCHomeViewModel()
    var pathBuilder = LPCPathBuilder()
    var typeDetector = LPCFileTypeDetector()
    var errorPresenter = LPCErrorPresenter()
    
// Outlets
    @IBOutlet weak var openButton: LPCTitleButton!
    @IBOutlet weak var aboutButton: UIButton!
    
//Private
    private let disposeBag = DisposeBag()

//Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        bindModel()
        bindActions()
    }
    
    func bindActions() {
        //openButton is custom UIControl so use storyboard actions
        aboutButton.rx.tap.bind { [weak self] in
            self?.about()
        }.disposed(by: disposeBag)
    }
    
    func bindModel(){
        
        model.videoProcessingStatus.subscribe(onNext: { [weak self] in
            guard let self = self else { return }

            switch $0 {
            case .notProcessing:
                
                self.aboutButton.isUserInteractionEnabled = true
                self.openButton.isUserInteractionEnabled = true
                self.openButton.title = "Open"
            case .processing(let progress):
                
                self.aboutButton.isUserInteractionEnabled = false
                self.openButton.isUserInteractionEnabled = false
                self.openButton.title = "\(Int(100*progress))%"
            case .finished(let video):
                
                self.aboutButton.isUserInteractionEnabled = true
                self.openButton.isUserInteractionEnabled = true
                self.openButton.title = "Open"
                if let vc = self.storyboard?.instantiateViewController(withIdentifier: String(describing: LPCEditVideoViewController.self)) as? LPCEditVideoViewController {
                    vc.model.videoFile.onNext(video)
                    self.present(vc, animated: true, completion: nil)
                }
            }
        }, onError: { [weak self] (error) in
            
            if let self = self {
                self.aboutButton.isUserInteractionEnabled = true
                self.openButton.isUserInteractionEnabled = true
                self.openButton.title = "Open"
                self.errorPresenter.showError(error.localizedDescription, in: self)
            }
            print("Error ", error)
        }).disposed(by: disposeBag)
    }
    
    // MARK: User actions
    func about(){
        print("About tapped")
    }
    
    @IBAction func openDocument(_ sender: Any) {
        let mediaTypes = [kUTTypeMovie, kUTTypeGIF, kUTTypeImage] as [String] //kUTTypeLivePhoto
        let picker = UIDocumentPickerViewController(documentTypes: mediaTypes, in: .import)
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    
    @IBAction func openCameraRoll(_ sender: Any) {

        weak var wself = self
        func openCameraRoll() {
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = wself
                imagePicker.sourceType = .photoLibrary;
                imagePicker.allowsEditing = false
                imagePicker.mediaTypes = [kUTTypeMovie, kUTTypeLivePhoto, kUTTypeImage] as [String]//kUTTypeGIF
                wself?.present(imagePicker, animated: true, completion: nil)
            }
        }
        
        let status = PHPhotoLibrary.authorizationStatus()
        
        if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization( { status in
                if status == .authorized {
                    openCameraRoll()
                }
            })
        }else if status != .authorized {
            // TODO: open setting
        }else{
            openCameraRoll()
        }
    }
}

//MARK: UIDocumentPickerDelegate
extension LPCHomeViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        //kUTTypeLivePhoto
        if typeDetector.url(url, conformToType: kUTTypeMovie) {//Video
            
            model.sourceFile.onNext(LCPSourceFile(type: .video, url: url))
        }else if typeDetector.url(url, conformToType: kUTTypeGIF) {//GIF
            
            model.sourceFile.onNext(LCPSourceFile(type: .gif, url: url))
        }else {
            
            errorPresenter.showError("Unsupported file type", in: self)
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        dismiss(animated: true, completion: nil)
    }
}

//MARK: UIImagePickerControllerDelegate
extension LPCHomeViewController: UIImagePickerControllerDelegate{
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        print("Picked \(info)")
        dismiss(animated: true, completion: nil)
        let type = info[.mediaType] as? UIImagePickerController.InfoKey
        
        let movieType = kUTTypeMovie as String
        let livePhotoType = kUTTypeLivePhoto as String
        let imageType = kUTTypeImage as String
        
        switch type?.rawValue {
        case movieType:
            
            let url = info[.mediaURL] as? URL
            
            model.sourceFile.onNext(LCPSourceFile(type: .video, url: url!))
        case livePhotoType:

            if let livePhoto = info[.livePhoto] as? PHLivePhoto,
                let destinationURL = self.pathBuilder.tempURL("\(UUID().uuidString).livePhoto") {
                //Maybe it's a kind of controversial idea to use file sytem as a buffer
                //But it allow to keep uniformity in video processing
                if NSKeyedArchiver.archiveRootObject(livePhoto, toFile: destinationURL.path) {
                    
                    let cover: UIImage? = {
                        guard let path = (info[.imageURL] as? URL)?.path else {
                            return nil
                        }
                       return UIImage(contentsOfFile: path)
                    }()
                    
                    model.sourceFile.onNext(LCPSourceFile(type: .livePhoto(cover, livePhoto.size), url: destinationURL))
                }else{
                    errorPresenter.showError(in: self)
                }
            }
        case imageType:
            
            if let asset = info[.phAsset] as? PHAsset,
                let url = info[.imageURL] as? URL,
                let imageType = asset.value(forKey: "uniformTypeIdentifier") as? String,
                imageType == kUTTypeGIF as String {
                
                model.sourceFile.onNext(LCPSourceFile(type: .gif, url: url))
            }else{
                errorPresenter.showError("Currently app support only animated image", in: self)
            }
        default:
            errorPresenter.showError(in: self)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController){
        dismiss(animated: true, completion: nil)
    }
}
