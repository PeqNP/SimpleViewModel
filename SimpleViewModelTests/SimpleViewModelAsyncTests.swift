/// Copyright ⓒ 2024 Bithead LLC. All rights reserved.

import PromiseKit
import Swinject
import XCTest

@testable import SimpleViewModel

enum AsyncError: Error, Equatable {
    case testError
}

///  This is designed to test filtering all `Input`s, regardless of which `Input` is sent
struct AsyncViewModel: ViewModel {
    enum Input {
        case didTapAddButton
    }

    enum Output: Equatable {
        case showCart(Cart)
        case showError(String)
    }

    struct State: Equatable {
        let id: String
        let name: String
    }

    @Dependency var cart: CartProvider!

    func filterAll() -> Bool {
        true
    }

    func accept(_ input: Input, respond: @escaping (Output) -> Void) throws {
        switch input {
        case .didTapAddButton:
            asyncTask { () -> Cart in
                try await cart.addProduct(.init(id: "1", name: "Eric", price: .single(.regular(1_000_000)), skus: []))
                // You can add multiple try...await, `Task`s, etc. in this block.
            }
            .onSuccess { cart in
                respond(.showCart(cart))
            }
            .onFailure { error in
                respond(.showError(String(describing: error)))
            }
        }
    }
}

// MARK: - Tests

enum TestError: Error {
    case funcNotStubbed(functionName: String)
}

class FakeCartService: CartProvider {
    var addedProducts = [Product]()
    var removedProducts = [Product]()
    var cart: Cart?

    func addProduct(_ product: SimpleViewModel.Product) async throws -> SimpleViewModel.Cart {
        addedProducts.append(product)
        guard let cart else {
            throw TestError.funcNotStubbed(functionName: "addProduct")
        }
        return cart
    }
    
    func removeProduct(_ product: SimpleViewModel.Product) async throws -> SimpleViewModel.Cart {
        removedProducts.append(product)
        guard let cart else {
            throw TestError.funcNotStubbed(functionName: "removeProduct")
        }
        return cart
    }
}

final class SimpleViewModelAsyncTests: SimpleTestCase {

    override func setUpWithError() throws { }

    override func tearDownWithError() throws { }

    func testAsyncRequests() throws {
        let assembly = TestAssembly()
        assembly.register(FakeCartService(), as: CartProvider.self)
        globalAssembly = assembly

        let tester = TestViewModelInterface(viewModel: AsyncViewModel())
    }
}
