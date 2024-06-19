/// Copyright ⓒ 2023 Bithead LLC. All rights reserved.

import PromiseKit
import Swinject
import XCTest

@testable import SimpleViewModel

// MARK: - Models

// MARK: View Model

private struct ProductSearch: Equatable {
    let term: String
    let products: [Int]
}

/// This is designed to test filtering specific inputs and the debounce logic
private struct FooViewModel: ViewModel {
    enum Input {
        case didTapButton
        case didTapOtherButton
        case didSearch(String)
    }

    enum Output: Equatable {
        case state(State)
        case products(ProductSearch)
        case showError(String)
        case showProgress(current: Double)
    }

    struct State: Equatable {
        let id: String
        let name: String
    }

    @Dependency var product: ProductService!
    
    func filter() -> [Input] {
        [.didTapButton]
    }

    func filterAllInputs() -> [Input] {
        [.didTapOtherButton]
    }

    func debounce() -> [Debounce<Input>] {
        [.init(input: .didSearch(""), interval: 0.3)]
    }

    /// The `showProgress` `Output` will not put the `Input` operation in a "finished" state. This prevents other `Input`s from being accepted.
    func filterOutputs() -> [Output] {
        [.showProgress(current: 0)]
    }

    func first(respond: (Output) -> Void) {
        respond(.state(.init(id: "5", name: "Foo")))
    }

    func accept(_ input: Input, respond: @escaping (Output) -> Void) {
        switch input {
        case .didTapButton,
             .didTapOtherButton:
            product.product(for: "10")
                .done { product in
                    respond(.state(.init(id: product.id, name: product.name)))
                }
                .catch { error in
                    respond(.showError(error.localizedDescription))
                }
        case let .didSearch(term):
            respond(.products(.init(term: term, products: [1, 2, 3])))
        }
    }
}

/// This shows how to filter `Output`s to prevent `Input` operations from being prematurely considered "finished."
private struct OutputTestViewModel: ViewModel {
    enum Input {
        case didTapButton
    }

    enum Output: Equatable {
        case state(State)
        case showProgress(current: Double)
    }

    struct State: Equatable {
        let id: String
        let name: String
    }

    @Dependency var product: ProductService!

    /// Button taps are filtered until the first `Input` operation has "finished"
    func filter() -> [Input] {
        [.didTapButton]
    }

    /// The `showProgress` `Output` will not put the `Input` operation in a "finished" state. This prevents other `Input`s from being accepted.
    func filterOutputs() -> [Output] {
        [.showProgress(current: 0)]
    }

    func accept(_ input: Input, respond: @escaping (Output) -> Void) {
        switch input {
        case .didTapButton:
            respond(.showProgress(current: 0.1))
            product.product(for: "10")
                .done { product in
                    respond(.state(.init(id: product.id, name: product.name)))
                }
                .catch { _ in
                    // Ignoring as catching an error is out of scope for this example
                }
        }
    }
}

private enum FakeError: Error, Equatable {
    case testError
}

///  This is designed to test filtering all `Input`s, regardless of which `Input` is sent
private struct BarViewModel: ViewModel {
    enum Input {
        case didTapButton
        case didTapOtherButton
        case didSearch(String)
        case didTapEditButton
    }

    enum Output: Equatable {
        case state(State)
        case products(ProductSearch)
        case showError(String)
    }

    struct State: Equatable {
        let id: String
        let name: String
    }

    @Dependency var product: ProductService!

    func filterAll() -> Bool {
        true
    }

    func first(respond: (Output) -> Void) {
        respond(.state(.init(id: "5", name: "Foo")))
    }

    func thrownError(_ error: any Error, respond: RespondCallback) {
        respond(.showError(String(describing: error)))
    }

    func accept(_ input: Input, respond: @escaping (Output) -> Void) throws {
        switch input {
        case .didTapButton,
             .didTapOtherButton:
            product.product(for: "10")
                .done { product in
                    respond(.state(.init(id: product.id, name: product.name)))
                }
                .catch { error in
                    respond(.showError(error.localizedDescription))
                }
        case let .didSearch(term):
            respond(.products(.init(term: term, products: [1, 2, 3])))
        case .didTapEditButton:
            throw FakeError.testError
        }
    }
}

// MARK: - Tests

class SimpleTestCase: XCTestCase {
    var assembly: SimpleViewModel.Assembly!
    var container: Container!
    
    override func setUp() {
        // Required for dependency injection
        // This should be done in global `XCTestCase`
        assembly = .init()
        container = assembly.container
        setContainer(container)
    }
    
    override func tearDown() {
        setContainer(nil)
        container = nil
        assembly = nil
    }
}

final class SimpleViewModelTests: SimpleTestCase {

    override func setUpWithError() throws { }

    override func tearDownWithError() throws { }

    func testViewModel_first() throws {
        var outputs = [FooViewModel.Output]()
        _ = ViewModelInterface(viewModel: FooViewModel(), receive: { output in
            outputs.append(output)
        })

        let expected: [FooViewModel.Output] = [
            .state(.init(id: "5", name: "Foo"))
        ]
        XCTAssertEqual(expected, outputs)
    }

    func testViewModel_filter() throws {
        var calledTimes = 0
        let product = container.force(ProductService.self)
        let pending = Promise<Product>.pending()

        product.product = { id in
            calledTimes += 1
            return pending.promise
        }

        var outputs = [FooViewModel.Output]()
        let vm = ViewModelInterface(viewModel: FooViewModel(), receive: { output in
            outputs.append(output)
        })
        
        // describe: filter button taps
        vm.send(.didTapButton)
        vm.send(.didTapButton)
        
        // it: should filter the `Input`
        TestWaiter.wait(for: { calledTimes == 1 })
        
        // describe: finish the `Input`'s operation
        pending.resolver.fulfill(.init(id: "1", name: "Name", price: .single(.regular(10)), skus: []))
        TestWaiter.wait(for: { outputs.count == 2 })
        vm.send(.didTapButton)
        
        // it: should allow the button to be tapped again
        TestWaiter.wait(for: { calledTimes == 2 })
    }

