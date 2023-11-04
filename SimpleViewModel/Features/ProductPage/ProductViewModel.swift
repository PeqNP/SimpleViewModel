/// Copyright ⓒ 2023 Bithead LLC. All rights reserved.

import Foundation

class ProductViewModel: ViewModel {
    enum Input {
        case loadProduct(id: ProductID)
        case didTapLike

        // This is how we compose child view models
        case sku(SKUViewModel.Output)
    }

    enum Output {
        case loadedProduct(Product)
        case addedToBag
        case showError(Error)
    }

    // Should a state be provided? This would allow a transform to be placed on top of view state. Ideally we would want to prevent updates to the page if the state is the same. IMO, this allows the implementation to be very sloppy. There's no way to ensure you're making only one call to the backend, etc.
    func accept(_ input: Input, respond: (Output) -> Void) {
        switch input {
        case let .loadProduct(id):
            // Make network request to load Product
            print(id)
            respond(.loadedProduct(
                .init(
                    id: id,
                    name: "Name",
                    price: .single(.regular(10)),
                    skus: [
                        .init(
                            id: "1",
                            color: .init(name: "Red", imageURL: nil),
                            size: .init(name: "L", metaDescription: nil),
                            price: .regular(10)
                        )
                    ]
                )
            ))
        case .didTapLike:
            break // Make network request
        case let .sku(msg):
            switch msg {
            case .addedToBag:
                // Update the view with some visual information
                respond(.addedToBag)
                break
            }
        }
    }
}
