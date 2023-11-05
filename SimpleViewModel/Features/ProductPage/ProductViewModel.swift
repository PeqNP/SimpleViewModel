/// Copyright ⓒ 2023 Bithead LLC. All rights reserved.

import Foundation

class ProductViewModel: ViewModel {
    struct ViewState: Equatable {
        var productName: String
        var productPrice: String
        var isLiked: Bool
        var skus: [SKU]
        
        static func make(from state: State) -> Self {
            .init(
                productName: state.product.name,
                productPrice: state.product.price.toString,
                isLiked: state.isLiked,
                skus: state.product.skus
            )
        }
    }
    
    /// This is not required. It is a convenient way to encapsulate the interal state of the `ViewModel`.
    struct State {
        var productId: ProductID
        var product: Product
        var isLiked: Bool

        static var empty: State {
            .init(productId: "0", product: .empty, isLiked: false)
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

    var state: State = .empty

    func filter(output: Output) -> ViewState? {
        switch output {
        case let .update(viewState): return viewState
        default: return nil
        }
    }

    // Should a state be provided? This would allow a transform to be placed on top of view state. Ideally we would want to prevent updates to the page if the state is the same. IMO, this allows the implementation to be very sloppy. There's no way to ensure you're making only one call to the backend, etc.
    func accept(_ input: Input, respond: (Output) -> Void) {
        switch input {
        case let .loadProduct(id):
            state.productId = id
            // TODO: Make network request to load `Product`
            state.product = .init(
                id: id,
                name: "Name",
                price: .single(.regular(10)),
                skus: []
            )
            respond(.update(.make(from: state)))
        case .didTapLike:
            // TODO: Make network request to like `Product`
            state.isLiked = !state.isLiked
            respond(.update(.make(from: state)))
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
