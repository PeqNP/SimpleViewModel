/// Copyright ⓒ 2023 Bithead LLC. All rights reserved.

import Foundation
import PromiseKit

class CheckoutService {
    var cart: () -> Promise<Cart> = { fatalError("Stub Network.Provider.cart") }

    init() { }
    
    init(_ live: Bool) {
        self.cart = _cart
    }
}

private func _cart() -> Promise<Cart> {
    .value(.init(
        products: [
            .init(
                id: "1",
                name: "Name",
                price: .single(.regular(10)),
                skus: [.init(
                    id: "1",
                    color: .init(name: "Red", imageURL: nil),
                    size: .init(name: "Medium", metaDescription: "M"),
                    price: .regular(10)
                )]
            )
        ]
    ))
}
