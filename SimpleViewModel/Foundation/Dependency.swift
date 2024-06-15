/// Copyright ⓒ 2023 Bithead LLC. All rights reserved.

import Swinject

private var container: Container!

public func setContainer(_ c: Container?) {
    container = c
}

@propertyWrapper struct Dependency<T> {
    var wrappedValue: T

    init(wrappedValue: T) {
        self.wrappedValue = container.resolve(T.self)!
    }
}

public func inject<T>(_ type: T.Type) -> T {
    container.resolve(T.self)!
}
