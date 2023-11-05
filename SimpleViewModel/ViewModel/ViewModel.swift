/// Copyright ⓒ 2023 Bithead LLC. All rights reserved.

import Foundation

protocol ViewModel<Input, Output> {
    associatedtype Input
    associatedtype Output: Equatable

    /// Allows the `ViewModel` to send a signal before any events may be accepted. This can be used to populate the default state of the view.
    func first(respond: (Output) -> Void)
    
    /// Accept an input from the consumer and respond in kind.
    func accept(_ input: Input, respond: @escaping (Output) -> Void)
}

extension ViewModel {
    /// Not every view model wishes to respond before signals can be sent
    func first(respond: (Output) -> Void) { }
}
