/// Copyright ⓒ 2023 Bithead LLC. All rights reserved.

import Foundation

enum Price: Equatable {
    case regular(Double)
    case sale(was: Double, now: Double)

    var current: Double {
        switch self {
        case let .regular(price):
            return price
        case let .sale(_, now):
            return now
        }
    }

    var toString: String {
        switch self {
        case let .regular(price):
            return String(price)
        case let .sale(was, now):
            return "Was: \(was) Now: \(now)"
        }
    }
}

enum NormalPrice: Equatable {
    case single(Price)
    case range(from: Price, to: Price)

    var toString: String {
        switch self {
        case let .single(price):
            return price.toString
        case let .range(from, to):
            return "From \(from.current) to \(to.current)"
        }
    }
}

struct Product: Equatable {
    let id: ProductID
    let name: String
    let price: NormalPrice
    let skus: [SKU]
    
    static var empty: Product {
        .init(id: "0", name: "", price: .single(.regular(0)), skus: [])
    }
}

struct SKUColor: Equatable {
    let name: String
    let imageURL: URL?
}

struct SKUSize: Equatable {
    let name: String
    let metaDescription: String?
}

struct SKU: Equatable {
    let id: SKUID
    let color: SKUColor
    let size: SKUSize
    let price: Price
}
