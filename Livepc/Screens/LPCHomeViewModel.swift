//
//  LPCHomeViewModel.swift
//  Livepc
//
//  Created by Dmytro Platov on 12/12/18.
//  Copyright © 2018 Dmytro Platov. All rights reserved.
//

import RxSwift
import RxCocoa
import RxOptional

class LPCHomeViewModel {
    
    //DI
    var exporter = LPCFileExporter()

    //Private stuff
    private let disposeBag = DisposeBag()
    
    //Files
    let sourceFile = BehaviorSubject<LCPSourceFile?>(value: nil)//Variable deprecated https://github.com/ReactiveX/RxSwift/issues/1501
    private(set) var videoProcessingStatus = Observable<LPCProcessingStatus<LPCVideoFile>>.never()//never() to avoid error using [weak self]
    
    init() {
        //Not using drive bacause want native error processing
        videoProcessingStatus = sourceFile.filterNil().flatMap({ [weak self] (source) -> Observable<LPCProcessingStatus<LPCVideoFile>> in
            guard let self = self else { return Observable<LPCProcessingStatus<LPCVideoFile>>.never() }
            return self.exporter.export(source)
        }).share(replay: 1)
    }
}
