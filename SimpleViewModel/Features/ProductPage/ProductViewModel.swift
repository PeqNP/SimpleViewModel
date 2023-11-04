/// Copyright ⓒ 2023 Bithead LLC. All rights reserved.

import Foundation

class ProductViewModel: ViewModel {
    struct ViewState: Equatable {
        var productName: String
        var productPrice: String
        var isLiked: Bool
        var skus: [SKU]

        static var empty: ViewState {
            .init(productName: "", productPrice: "", isLiked: false, skus: [])
        }
    }

    enum Input {
        case loadProduct(id: ProductID)
        case didTapLike

        // This is how we compose child view models
        case sku(SKUViewModel.Output)
    }

    enum Output {
        case update(ViewState)
        case addedToBag
        case showError(Error)
    }

    var state: ViewState = .empty

    func limit(output: Output) -> ViewState? {
        switch output {
        case let .update(viewState): return viewState
        default: return nil
        }
    }

    // Should a state be provided? This would allow a transform to be placed on top of view state. Ideally we would want to prevent updates to the page if the state is the same. IMO, this allows the implementation to be very sloppy. There's no way to ensure you're making only one call to the backend, etc.
    func accept(_ input: Input, respond: (Output) -> Void) {
        switch input {
        case let .loadProduct(id):
            print("Product ID: \(id)")
            // TODO: Make network request to load `Product` and tranform into `ViewState`.
            state.productName = "Name"
            state.productPrice = "$10.00"
            respond(.update(state))
        case .didTapLike:
            // TODO: Make network request to like `Product`
            state.isLiked = !state.isLiked
            respond(.update(state))
        case let .sku(msg):
            switch msg {
            case .addedToBag:
                respond(.addedToBag)
                break
            case .loaded:
                break
            }
        }
    }
}
