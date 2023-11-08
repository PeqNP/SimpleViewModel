/// Copyright ⓒ 2023 Bithead LLC. All rights reserved.

import Foundation

public protocol ViewModel<Input, Output> {
    associatedtype Input
    associatedtype Output: Equatable

    /// Allows the `ViewModel` to send a signal before any events may be accepted. This can be used to populate the default state of the view.
    func first(respond: (Output) -> Void)
    
    /// Accept an input from the consumer and respond in kind.
    func accept(_ input: Input, respond: @escaping (Output) -> Void)

    /// Filter `Input` signals from being sent to the `ViewModel` until the respective `Input` operation has finished.
    ///
    /// Use Case: If a user sends an `addToBag` `Input`, and the "Add to bag" operation requires a network call, you can filter all subsequent `addToBag` `Input`s until the "Add to bag" operation succeeds.
    func filter() -> [Input]
    
    /// Debounce `Input` signals for N seconds
    func debounce() -> [(Input, TimeInterval)]
}

public extension ViewModel {
    /// Not every view model wishes to respond before signals can be sent
    func first(respond: (Output) -> Void) { }
    
    /// Not every `ViewModel` wants to filter `Input`s
    func filter() -> [Input] { [] }
    
    func debounce() -> [(Input, TimeInterval)] { [] }
}
