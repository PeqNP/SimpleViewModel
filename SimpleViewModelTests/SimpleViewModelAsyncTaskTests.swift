/// Copyright ⓒ 2024 Bithead LLC. All rights reserved.

import Swinject
import XCTest

@testable import SimpleViewModel

private enum AsyncError: Error, Equatable {
    case testError
}

/// This view model shows how you can inject and use a protocol-oriented approach with this library.
/// It also shows how you can integrate `async` into your vms using the `asyncTask` extension.
private struct AsyncTaskViewModel: ViewModel {
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
            // This is how you can perform N number of `async` calls and respond accordingly. You an also use the Promise library of your choice, using a similar pattern.
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

final class SimpleViewModelAsyncTaskTests: SimpleTestCase {

    func testAsyncRequests() throws {
        let assembly = TestAssembly()
        let cart = FakeCartService()
        assembly.register(cart, as: CartProvider.self)

        var outputs = [AsyncTaskViewModel.Output]()
        let vm = ViewModelInterface(viewModel: AsyncTaskViewModel(), receive: { output in
            outputs.append(output)
        })

        // describe: load products; products have been stubbed
        cart.cart = .init(products: [])
        vm.send(.didTapAddButton)

        TestWaiter.wait(for: { outputs.count == 1 })
        let expected: [AsyncTaskViewModel.Output] = [.showCart(.init(products: []))]
        XCTAssertEqual(outputs, expected)

        // describe: load products; raise error
        cart.cart = nil // Setting this to `nil` has the effect of making service raise error
        vm.send(.didTapAddButton)

        TestWaiter.wait(for: { outputs.count == 2 })
        XCTAssertEqual(outputs[safe: 1], AsyncTaskViewModel.Output.showError(String(describing: TestError.productNotFound)))
    }

    func testPromise_fulfillSuccess() throws {
        var promise = AsyncTask<Product>()

        var fulfilledProduct: Product?

        // describe: fulfill promise before success callback is registered
        let product = Product(id: "1", name: "Eric", price: .single(.regular(10)), skus: [])
        promise.success(product)
        promise.onSuccess { p in
            fulfilledProduct = p
        }
        TestWaiter.wait(for: { promise.fulfilled })
        XCTAssertEqual(product, fulfilledProduct)

        // describe: fulfill promise after on success callback is registered
        fulfilledProduct = nil
        promise = AsyncTask<Product>()
        promise.onSuccess { p in
            fulfilledProduct = p
        }
        XCTAssertFalse(promise.fulfilled)
        promise.success(product)
        TestWaiter.wait(for: { promise.fulfilled })
        XCTAssertEqual(product, fulfilledProduct)
    }

    func testPromise_fulfillError() throws {
        var promise = AsyncTask<Product>()

        var fulfilledError: AsyncError?

        // describe: fulfill promise before error callback is registered
        promise.failure(AsyncError.testError)
        promise.onFailure { e in
            fulfilledError = e as? AsyncError
        }
        TestWaiter.wait(for: { promise.fulfilled })
        XCTAssertEqual(AsyncError.testError, fulfilledError)

        // describe: fulfill promise after error callback is registered
        fulfilledError = nil
        promise = AsyncTask<Product>()
        promise.onFailure { e in
            fulfilledError = e as? AsyncError
        }
        XCTAssertFalse(promise.fulfilled)
        promise.failure(AsyncError.testError)
        TestWaiter.wait(for: { promise.fulfilled })
        XCTAssertEqual(AsyncError.testError, fulfilledError)
    }

    func testPromise_fulfillComplete_success() throws {
        var promise = AsyncTask<Product>()

        var fulfilledProduct: Product?

        // describe: fulfill promise before success callback is registered
        let product = Product(id: "1", name: "Eric", price: .single(.regular(10)), skus: [])
        promise.success(product)
        promise.onComplete { result in
            switch result {
            case let .success(product):
                fulfilledProduct = product
            case .failure:
                XCTFail("expected onComplete to succeed")
            }
        }
        TestWaiter.wait(for: { promise.fulfilled })
        XCTAssertEqual(product, fulfilledProduct)

        // describe: register to promise after fulfillment as success callback
        fulfilledProduct = nil
        promise.onSuccess { p in
            fulfilledProduct = p
        }
        // it: should immediately resolve promise
        XCTAssertEqual(product, fulfilledProduct)

        // describe: fulfill promise after on success callback is registered
        fulfilledProduct = nil
        promise = AsyncTask<Product>()
        promise.onComplete { result in
            switch result {
            case let .success(product):
                fulfilledProduct = product
            case .failure:
                XCTFail("expected onComplete to succeed")
            }
        }
        XCTAssertFalse(promise.fulfilled)
        promise.success(product)
        TestWaiter.wait(for: { promise.fulfilled })
        XCTAssertEqual(product, fulfilledProduct)
    }

    func testPromise_fulfillComplete_error() throws {
        var promise = AsyncTask<Product>()

        var fulfilledError: AsyncError?

        // describe: fulfill promise before error callback is registered
        promise.failure(AsyncError.testError)
        promise.onComplete { result in
            switch result {
            case .success:
                XCTFail("Expected onComplete to fail")
            case let .failure(error):
                fulfilledError = error as? AsyncError
            }
        }
        TestWaiter.wait(for: { promise.fulfilled })
        XCTAssertEqual(AsyncError.testError, fulfilledError)

        // describe: register to promise after fulfillment
        fulfilledError = nil
        promise.onFailure { e in
            fulfilledError = e as? AsyncError
        }
        // it: should immediately resolve promise
        XCTAssertEqual(AsyncError.testError, fulfilledError)

        // describe: fulfill promise after error callback is registered
        fulfilledError = nil
        promise = AsyncTask<Product>()
        promise.onComplete { result in
            switch result {
            case .success:
                XCTFail("Expected onComplete to fail")
            case let .failure(error):
                fulfilledError = error as? AsyncError
            }
        }
        XCTAssertFalse(promise.fulfilled)
        promise.failure(AsyncError.testError)
        TestWaiter.wait(for: { promise.fulfilled })
        XCTAssertEqual(AsyncError.testError, fulfilledError)
    }
}
