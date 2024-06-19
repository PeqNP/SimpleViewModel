/// Copyright ⓒ 2023 Bithead LLC. All rights reserved.

import Foundation

public enum ViewModelError: Error {
    case ignoreInput
}

public struct Debounce<Input> {
    public let input: Input
    public let interval: TimeInterval

    public init(input: Input, interval: TimeInterval) {
        self.input = input
        self.interval = interval
    }
}

public protocol ViewModel<Input, Output> {
    associatedtype Input
    associatedtype Output: Equatable

    typealias RespondCallback = (Output) -> Void

    /// This type is designed to remove ambiguity and make it obvious that an async response is expected when using a responder. This signature will not differ from `RespondCallback`.
    typealias AsyncRespondCallback = (Output) -> Void

    /// Allows the `ViewModel` to send a signal before any events may be accepted. This can be used to populate the default state of the view.
    func first(respond: RespondCallback)
    
    /// Accept an input from the consumer and respond in kind.
    /// - Throws: When an `Input` throws, `thrownError(_:)` is called with the respective `Error`
    func accept(_ input: Input, respond: @escaping RespondCallback) async throws

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

    /// Ignore `Output`s from setting the state of an `Input` operation to "finished."
    ///
    /// Use Case: If filtering an `Input`, and you wish to show a progress bar to indicate that an `Input` is processing, this will filter the "show progress bar" `Output` (e.g. `showProgressBar(current: 0.5)`) from prematurely marking an `Input` operation as being "finished."
    ///
    /// When an `Input` operation is "finished", internally this cleans up filtering state allowing other `Input`s to be accepted. If your `Input` operation is in the middle of processing, but you wish to update the view with some type of progress, you may not want other `Input`s from processing!
    func filterOutputs() -> [Output]

    /**
     Returns a callback that can be used for async responses which are not directly related to an input. For example, a view model may listen to the user's signed in status. If a user signs in our out, the view model may want to send commands to the consumer informing them of the state change.

     NOTES:
     - Do NOT use the instance of this callback in `accept`
     - The view model is expected to hold on to an instance of this callback for the duration of its lifetime
     - This is considered a configuration step, and, therefore, is called before `first`
     - Messages sent on this channel are not filtered or debounced
     */
    func responder(respond: @escaping AsyncRespondCallback)

    /// Called when an operation bubbles up an `Error` from `accept(_:respond:)`.
    ///
    /// Use Case: This provides a way for vm to display an error if an `Input` operation failed. Please catch `Error`s where necessary. However, in many contexts, all you wish to do is bubble up the `Error` from some other operation. If you use the `Simple`
    func thrownError(_ error: Error, respond: @escaping RespondCallback)
}

/// Default implementations for optional behaviors
public extension ViewModel {
    func first(respond: AsyncRespondCallback) { }
    func filter() -> [Input] { [Input]() }
    func filterAll() -> Bool { false }
    func filterAllInputs() -> [Input] { [Input]() }
    func debounce() -> [Debounce<Input>] { [Debounce<Input>]() }
    func responder(respond: @escaping AsyncRespondCallback) { }
    func thrownError(_ error: Error, respond: @escaping RespondCallback) { }
    func filterOutputs() -> [Output] { [Output]() }
}
