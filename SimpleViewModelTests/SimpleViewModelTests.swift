/// Copyright ⓒ 2023 Bithead LLC. All rights reserved.

import PromiseKit
import Swinject
import XCTest

@testable import SimpleViewModel

// MARK: - Models

// MARK: View Model

struct FooViewModel: ViewModel {
    enum Input {
        case didTapButton
    }

    enum Output: Equatable {
        case state(State)
        case showError(String)
    }

    struct State: Equatable {
        let id: String
        let name: String
    }

    @Dependency var product: ProductService!
    
    func first(respond: (Output) -> Void) {
        respond(.state(.init(id: "5", name: "Foo")))
    }

    func accept(_ input: Input, respond: @escaping (Output) -> Void) {
        switch input {
        case .didTapButton:
            product.loadFoo(id: "10")
                .done { product in
                    respond(.state(.init(id: product.id, name: product.name)))
                }
                .catch { error in
                    respond(.showError(error.localizedDescription))
                }
        }
    }
}

struct Foo {
    let id: String
    let name: String
}

struct Bar {
    let color: String
    let size: String
}

extension Foo {
    static func make(
        id: String = "",
        name: String = ""
    ) -> Foo {
        .init(id: id, name: name)
    }
}

extension Bar {
    static func make(
        color: String = "",
        size: String = ""
    ) -> Bar {
        .init(color: color, size: size)
    }
}

// Protocol witness

// Contrived example of how you could switch using v2 LoadFoo over v1 LoadFoo
struct FeatureFlags {
    let productV2On: Bool
}

// file: Network.swift

class Network {
    var checkout: CheckoutService
    var product: ProductService
    
    // Live version
    init(ff: FeatureFlags) {
        self.product = ProductService(useV2: ff.productV2On)
        self.checkout = CheckoutService(true)
    }
    
    // Used by test
    init() {
        self.product = ProductService()
        self.checkout = CheckoutService()
    }
}

// file: Checkout.swift

class CheckoutService {
    var loadBar: (String) -> Bar = { _ in fatalError("Stub Network.Provider.loadBar") }
    
    init() { }
    
    init(_ live: Bool) {
        self.loadBar = _loadBar
    }
    
    func loadBar(id: String) -> Bar {
        loadBar(id)
    }
}

private func _loadBar(id: String) -> Bar {
    .make()
}

// file: Product.swift

class ProductService {
    var loadFoo: (String) -> Promise<Foo> = { _ in fatalError("Stub Network.Provider.loadFoo") }
    
    init() { }
    
    init(useV2: Bool) {
        if useV2 {
            self.loadFoo = _loadFoov2
        }
        else {
            self.loadFoo = _loadFoo
        }
    }
    
    func loadFoo(id: String) -> Promise<Foo> {
        loadFoo(id)
    }
}

private func _loadFoo(id: String) -> Promise<Foo> {
    .value(.make())
}

private func _loadFoov2(id: String) -> Promise<Foo> {
    .value(.make())
}

// file: Assembly.swift

class Assembly {
    let container = Container()
    
    init() {
        container.register(Network.self) { _ in
            Network()
        }.inObjectScope(.container)
        container.register(ProductService.self) { resolver in
            resolver.force(Network.self).product
        }
        container.register(CheckoutService.self) { resolver in
            resolver.force(Network.self).checkout
        }
    }
}

// MARK: - Tests

class SimpleTestCase: XCTestCase {
    private var assembly: Assembly!
    var container: Container!
    
    override func setUp() {
        // Required for dependency injection
        // This should be done in global `XCTestCase`
        assembly = Assembly()
        container = assembly.container
        setContainer(assembly.container)
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

    func testViewModel() throws {
        let tester = TestViewModelInterface(viewModel: FooViewModel())

        tester.expect([
            .state(.init(id: "5", name: "Foo"))
        ])
        
        let network = container.force(Network.self)
        network.product.loadFoo = { id in
            .value(.init(id: id, name: "Bar"))
        }

        tester.send(.didTapButton).expect([
            .state(.init(id: "10", name: "Bar"))
        ])

        // This isn't necessary. If the value from the `send` function is unused, a compiler warning will show, making it immediately obvious that it is missing an expectation.
        tester.finish()
    }
}
