/// Copyright ⓒ 2023 Bithead LLC. All rights reserved.

import Foundation

protocol ViewModel<Input, Output> {
    associatedtype Input
    associatedtype Output

    func accept(_ input: Input, respond: (Output) -> Void)
}
