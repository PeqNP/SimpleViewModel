/// Copyright ⓒ 2023 Bithead LLC. All rights reserved.

import Foundation

/// In addition to using protocol witnesses, this provides a pattern for protocol oriented programming.
/// In this context a protocol is used to define the domain interface to a "Cart service".
/// This also shows how the SimpleViewModel libraray can  handle async functions.
protocol CartProvider {
    func addProduct(_ product: Product) async throws -> Cart
    func removeProduct(_ product: Product) async throws -> Cart
}
