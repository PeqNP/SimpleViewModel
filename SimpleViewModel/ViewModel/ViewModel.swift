/// Copyright ⓒ 2023 Bithead LLC. All rights reserved.

import Foundation

protocol ViewModel<Input, Output> {
    associatedtype ViewState: Equatable
    associatedtype Input
    associatedtype Output

    // Provides a way to determine if an `Output` signal should be sent if the `ViewState` is different than the last state.
    func limit(output: Output) -> ViewState?
    func accept(_ input: Input, respond: (Output) -> Void)
    func first(respond: (Output) -> Void)
}

extension ViewModel {
    // Not every view model wishes to check for state
    func limit(output: Output) -> ViewState? { return nil }

    // Not every view model wishes to respond to the first event
    func first(respond: (Output) -> Void) { }
}
