//
//  LPCEditVideoViewModel.swift
//  Livepc
//
//  Created by Dmytro Platov on 12/10/18.
//  Copyright © 2018 Dmytro Platov. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxOptional

class LPCEditVideoViewModel {
    //Private
    private let disposeBag = DisposeBag()
    //Helper
    let infoFormatText = BehaviorSubject<String>(value: String())
    //Video
    let videoFile = BehaviorSubject<LPCVideoFile?>(value: nil)
    let isPlaying = BehaviorSubject<Bool>(value: false)
    //Input
    let startTimeInputText = BehaviorSubject<String?>(value: nil)
    let endTimeInputText = BehaviorSubject<String?>(value: nil)
    //time
    let startTime = BehaviorSubject<Float64>(value: 0)
    let endTime = BehaviorSubject<Float64>(value: 0)
    //Time validation
    var isValidStartTimeText = Observable<Bool>.never()
    var isValidEndTimeText = Observable<Bool>.never()
    
    var startValidationEventStream = PublishRelay<()>()
    var endValidationEventStream = PublishRelay<()>()

    
    init() {
        //video file
        videoFile.filterNil().subscribe(onNext: { [weak self] file in
            guard let self = self else { return }
            self.startTime.onNext(0)
            let endTime = file.parameters.duration > 2 ? 2 : file.parameters.duration
            self.endTime.onNext(endTime)
        }).disposed(by: disposeBag)
        
        //start
        let startTimeStream = startTimeInputText.map { $0 == nil ? nil: Float64($0!) }
        let isEndBiggerOrEquailStart = Observable<Bool>.combineLatest(startTimeStream.filterNil(), endTime, resultSelector: { $1 >= $0 })
        isValidStartTimeText = startTimeStream.withLatestFrom(isEndBiggerOrEquailStart, resultSelector: { $0 != nil && $1 })

        let validStartTime = Observable<Float64>.combineLatest(startTimeStream, startTime, endTime) { startInput, start, end in
            if let startInput = startInput {
                return startInput <= end ? startInput : start
            }else{
                return start
            }
        } .map { $0.roundedToSignificant }
        startValidationEventStream.withLatestFrom(validStartTime) { $1 } .bind(to: startTime).disposed(by: disposeBag)
        startTime.map { String($0) } .bind(to: startTimeInputText).disposed(by: disposeBag)

        //end
        let endTimeStream = endTimeInputText.map { $0 == nil ? nil: Float64($0!) }
        let isStartLowerOrEquailEnd = Observable<Bool>.combineLatest(endTimeStream.filterNil(), startTime, resultSelector: { $0 >= $1 })
        isValidEndTimeText = endTimeStream.withLatestFrom(isStartLowerOrEquailEnd, resultSelector: { $0 != nil && $1 })

        let validEndTime = Observable<Float64>.combineLatest(endTimeStream, endTime, startTime) { endInput, end, start in
            if let endInput = endInput {
                return endInput >= start ? endInput : end
            }else{
                return end
            }
        } .map { $0.roundedToSignificant }
        endValidationEventStream.withLatestFrom(validEndTime) { $1 } .bind(to: endTime).disposed(by: disposeBag)
        endTime.map { String($0) } .bind(to: endTimeInputText).disposed(by: disposeBag)
    }
}
