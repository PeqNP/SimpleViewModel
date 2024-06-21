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

    /// A callback provided _only_ if a corresponding `Input` is provided.
    typealias RespondCallback = (Output) -> Void

    /// Allows the `ViewModel` to send a signal before any `Input` events may be accepted. This can be used to populate the default state of the view.
    ///
    /// Depending on when you instantiate the `ViewModel`, you may need to cache this value until your controller's view loads or your view's nib is inflated.
    ///
    /// If using `first`, the safest option is to instantiate the `ViewModel` in `UIViewController.viewDidLoad` to safeguard against the possibility of updating the view before it is ready.
    func first(respond: RespondCallback)
    
    /// Accept an input from the consumer and respond in kind.
    /// - Throws: When an `Input` throws, `thrownError(_:)` is called with the respective `Error`
    func accept(_ input: Input, respond: @escaping RespondCallback) async throws

    /// Filter `Input` signals from being sent to the `ViewModel` until the respective `Input` operation has finished.
    ///
    /// Use Case: If a user sends an `addToBag` `Input`, and the "Add to bag" operation requires a network call, you can filter all subsequent `addToBag` `Input`s until the "Add to bag" operation completes.
    ///
    /// - Returns: `Input`s that should be filtered (default: no `Input`s are filtered)
    func filter() -> [Input]

    /// Filters all signals from being sent to `ViewModel` until last `Input` operation has finished.
    ///
    /// - Returns: `true` will filter all `Input`s (default: `false`)
    func filterAll() -> Bool

    /// Filter all signals from being sent to the `ViewModel` until specific `Input`s have finished.
    ///
    /// Use Case: If user sends `addToBag` `Input`, all other signals are ignored until the `addToBag` operation has completed.
    ///
    /// - Returns: `Input`s that should be filtered (default: no `Input`s are filtered)
    func filterAllInputs() -> [Input]

    /// Debounce `Input` signals for N seconds
    ///
    /// - Returns: `Debounce`s that filter specified `Input` (default: no `Input`s are debounced)

    func debounce() -> [Debounce<Input>]

    /// Ignore `Output`s from setting the state of an `Input` operation to "finished."
    ///
    /// Use Case: If filtering an `Input`, and you wish to show a progress bar to indicate that an `Input` is processing, this will filter the "show progress bar" `Output` (e.g. `showProgressBar(current: 0.5)`) from prematurely marking an `Input` operation as being "finished."
    ///
    /// When an `Input` operation is "finished", internally this cleans up filtering state allowing other `Input`s to be accepted. If your `Input` operation is in the middle of processing, but you wish to update the view with some type of progress, you may not want other `Input`s from processing!
    ///
    /// - Returns: `Output`s that should not set any `Input` operation to "finished" (default: no `Output`s are filtered)
    func filterOutputs() -> [Output]

    /// Returns a callback that can be used for async responses which are not directly related to an input. For example, a view model may listen to the user's signed in status. If a user signs in our out, the view model may want to send commands to the consumer informing them of the state change.
    ///
    /// NOTES:
    /// - Do NOT use the instance of this callback in `accept`. Otherwise, `Input` filter statuses will NOT be cleared!
    /// - The view model is expected to hold on to an instance of this callback for the duration of its lifetime
    /// - This is considered a configuration step, and, therefore, is called before `first`
    /// - Messages sent on this channel are not filtered or debounced
    func responder(respond: @escaping RespondCallback)

    /// Called when an operation bubbles up an `Error` from `accept(_:respond:)`.
    ///
    /// Use Case: This provides a way for vm to display an error if an `Input` operation failed. Please catch `Error`s where necessary. However, in many contexts, all you wish to do is bubble up the `Error` from some other operation. If you use the `Simple`
    func thrownError(_ error: Error, respond: @escaping RespondCallback)
}

/// Default implementations for optional behaviors
public extension ViewModel {
    func first(respond: RespondCallback) { }
    func filter() -> [Input] { [Input]() }
    func filterAll() -> Bool { false }
    func filterAllInputs() -> [Input] { [Input]() }
    func debounce() -> [Debounce<Input>] { [Debounce<Input>]() }
    func responder(respond: @escaping RespondCallback) { }
    func thrownError(_ error: Error, respond: @escaping RespondCallback) { }
    func filterOutputs() -> [Output] { [Output]() }
}
