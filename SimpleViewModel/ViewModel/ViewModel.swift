/// Copyright ⓒ 2023 Bithead LLC. All rights reserved.

import Foundation

public struct Debounce<Input> {
    let input: Input
    let interval: TimeInterval
}

public protocol ViewModel<Input, Output> {
    associatedtype Input
    associatedtype Output: Equatable

    typealias RespondCallback = (Output) -> Void

    /// Allows the `ViewModel` to send a signal before any events may be accepted. This can be used to populate the default state of the view.
    func first(respond: RespondCallback)
    
    /// Accept an input from the consumer and respond in kind.
    func accept(_ input: Input, respond: @escaping RespondCallback)

    /// Filter `Input` signals from being sent to the `ViewModel` until the respective `Input` operation has finished.
    ///
    /// Use Case: If a user sends an `addToBag` `Input`, and the "Add to bag" operation requires a network call, you can filter all subsequent `addToBag` `Input`s until the "Add to bag" operation completes.
    func filter() -> [Input]

    /// Filters all signals from being sent to `ViewModel` until last `Input` operation has finished.
    func filterAll() -> Bool

    /// Filter all signals from being sent to the `ViewModel` until specific `Input`s have finished.
    ///
    /// Use Case: If user sends `addToBag` `Input`, all other signals are ignored until the `addToBag` operation has completed.
    func filterAllInputs() -> [Input]

    /// Debounce `Input` signals for N seconds
    func debounce() -> [Debounce<Input>]

    /**
     Returns a callback that can be used for async responses which are not directly related to an input. For example, a view model may listen to the user's signed in status. If a user signs in our out, the view model may want to send commands to the consumer informing them of the state change.

     NOTES:
     - Do NOT use the instance of this callback in `accept`
     - The view model is expected to hold on to an instance of this callback for the duration of its lifetime
     - This is considered a configuration step, and, therefore, is called before `first`
     - Messages sent on this channel are not filtered or debounced
     */
    func responder(respond: @escaping RespondCallback)
}

/// Default implementations for optional behaviors
public extension ViewModel {
    func first(respond: RespondCallback) { }
    func filter() -> [Input] { [Input]() }
    func filterAll() -> Bool { false }
    func filterAllInputs() -> [Input] { [Input]() }
    func debounce() -> [Debounce<Input>] { [Debounce<Input>]() }
    func responder(respond: @escaping RespondCallback) { }
}
