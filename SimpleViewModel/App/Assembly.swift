/// Copyright ⓒ 2023 Bithead LLC. All rights reserved.

import Foundation
import Swinject

extension Resolver {
    func force<Service>(_ object: Service.Type) -> Service {
        resolve(object)!
    }
}

class Assembly {
    let container = Container()
    
    init() {
        
        // MARK: - Subsystem

        container.register(DispatchQueue.self) { _ in
            DispatchQueue.main
        }
        
        container.register(URLSession.self) { _ in
            URLSession(configuration: URLSessionConfiguration.default)
        }
        
        container.register(FeatureFlags.self) { _ in
            FeatureFlags()
        }.inObjectScope(.container)
                
        // MARK: - Network
        
        container.register(ProductService.self) { resolver in
            let ff = resolver.force(FeatureFlags.self)
            return ProductService(useVersion2API: ff.useVersion2ProductService)
        }.inObjectScope(.container)
        
        container.register(CheckoutService.self) { resolver in
            CheckoutService()
        }.inObjectScope(.container)
    }
}
