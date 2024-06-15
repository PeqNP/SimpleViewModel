/// Copyright ⓒ 2024 Bithead LLC. All rights reserved.

import Swinject
import XCTest

@testable import SimpleViewModel

private enum AsyncError: Error, Equatable {
    case testError
}

/// This shows how you can use `async` vms.
private struct AsyncViewModel: ViewModel {
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

    func thrownError(_ error: any Error, respond: @escaping RespondCallback) {
        respond(.showError(String(describing: error)))
    }

    func accept(_ input: Input, respond: @escaping (Output) -> Void) async throws {
        switch input {
        case .didTapAddButton:
            let cart = try await cart.addProduct(.init(id: "1", name: "Eric", price: .single(.regular(1_000_000)), skus: []))
            respond(.showCart(cart))
        }
    }
}

// MARK: - Tests

private enum TestError: Error {
    case productNotFound
}

/// FakeCartService is a contrived example of how to create a fake implemenation of a protocol
private class FakeCartService: CartProvider {
    /// Very simple way to track calls made to respective functions
    var addedProducts = [Product]()
    var removedProducts = [Product]()

    /// Very simple way to return a stubbed value
    var cart: Cart?

    func addProduct(_ product: SimpleViewModel.Product) async throws -> SimpleViewModel.Cart {
        addedProducts.append(product)
        guard let cart else {
            throw TestError.productNotFound
        }
        return cart
    }

    func removeProduct(_ product: SimpleViewModel.Product) async throws -> SimpleViewModel.Cart {
        removedProducts.append(product)
        guard let cart else {
            throw TestError.productNotFound
        }
        return cart
    }
}

final class SimpleViewModelAsyncTests: SimpleTestCase {

    func testAsyncRequests() throws {
        let assembly = TestAssembly()
        let cart = FakeCartService()
        assembly.register(cart, as: CartProvider.self)

        var outputs = [AsyncViewModel.Output]()
        let vm = ViewModelInterface(viewModel: AsyncViewModel(), receive: { output in
            outputs.append(output)
        })

        // describe: load products; products have been stubbed
        cart.cart = .init(products: [])
        vm.send(.didTapAddButton)

        let expected: [AsyncViewModel.Output] = [.showCart(.init(products: []))]
        TestWaiter.wait(for: { outputs == expected })

        // describe: load products; raise error
        cart.cart = nil // Setting this to `nil` has the effect of making service raise error
        vm.send(.didTapAddButton)

        TestWaiter.wait(for: { outputs.count == 2 })
        XCTAssertEqual(outputs[safe: 1], AsyncViewModel.Output.showError(String(describing: TestError.productNotFound)))
    }
}
