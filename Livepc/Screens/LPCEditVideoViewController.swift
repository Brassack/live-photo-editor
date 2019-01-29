//
//  LPCEditVideoViewController.swift
//  Livepc
//
//  Created by Dmytro Platov on 12/1/18.
//  Copyright © 2018 Dmytro Platov. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import ABVideoRangeSlider
import RxSwift
import RxCocoa
import RxOptional

class LPCEditVideoViewController: UIViewController {
//DI
    var model = LPCEditVideoViewModel()
    var errorPresenter = LPCErrorPresenter()
//Private
    private let disposeBag = DisposeBag()

//MARK: Outlets
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var startTimeTextField: LPCUnderlineTextField!
    @IBOutlet weak var endTimeTextField: LPCUnderlineTextField!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var videoContrainer: UIView!
    @IBOutlet var videoRangeSlider: ABVideoRangeSlider!
    
    let avPlayerController = AVPlayerViewController()

    override func viewDidLoad() {
        super.viewDidLoad()

        avPlayerController.showsPlaybackControls = false
        videoContrainer.addSubview(avPlayerController.view)
        
        if let text = infoLabel.text {
            model.infoFormatText.onNext(text)
        }
        
        bindModel()
        bindActions()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        avPlayerController.view.frame = videoContrainer.bounds
    }
    
    func bindModel(){
        //Video file
        model.videoFile.filterNil().subscribe(onNext: { [weak self] (file) in
            guard let self = self else { return }

            if let infoFormatText = try? self.model.infoFormatText.value() {
                self.infoLabel.text = infoFormatText.replacingOccurrences(of: "%x", with: String(file.parameters.duration.roundedToSignificant))
            }
            
            self.setupRangeSlider(with: file.url)
            self.avPlayerController.player = AVPlayer(url: file.url)
            let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            self.avPlayerController.player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
                
                guard let self = self, (try! self.model.isPlaying.value()) else { return }
                let currentSeconds = CMTimeGetSeconds(time)
                self.videoRangeSlider.updateProgressIndicator(seconds: Float64(currentSeconds))
            }
        }, onError: {[weak self] (error) in
            if let self = self {
                self.errorPresenter.showError(in: self)
            }
        }).disposed(by: disposeBag)
        
        //start
        model.startTimeInputText.bind(to: startTimeTextField.rx.text).disposed(by: disposeBag)
        startTimeTextField.rx.text.bind(to: model.startTimeInputText).disposed(by: disposeBag)
        startTimeTextField.rx.controlEvent(.editingDidEnd).bind(to: model.startValidationEventStream).disposed(by: disposeBag)
        model.isValidStartTimeText.map { $0 ? UIColor.white : UIColor.red }.bind(to: startTimeTextField.rx.underlineColor).disposed(by: disposeBag)
        
        model.startTime.subscribe(onNext: { [weak self] (time) in
            guard let self = self, let player = self.avPlayerController.player else {
                return
            }
            
            player.pause()
            self.model.isPlaying.onNext(false)
//            self.isPlaying = false
            self.videoRangeSlider.setStartPosition(seconds: Float(time))
        }).disposed(by: disposeBag)
        
        //End
        model.endTimeInputText.bind(to: endTimeTextField.rx.text).disposed(by: disposeBag)
        endTimeTextField.rx.text.bind(to: model.endTimeInputText).disposed(by: disposeBag)
        endTimeTextField.rx.controlEvent(.editingDidEnd).bind(to: model.endValidationEventStream).disposed(by: disposeBag)
        model.isValidEndTimeText.map { $0 ? UIColor.white : UIColor.red }.bind(to: endTimeTextField.rx.underlineColor).disposed(by: disposeBag)

        model.endTime.subscribe(onNext: { [weak self] (time) in
            guard let self = self, let player = self.avPlayerController.player else {
                return
            }

            player.pause()
            self.model.isPlaying.onNext(false)
//            self.isPlaying = false
            self.videoRangeSlider.setEndPosition(seconds: Float(time))
        }).disposed(by: disposeBag)
    }
    
    func bindActions(){
        backButton.rx.tap.bind { [weak self] in
            self?.back()
        }.disposed(by: disposeBag)
    }
    
    
    func setupRangeSlider(with url: URL) {
        videoRangeSlider.setVideoURL(videoURL: url)
        videoRangeSlider.delegate = self
        videoRangeSlider.startTimeView.isHidden = true
        videoRangeSlider.endTimeView.isHidden = true
        videoRangeSlider.minSpace = Float(1/60)
    }
    
    // MARK: User actions
    func back(){
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func play(_ sender: Any) {

        let isPlaying = try! model.isPlaying.value()
        
        if isPlaying {
            avPlayerController.player?.pause()
        }else{
            avPlayerController.player?.play()
        }
        model.isPlaying.onNext(!isPlaying)
    }
}

//MARK: ABVideoRangeSliderDelegate
extension LPCEditVideoViewController: ABVideoRangeSliderDelegate {
    
    func didChangeValue(videoRangeSlider: ABVideoRangeSlider, startTime: Float64, endTime: Float64) {
        
        guard let player = avPlayerController.player else { return }
        
        player.pause()
        model.isPlaying.onNext(false)
        model.startTime.onNext(startTime.roundedToSignificant)
        model.endTime.onNext(endTime.roundedToSignificant)
    }
    
    func indicatorDidChangePosition(videoRangeSlider: ABVideoRangeSlider, position: Float64) {
        
        guard let player = avPlayerController.player, let timescale = player.currentItem?.asset.duration.timescale else {
            return
        }
        
        player.pause()
        model.isPlaying.onNext(false)
        
        let time = CMTime(seconds: Double(position), preferredTimescale: timescale)
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { (finished) in }
    }
}
