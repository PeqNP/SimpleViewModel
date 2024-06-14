/// Copyright ⓒ 2023 Bithead LLC. All rights reserved.

import Foundation
import Swinject

@testable import SimpleViewModel

class TestAssembly: SimpleViewModel.Assembly {
    override init() { }

    func register<Concrete>(_ instance: Concrete, as type: Concrete.Type) {
        container.register(Concrete.self) { _ in instance }
    }
}

