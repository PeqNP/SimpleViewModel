/// Copyright ⓒ 2023 Bithead LLC. All rights reserved.

import Foundation

struct AppError: Error {
    private let error: Error

    init(_ error: Error) {
        self.error = error
    }
}

extension AppError: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.error.localizedDescription == rhs.error.localizedDescription
    }
}
