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

    enum Output: Equatable {
        case viewState(ViewState)
        case skus([SKU])
        case showMessage(String)
        case showError(AppError)
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

    @Dependency var productService: ProductService!
    
    var state: State = .empty

    func filter() -> [Input] {
        [.loadProduct(id: ""), .didTapLike]
    }
    
    func accept(_ input: Input, respond: @escaping (Output) -> Void) {
        switch input {
        case let .loadProduct(id):
            productService.product(for: id)
                .done { [weak self] product in
                    guard let state = self?.state else { return }
                    state.product = product
                    respond(.viewState(.make(from: state)))
                    respond(.skus(product.skus))
                }
                .catch { error in
                    respond(.showError(AppError(error)))
                }
        case .didTapLike:
            // TODO: Make network request to like `Product`
            state.isLiked = !state.isLiked
            respond(.viewState(.make(from: state)))
        case let .sku(output):
            switch output {
            case .addedToBag:
                respond(.showMessage("Successfully added product!"))
                break
            case .viewState:
                break
            }
        }
    }
}
