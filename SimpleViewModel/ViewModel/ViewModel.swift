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

    /// This type is designed to remove ambiguity and make it obvious that an async response is expected when using a responder. This signature will not differ from `RespondCallback`.
    typealias AsyncRespondCallback = (Output) -> Void

    /// Allows the `ViewModel` to send a signal before any events may be accepted. This can be used to populate the default state of the view.
    func first(respond: RespondCallback)
    
    /// Accept an input from the consumer and respond in kind.
    /// - Throws: When an `Input` throws, `thrownError(_:)` is called with the respective `Error`
    func accept(_ input: Input, respond: @escaping RespondCallback) throws

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
}

public class Promise<T> {

    public typealias CompleteCallback = (Result<T, Error>) -> Void
    public typealias SuccessCallback = (T) -> Void
    public typealias FailureCallback = (Error) -> Void

    private var completeCallbacks = [CompleteCallback]()
    private var successCallbacks = [SuccessCallback]()
    private var failureCallbacks = [FailureCallback]()

    private var value: T?
    private var error: Error?

    deinit {
        completeCallbacks = []
        successCallbacks = []
        failureCallbacks = []
    }

    func success(_ value: T) {
        precondition(self.value == nil, "A Promise may not be resolved more than once")
        precondition(self.error == nil, "A Promise may not be resolved more than once")

        self.value = value
        resolveSuccess()
    }

    func failure(_ error: Error) {
        precondition(self.value == nil, "A Promise may not be resolved more than once")
        precondition(self.error == nil, "A Promise may not be resolved more than once")

        self.error = error
        resolveFailure()
    }

    public func onSuccess(callback: @escaping SuccessCallback) {
        successCallbacks.append(callback)
        resolveSuccess()
    }

    public func onFailure(callback: @escaping FailureCallback) {
        failureCallbacks.append(callback)
        resolveFailure()
    }

    public func onComplete(callback: @escaping CompleteCallback) {
        completeCallbacks.append(callback)
        resolveSuccess()
        resolveFailure()
    }

    private func resolveSuccess() {
        guard let value else {
            // Value has not yet been resolved
            return
        }
        for cb in successCallbacks {
            cb(value)
        }
        for cb in completeCallbacks {
            cb(Result.success(value))
        }
    }

    private func resolveFailure() {
        guard let error else {
            // Error has not yet been determined
            return
        }
        for cb in failureCallbacks {
            cb(error)
        }
        for cb in completeCallbacks {
            cb(Result.failure(error))
        }
    }
}

public extension ViewModel {
    func asyncTask<T>(callback: @escaping () throws -> T) -> Promise<T> {
        let promise = Promise<T>()
        Task {
            do {
                let value = try callback()
                promise.success(value)
            }
            catch {
                promise.failure(error)
            }
        }
        return promise
    }
}