    func testViewModel_filterAllInputs() throws {
        var calledTimes = 0
        let product = container.force(ProductService.self)
        let pending = Promise<Product>.pending()

        product.product = { id in
            calledTimes += 1
            return pending.promise
        }

        var outputs = [FooViewModel.Output]()
        let vm = ViewModelInterface(viewModel: FooViewModel(), receive: { output in
            outputs.append(output)
        })

        // describe: filter all signals
        vm.send(.didTapOtherButton)
        vm.send(.didTapButton)
        vm.send(.didSearch("term"))
        vm.send(.didTapButton)

        // it: should only call service once
        TestWaiter.wait(for: { calledTimes == 1 })
        // it: should filter all `Input`s
        TestWaiter.wait(for: { outputs.count == 1 })

        // describe: finish the `Input`'s operation
        pending.resolver.fulfill(.init(id: "1", name: "Name", price: .single(.regular(10)), skus: []))
        TestWaiter.wait(for: { outputs.count == 2 })
        vm.send(.didTapOtherButton)

        // it: should allow the button to be tapped again
        TestWaiter.wait(for: { calledTimes == 2 })
    }

    func testViewModel_filterAll() throws {
        var calledTimes = 0
        let product = container.force(ProductService.self)
        let pending = Promise<Product>.pending()

        product.product = { id in
            calledTimes += 1
            return pending.promise
        }

        var outputs = [BarViewModel.Output]()
        let vm = ViewModelInterface(viewModel: BarViewModel(), receive: { output in
            outputs.append(output)
        })

        // describe: filter all signals
        vm.send(.didTapOtherButton)
        vm.send(.didTapButton)
        vm.send(.didSearch("term"))
        vm.send(.didTapButton)

        // it: should only call service once
        TestWaiter.wait(for: { calledTimes == 1 })
        // it: should filter all `Input`s
        TestWaiter.wait(for: { outputs.count == 1 })

        // describe: finish the `Input`'s operation
        pending.resolver.fulfill(.init(id: "1", name: "Name", price: .single(.regular(10)), skus: []))
        TestWaiter.wait(for: { outputs.count == 2 })
        vm.send(.didTapOtherButton)

        // it: should allow the button to be tapped again
        TestWaiter.wait(for: { calledTimes == 2 })
    }

    func testViewModel_thrownError() throws {
        var outputs = [BarViewModel.Output]()
        let vm = ViewModelInterface(viewModel: BarViewModel(), receive: { output in
            outputs.append(output)
        })

        vm.send(.didTapEditButton)
        TestWaiter.wait(for: { outputs.count == 2 })
        TestWaiter.wait(for: {
            outputs[safe: 1] == BarViewModel.Output.showError(String(describing: FakeError.testError))
        })
    }

    func testViewModel_debounce() throws {
        var outputs = [FooViewModel.Output]()
        let vm = ViewModelInterface(viewModel: FooViewModel(), receive: { output in
            outputs.append(output)
        })
        
        // describe: searching for `Chanel`
        vm.send(.didSearch("C"))
        vm.send(.didSearch("Ch"))
        vm.send(.didSearch("Cha"))
        vm.send(.didSearch("Chan"))

        // Wait 500ms before continuing
        TestWaiter.wait(for: 0.5)
        
        // it: should debounce search requests
        // First: is the initial output, Second is the Output from `didSearch`
        XCTAssertEqual(outputs.count, 2)
        XCTAssertEqual(FooViewModel.Output.products(.init(term: "Chan", products: [1, 2, 3])), outputs[safe: 1])
    }
    
    /// This shows you how to use the `TestViewModelInterface` which provides a convenient way to perform expectations directly after `send` actions.
    /// This has not been thoroughly tested using the `async` pattern.
    func testFooViewModel() throws {
        let tester = TestViewModelInterface(viewModel: FooViewModel())

        tester.expect([
            .state(.init(id: "5", name: "Foo"))
        ])
        
        let product = container.force(ProductService.self)
        product.product = { id in
            .value(.init(id: id, name: "Name", price: .single(.regular(10)), skus: []))
        }

        tester.send(.didTapButton).expect([
            .state(.init(id: "10", name: "Name"))
        ])

        // This isn't necessary. If the value from the `send` function is unused, a compiler warning will show, making it immediately obvious that it is missing an expectation.
        tester.finish()
    }

    func testFilterOutputs() throws {
        var calledTimes = 0
        let product = container.force(ProductService.self)
        let pending = Promise<Product>.pending()

        product.product = { id in
            calledTimes += 1
            return pending.promise
        }

        var outputs = [OutputTestViewModel.Output]()
        let vm = ViewModelInterface(viewModel: OutputTestViewModel(), receive: { output in
            outputs.append(output)
        })

        // describe: tap button to load `Product`s
        vm.send(.didTapButton)

        // it: should return progress
        let expected: [OutputTestViewModel.Output] = [
            .showProgress(current: 0.1)
        ]
        TestWaiter.wait(for: { outputs == expected })
        XCTAssertEqual(calledTimes, 1)

        // describe: send another button tap
        vm.send(.didTapButton)

        // it: should not send another progress update
        // Because the last `Output` is ignored, the first `didTapButton` is still in progress
        TestWaiter.wait(for: { outputs == expected })
        XCTAssertEqual(calledTimes, 1)
    }
}
