/// Copyright ⓒ 2023 Bithead LLC. All rights reserved.

import XCTest

@testable import SimpleViewModel

struct FooViewModel: ViewModel {
    enum Input {
        case didTapButton
    }

    enum Output: Equatable {
        case state(State)
    }

    struct State: Equatable {
        let id: String
        let name: String
    }

    func first(respond: (Output) -> Void) {
        respond(.state(.init(id: "5", name: "Foo")))
    }

    func accept(_ input: Input, respond: @escaping (Output) -> Void) {
        switch input {
        case .didTapButton:
            respond(.state(.init(id: "10", name: "Bar")))
        }
    }
}

final class SimpleViewModelTests: XCTestCase {

    override func setUpWithError() throws { }

    override func tearDownWithError() throws { }

    func testViewModel() throws {
        let tester = TestViewModelInterface(viewModel: FooViewModel())

        tester.expect([
            .state(.init(id: "5", name: "Foo"))
        ])

        // TODO: Perform network request

        tester.send(.didTapButton).expect([
            .state(.init(id: "10", name: "Bar"))
        ])

        // This isn't entirely necessary. If the value from the `send` function is unused, a compiler warning will show, making it immediately obvious that it is missing an expectation.
        tester.finish()
    }
}
