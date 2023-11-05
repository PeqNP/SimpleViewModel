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

    func expect(_ expected: [T.Output], file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(outputs, expected, file: file, line: line)
        outputs = []
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
