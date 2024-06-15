/// Copyright ⓒ 2023 Bithead LLC. All rights reserved.

import Foundation
import PromiseKit

/// Provides products
///
/// This provides a contrived example to use different versions of a product service
class ProductService {
    var product: (ProductID) -> Promise<Product> = { _ in fatalError("Stub Provider.product") }

    init() { }
    
    init(useVersion2API: Bool) {
        if useVersion2API {
            self.product = _product_v2
        }
        else {
            self.product = _product
        }
    }
    
    func product(for id: ProductID) -> Promise<Product> {
        product(id)
    }
}

private func _product(for id: ProductID) -> Promise<Product> {
    firstly {
        requestProduct(for: id)
    }
}

private func _product_v2(for id: ProductID) -> Promise<Product> {
    // This would make a request to a different endpoint. For simplicity, this returns the same thing as the V1 endpoint.
    firstly {
        requestProduct(for: id)
    }
}

private func requestProduct(for productId: ProductID) -> Promise<Product> {
    // Fake request for now
    .value(.init(
        id: "1",
        name: "Name",
        price: .single(.regular(10)),
        skus: [
            .init(id: "1", color: .init(name: "Red", imageURL: nil), size: .init(name: "Medium", metaDescription: "M"), price: .regular(10))
        ]
    ))
}

// Making a real request may require a `Request` object and mapped to a `Response` object. Once a response is provided, the `Response` object is mapped to the respective domain model.
// Below are contrived examples for a request, response, and network to domain transform.

struct ProductRequest: Encodable {
    let productId: ProductID
}

struct ProductResponse: Decodable {
    struct Price: Decodable {
        let type: String
        let amount: Double
        // ... Imagine this being complete
    }

    struct SKU: Decodable {
        struct Color: Decodable {
            let name: String
        }
        struct Size: Decodable {
            let name: String
            let metadata: String?
        }
        
        let id: String
        let color: ProductResponse.SKU.Color
        let size: ProductResponse.SKU.Size
        let price: ProductResponse.Price
    }
    
    let id: String
    let name: String
    let price: Price
    let skus: [ProductResponse.SKU]
}

extension Product {
    static func make(from response: ProductResponse) -> Product {
        .init(
            id: response.id,
            name: response.name,
            price: .single(.regular(response.price.amount)),
            skus: response.skus.map { SKU.make(from: $0) }
        )
    }
}

extension SKU {
    static func make(from response: ProductResponse.SKU) -> SKU {
        .init(
            id: response.id,
            color: .init(name: response.color.name, imageURL: nil),
            size: .init(name: response.size.name, metaDescription: response.size.metadata),
            price: .regular(response.price.amount)
        )
    }
}

fileprivate func requestProduct(with request: ProductRequest) throws -> URLRequest {
    var rq = URLRequest(url: URL(string: "https://api.getbithead.com/product")!)
    rq.httpMethod = "POST"
    rq.addValue("application/json", forHTTPHeaderField: "Content-Type")
    rq.addValue("application/json", forHTTPHeaderField: "Accept")
    rq.httpBody = try JSONEncoder().encode(request)
    return rq
}
