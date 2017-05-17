//
//  Created by Pavel Sharanda on 17.05.17.
//  Copyright © 2017 Jetpack. All rights reserved.
//

import Foundation

extension Observer where T == Void {
    public static func repeated(timeInterval: TimeInterval) -> Observer<Void> {
        return Observer<Void> { observer in
            let timerOwner = TimerOwner(observer: observer)
            let timer = Timer.scheduledTimer(timeInterval: timeInterval, target: timerOwner, selector: #selector(TimerOwner.handleTimer), userInfo: nil, repeats: true)
            return TimerDisposable(timer: timer)
        }
    }
}

private class TimerOwner: NSObject {
    let observer: ()->Void
    init(observer: @escaping ()->Void) {
        self.observer = observer
    }
    
    @objc func handleTimer() {
        observer()
    }
}

private class TimerDisposable: Disposable {
    weak var timer: Timer?
    
    init(timer: Timer) {
        self.timer = timer
    }
    
    func dispose() {
        timer?.invalidate()
        timer = nil
    }
}
