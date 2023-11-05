/// Copyright ⓒ 2023 Bithead LLC. All rights reserved.

import Foundation

protocol ViewModel<Input, Output> {
    associatedtype ViewState: Equatable
    associatedtype Input
    associatedtype Output

    /// Allows the `ViewModel` to send a signal before any events may be accepted. This can be used to populate the default state of the view.
    func first(respond: (Output) -> Void)
    
    /// Provides a way to filter an `Output` signal that provides a `ViewState`. If a `ViewState` is provided, and the `ViewState` is the same as the previous state, no signal will be sent to the consumer.
    func filter(output: Output) -> ViewState?
    
    /// Accept an input from the consumer and respond in kind.
    func accept(_ input: Input, respond: (Output) -> Void)
}

extension ViewModel {
    /// Not every view model wishes to filter for state
    func filter(output: Output) -> ViewState? { return nil }

    /// Not every view model wishes to respond before signals can be sent
    func first(respond: (Output) -> Void) { }
}
