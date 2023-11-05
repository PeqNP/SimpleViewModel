/// Copyright ⓒ 2023 Bithead LLC. All rights reserved.

import Foundation

struct SKUViewModel: ViewModel {
    struct ViewState: Equatable {
        let color: String
        let price: String
    }

    enum Input {
        case addToBag
    }

    enum Output {
        case viewState(ViewState)
        case addedToBag(SKU)
    }

    private let sku: SKU

    init(sku: SKU) {
        self.sku = sku
    }

    func first(respond: (Output) -> Void) {
        respond(.viewState(.init(
            color: sku.color.name,
            price: sku.price.toString)
        ))
    }

    func accept(_ input: Input, respond: @escaping (Output) -> Void) {
        switch input {
        case .addToBag:
            /**
             TODO: Perform a network request to add the product SKU to the bag.

             In many cases this would be a very simple VM that may not perform any network request. The network request is being performed in the view to illustrate how you can create isolated views that perform their own workload.
             */
            respond(.addedToBag(sku))
        }
    }
}
