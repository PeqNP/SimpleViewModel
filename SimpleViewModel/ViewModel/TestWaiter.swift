/// Copyright ⓒ 2023 Bithead LLC. All rights reserved.

import Foundation
import XCTest

public class TestWaiter {
    private let description: String
    private var finished: () -> Bool = { true }
    
    public init(description: String = "") {
        self.description = description
    }
    
    /// Wait N seconds before continuing the test
    public func wait(for seconds: TimeInterval, file: StaticString = #file, line: UInt = #line) {
        let waiter = XCTWaiter()
        let expectation = XCTestExpectation(description: description)
        waiter.wait(for: [expectation], timeout: seconds)
    }
    
    /// Wait N seconds for a condition to be true before failing test
    public func wait(seconds: TimeInterval = 1, file: StaticString = #file, line: UInt = #line, for finished: @escaping () -> Bool) {
        self.finished = finished
        let waiter = XCTWaiter()
        let expectation = XCTestExpectation(description: description)
        poll(expectation, seconds: seconds)
        let result = waiter.wait(for: [expectation], timeout: seconds)
        switch result {
        case .completed:
            return
        case .timedOut:
            XCTFail("Operation timed out for: \(description)", file: file, line: line)
        default:
            XCTFail("Invalid result returned from `wait` - \(result)", file: file, line: line)
        }
    }
    
    private func poll(_ expectation: XCTestExpectation, seconds: TimeInterval, iteration: Double = 0) {
        let iterationsPerSecond: Double = 10
        // `2` ensures this finishes before `waiter.wait` finishes in `expect`
        guard iteration < (iterationsPerSecond * seconds) - 1 else {
            return
        }
        // No need to wait 100 milliseconds on the first iteration. This is especially true if the expectation has no async calls.
        let interval: DispatchTimeInterval = iteration == 0 ? .seconds(0) : .milliseconds(100)
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) { [weak self] in
            guard let self else {
                return
            }
            if self.finished() {
                expectation.fulfill()
            }
            else {
                self.poll(expectation, seconds: seconds, iteration: iteration + 1)
            }
        }
    }
}
