

import Foundation
import XCTest

import SimpleViewModel

/// Provides API for view to interact with its respective `ViewModel`
///
/// The tester does NOT provide facilities to filter or debounce signals.
public class TestViewModelInterface<T: ViewModel> {
    private let viewModel: T

    private var outputs: [T.Output] = []

    public init(viewModel: T) {
        self.viewModel = viewModel

        viewModel.first { [weak self] output in
            self?.respond(output)
        }
    }

    public func send(_ input: T.Input, file: StaticString = #file, line: UInt = #line) -> Self {
        guard outputs.isEmpty else {
            XCTAssert(false, "Untested outputs encountered from previous `send`", file: file, line: line)
            return self
        }
        do {
            try viewModel.accept(input) { [weak self] output in
                self?.respond(output)
            }
        }
        catch {
            viewModel.thrownError(error) { [weak self] output in
                self?.respond(output)
            }
        }
        return self
    }
    
    /// Expect `[Output]` from a given `send` action.
    ///
    /// If multiple `Output`s are expected, they _must_ be performed at the same time within the same thread.
    public func expect(_ expected: [T.Output], wait seconds: TimeInterval = 2, file: StaticString = #file, line: UInt = #line) {
        let waiter = TestWaiter(description: "Outputs are equal")
        waiter.wait(seconds: seconds, file: file, line: line) { [weak self] in
            !(self?.outputs.isEmpty ?? false)
        }
        XCTAssertEqual(expected, outputs, file: file, line: line)
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
