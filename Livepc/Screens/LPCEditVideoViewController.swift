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

class LPCEditVideoViewController: UIViewController {
    //MARK: Outlets
    @IBOutlet weak var backButton: UIButton!
    
    //Private
    private let disposeBag = DisposeBag()
    
    var _video: LPCVideoFile!
    @IBOutlet var videoRangeSlider: ABVideoRangeSlider!
//    lazy var videoURL = Bundle.main.url(forResource: "video", withExtension: "mov")!
    lazy var video = AVAsset.init(url: _video.url)
    lazy var avPlayer = AVPlayer(url: _video.url)
    let avPlayerController = AVPlayerViewController()
    @IBOutlet weak var videoContrainer: UIView!
    
    var isPlaying = false

    override func viewDidLoad() {
        super.viewDidLoad()
        videoRangeSlider.setVideoURL(videoURL: _video.url)
        videoRangeSlider.setStartPosition(seconds: 0.0)
        videoRangeSlider.setEndPosition(seconds: 1.0)
        videoRangeSlider.delegate = self
        videoRangeSlider.startTimeView.isHidden = true
        videoRangeSlider.endTimeView.isHidden = true
        videoRangeSlider.minSpace = Float(1/60)
        avPlayerController.player = avPlayer

        avPlayerController.showsPlaybackControls = false
        videoContrainer.addSubview(avPlayerController.view)
        
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
//        videoRangeSlider?.progressIndicator
        avPlayerController.player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self, self.isPlaying else {
                return
            }
            
            let currentSeconds = CMTimeGetSeconds(time)
            guard let duration = self.avPlayer.currentItem?.duration else { return }
            let totalSeconds = CMTimeGetSeconds(duration)
            let progress: Float = Float(currentSeconds/totalSeconds)
            print(progress)
            self.videoRangeSlider.updateProgressIndicator(seconds: Float64(currentSeconds))
        }
        bindActions()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        avPlayerController.view.frame = videoContrainer.bounds
    }
    
    func bindActions(){
        backButton.rx.tap.bind { [weak self] in
            self?.back()
        }.disposed(by: disposeBag)
    }
    
    func back(){
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func play(_ sender: Any) {
//        avPlayerController.player?.rate = -1.0
//        return;
        if isPlaying {
            avPlayerController.player?.pause()
        }else{
            avPlayerController.player?.play()
        }
        isPlaying = !isPlaying
    }
}

//MARK: ABVideoRangeSliderDelegate
extension LPCEditVideoViewController: ABVideoRangeSliderDelegate {
    func didChangeValue(videoRangeSlider: ABVideoRangeSlider, startTime: Float64, endTime: Float64) {
        print(#function)
        print("start \(startTime), end \(endTime)")
    }
    
    func indicatorDidChangePosition(videoRangeSlider: ABVideoRangeSlider, position: Float64) {
        avPlayerController.player?.pause()
        isPlaying = false
        
        print(#function)
        print("position: ", position)
        let timescale = avPlayer.currentItem!.asset.duration.timescale
        let time = CMTime(seconds: Double(position), preferredTimescale: timescale)
        avPlayer.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { (finished) in
            print("finished: ", finished)
            print(self.avPlayer.currentTime().seconds)
        }
    }
}
