/// Copyright ⓒ 2023 Bithead LLC. All rights reserved.

import Foundation
import PromiseKit

protocol ProductProvider {
    func product(for productId: ProductID) -> Promise<Product>
}
