/// Copyright ⓒ 2023 Bithead LLC. All rights reserved.

import PromiseKit
import Swinject
import XCTest

@testable import SimpleViewModel

// MARK: - Models

// MARK: View Model

struct ProductSearch: Equatable {
    let term: String
    let products: [Int]
}

struct FooViewModel: ViewModel {
    enum Input {
        case didTapButton
        case didSearch(String)
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
    
    func filter() -> [Input] {
        [.didTapButton]
    }
    
    func debounce() -> [(Input, TimeInterval)] {
        [(.didSearch(""), 0.3)]
    }
    
    func first(respond: (Output) -> Void) {
        respond(.state(.init(id: "5", name: "Foo")))
    }

    func accept(_ input: Input, respond: @escaping (Output) -> Void) {
        switch input {
        case .didTapButton:
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
        XCTAssertEqual(calledTimes, 1)
        
        // describe: finish the `Input`'s operation
        pending.resolver.fulfill(.init(id: "1", name: "Name", price: .single(.regular(10)), skus: []))
        TestWaiter().wait(for: { !outputs.isEmpty })
        vm.send(.didTapButton)
        
        // it: should allow the button to be tapped again
        XCTAssertEqual(calledTimes, 2)
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
        TestWaiter().wait(for: 0.5)
        
        // it: should debounce search requests
        // First: is the initial output, Second is the Output from `didSearch`
        XCTAssertEqual(outputs.count, 2)
        XCTAssertEqual(FooViewModel.Output.products(.init(term: "Chan", products: [1, 2, 3])), outputs[safe: 1])
    }
    
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
}
