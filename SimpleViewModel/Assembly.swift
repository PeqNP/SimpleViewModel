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
                
        // MARK: - Providers
        
        container.register(ProductService.self) { _ in
            ProductService()
        }
    }
}
