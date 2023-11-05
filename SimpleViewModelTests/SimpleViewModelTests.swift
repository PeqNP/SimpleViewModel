/// Copyright ⓒ 2023 Bithead LLC. All rights reserved.

import XCTest

@testable import SimpleViewModel

final class SimpleViewModelTests: XCTestCase {

    override func setUpWithError() throws { }

    override func tearDownWithError() throws { }

    func testViewModel() throws {
        /**
         I would like something as the following:
         
         // This will initialize the tester and also ensure that `first` signals are accounted for.
         // If no expectations are provided, they are still checked against, and the test will fail immediately if the `first` logic is not tested against.
         let tester = TestViewModelInterface(viewModel: MyViewModel(), expect: [
            .viewState(SomeViewState())
         ])
         
         // TODO: Stub a network request
         // If a network request is not stubbed, the test should fail immediately with an error saying that the function is not stubbed.
         
         tester.send(.didTapLikeButton, expect: [
            .addedToBag(SKU()),
            .analytic(SomeAnalyticEvent())
         ])
         
         Stubbing of network requests still needs to be figured out. If it's possible to replace the real instance's function, that might work. No network requests should ever be made at test time though.
         */
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }
}
