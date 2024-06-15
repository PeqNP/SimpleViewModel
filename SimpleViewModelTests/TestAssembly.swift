/// Copyright ⓒ 2023 Bithead LLC. All rights reserved.

import Foundation
import SimpleViewModel
import Swinject

class TestAssembly {
    let container = Container()

    init() {
        setContainer(self.container)
    }

    func register<Concrete>(_ instance: Concrete, as type: Concrete.Type) {
        container.register(Concrete.self) { _ in instance }
    }
}

