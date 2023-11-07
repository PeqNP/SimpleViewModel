/// Copyright ⓒ 2023 Bithead LLC. All rights reserved.

import Foundation
import XCTest

@testable import SimpleViewModel

/// Provides API for view to interact with its respective `ViewModel`
class TestViewModelInterface<T: ViewModel> {
    let viewModel: T

    var outputs: [T.Output] = []

    init(viewModel: T) {
        self.viewModel = viewModel

        viewModel.first(respond: respond)
    }

    func send(_ input: T.Input, file: StaticString = #file, line: UInt = #line) -> Self {
        guard outputs.isEmpty else {
            XCTAssert(false, "Untested outputs encountered from previous `send`", file: file, line: line)
            return self
        }
        viewModel.accept(input, respond: respond)
        return self
    }
    
    /// Expect `[Output]` from a given `send` action.
    ///
    /// If multiple `Output`s are expected, they _must_ be performed at the same time within the same thread.
    func expect(_ expected: [T.Output], wait seconds: TimeInterval = 2, file: StaticString = #file, line: UInt = #line) {
        let waiter = XCTWaiter()
        let expectation = XCTestExpectation(description: "Outputs are equal")
        waitForOutputs(expectation, wait: seconds)
        let result = waiter.wait(for: [expectation], timeout: seconds)
        switch result {
        case .completed:
            XCTAssertEqual(expected, outputs, file: file, line: line)
        case .timedOut:
            XCTFail("Expected Outputs, but none were returned")
        default:
            XCTFail("Invalid result returned from `wait` - \(result)", file: file, line: line)
        }
        outputs = []
    }
    
    private func waitForOutputs(_ expectation: XCTestExpectation, wait seconds: TimeInterval, iteration: Double = 0) {
        let iterationsPerSecond: Double = 10
        // `2` ensures this finishes before `waiter.wait` finishes in `expect`
        guard iteration < (iterationsPerSecond * seconds) - 1 else {
            return
        }
        // No need to wait 100 milliseconds on the first iteration. This is especially true if the expectation has no async calls.
        let interval: DispatchTimeInterval = iteration == 0 ? .seconds(0) : .milliseconds(100)
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) { [weak self] in
            guard let self else {
                expectation.fulfill()
                return
            }
            if !self.outputs.isEmpty {
                expectation.fulfill()
            }
            else {
                self.waitForOutputs(expectation, wait: seconds, iteration: iteration + 1)
            }
        }
    }

    private func respond(_ output: T.Output) {
        outputs.append(output)
    }

    func finish(file: StaticString = #file, line: UInt = #line) {
        if !outputs.isEmpty {
            XCTAssert(false, "Untested outputs remaining at end of test. Call `expect` on previous `send`.", file: file, line: line)
        }
    }
}
