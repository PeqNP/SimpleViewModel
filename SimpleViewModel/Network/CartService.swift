/// Copyright ⓒ 2023 Bithead LLC. All rights reserved.

import Foundation

class CartService: CartProvider {
    private var products = [Product]()

    func addProduct(_ product: Product) async throws -> Cart {
        products.append(product)
        return .init(products: products)
    }
    
    func removeProduct(_ product: Product) async throws -> Cart {
        products.removeAll(where: { p in
            p.id == product.id
        })

        return .init(products: products)
    }
}
