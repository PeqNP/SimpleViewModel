/// Copyright ⓒ 2023 Bithead LLC. All rights reserved.

import Foundation

enum Price {
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

enum NormalPrice {
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

struct Product {
    let id: ProductID
    let name: String
    let price: NormalPrice
    let skus: [SKU]
}

struct SKUColor {
    let name: String
    let imageURL: URL?
}

struct SKUSize {
    let name: String
    let metaDescription: String?
}

struct SKU {
    let id: SKUID
    let color: SKUColor
    let size: SKUSize
    let price: Price
}

extension SKUSize: Equatable {

    public static func ==(lhs: SKUSize, rhs: SKUSize) -> Bool {
        return lhs.name == rhs.name
            && lhs.metaDescription == rhs.metaDescription
    }
}
extension SKUColor: Equatable {

    public static func ==(lhs: SKUColor, rhs: SKUColor) -> Bool {
        return lhs.name == rhs.name
            && lhs.imageURL == rhs.imageURL
    }
}
