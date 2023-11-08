/// Copyright ⓒ 2022 Bithead LLC. All rights reserved.

import Foundation

public class Debouncer {
    private let interval: TimeInterval
    private var timer: Timer?
    
    public init(interval: TimeInterval) {
        self.interval = interval
    }
    
    public func debounce(block: @escaping () -> ()) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in block() }
    }

    public func cancel() {
        timer?.invalidate()
    }
}
