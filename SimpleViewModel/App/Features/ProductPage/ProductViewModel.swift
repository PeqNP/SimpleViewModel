/// Copyright ⓒ 2023 Bithead LLC. All rights reserved.

import Foundation

class ProductViewModel: ViewModel {    
    struct ViewState: Equatable {
        var productName: String
        var productPrice: String
        var isLiked: Bool
        
        static func make(from state: State) -> Self {
            .init(
                productName: state.product.name,
                productPrice: state.product.price.toString,
                isLiked: state.isLiked
            )
        }
    }
    
    enum Input {
        case loadProduct(id: ProductID)
        case didTapLike

        // This is how we compose child view models
        case sku(SKUViewModel.Output)
    }

    enum Output {
        case viewState(ViewState)
        case skus([SKU])
        case addedToBag
        case showError(Error)
    }
    
    /// This is not required. It is a convenient way to encapsulate the interal state of the `ViewModel`.
    class State {
        var product: Product
        var isLiked: Bool

        init(product: Product, isLiked: Bool) {
            self.product = product
            self.isLiked = isLiked
        }
        
        static var empty: State {
            .init(product: .empty, isLiked: false)
        }
    }

    @Dependency var productProvider: ProductProvider!
    
    var state: State = .empty

    func accept(_ input: Input, respond: @escaping (Output) -> Void) {
        switch input {
        case let .loadProduct(id):
            productProvider.product(for: id)
                .done { [weak self] product in
                    guard let state = self?.state else { return }
                    state.product = product
                    respond(.viewState(.make(from: state)))
                    respond(.skus(product.skus))
                }
                .catch { error in
                    respond(.showError(error))
                }
        case .didTapLike:
            // TODO: Make network request to like `Product`
            state.isLiked = !state.isLiked
            respond(.viewState(.make(from: state)))
        case let .sku(output):
            switch output {
            case .addedToBag:
                respond(.addedToBag)
                break
            case .viewState:
                break
            }
        }
    }
}
