# SimpleViewModel

A simple, robust, view model pattern.

- Easy to change
- Easy to test

Additional benefits:

- Know where a signal originates from. Avoid the "infinite sink" problem when debugging (e.g. `RxSwift`).
- Pass-thru child signals to parent view models with ease. No complicated wiring. Use delegation, a pattern that has been used for decades. Refer to `ProductViewController` for an example.
- Debounce and filter signals to your view model.
- `TestWaiter` provides a flexible way to wait for conditions to occur before the test continues. Useful for asynchronous calls.

The sample project also provides several examples for the following patterns:

- Dependency injection. Use `Swinject` and the `@Dependency` property wrapper. Refer to `ProductViewModel` for an example.
- Protocol witness pattern used for stubbing network requests. Please refer to the `ProductService` class, within the sample project, for an example.
- Network to domain transform
- Project organization. The organization of this project has worked for very large iOS teams. Every group such as `App`, `Domain`, `Foundation`, etc. would be their own module.
- A handful of helpful extensions for `Array`, `UIView`, etc.

## Introduction

This project aims to build on top of tried and true patterns that have been around for decades. It is a non-opinionated, robust, testable pattern.

This view model illustrates how to:

- Filter signals from button taps
- Debounce signals from text entry
- Makes network requsts to query and search for products
- Injects dependencies
- Transforms domain model to view model
- Returns error states that the VC can show to the user

```swift
// file: MyViewModel.swift

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
    
    // Wait for the product to be retrieved from server before allowing the button to be tapped again
    func filter() -> [Input] {
        [.didTapButton]
    }
    
    // When searching for a product, wait 300ms
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
                    // Transform domain model to view state
                    respond(.state(.init(id: product.id, name: product.name)))
                }
                .catch { error in
                    respond(.showError(error.localizedDescription))
                }
        case let .didSearch(term):
            product.search(term: term)
                .done { productSearch in
                    respond(.products(productSearch))
                }
                .catch { error in
                    respond(.showError(error.localizedDescription))
                }
        }
    }
}
```

Testing the `FooViewModel`.

```swift
// file: FooViewModelTests.swift

// Please note that `SimpleTestCase` is a custom class that initializes the Networking layer.
// Please refer to the `SimpleViewModelTests` file for more context.

final class FooViewModelTests: SimpleTestCase {

    override func setUpWithError() throws { }

    override func tearDownWithError() throws { }
    
    func testFooViewModel() throws {
        let tester = TestViewModelInterface(viewModel: FooViewModel())

        // Test the initial state of the VM. If your `ViewModel` implements `first`,
        // this is a _required_ step.
        tester.expect([
            .state(.init(id: "5", name: "Foo"))
        ])
        
        // Stub a networking service. Please refer to the sample project for more context.
        let product = container.force(ProductService.self)
        product.product = { id in
            .value(.init(id: id, name: "Name", price: .single(.regular(10)), skus: []))
        }

        // describe: tap button to load `Product`
        tester.send(.didTapButton).expect([
            // it: should return a new `ViewState`
            .state(.init(id: "10", name: "Name"))
        ])

        // This isn't necessary. If the value from the `send` function is unused, a
        // compiler warning will show, making it immediately obvious that it is missing
        // an expectation.
        tester.finish()
    }
}
```

To see how you can wire signals between child and parent, refer to the `ProductViewController` and the `SKUView`. Instead of the parent `ViewModel` having a reference to the child `ViewModel` (as in the Composable Architecture) you configure signaling to occur via delegation.

If you found this pattern interesting, you may also find the following libraries helpful:
- [`SimpleAnalytics`](https://github.com/PeqNP/SimpleAnalytics) - A way to easily capture and emit analytics to multiple analytics providers
- [`SimpleABTest`](https://github.com/PeqNP/SimpleABTesting) - A way to easily A/B test features
- [`SimpleUITheme`](https://github.com/PeqNP/SimpleUITheme) - Easily define and integrate design patterns into your app
- [`SimpleGetView`](https://github.com/PeqNP/SimpleGetView) - Identifying views that can be tested at test time
