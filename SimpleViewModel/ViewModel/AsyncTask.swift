/// Copyright ⓒ 2024 Bithead LLC. All rights reserved.

import Foundation

/// Represents an asynchronous task (i.e. a "promise")
///
/// This is actually a "promise". I decided against naming it `Promise` to avoid name collisions with other libraries. It also matches the name of the function that extends `ViewModel`.
public class AsyncTask<T> {
    public typealias CompleteCallback = (Result<T, Error>) -> Void
    public typealias SuccessCallback = (T) -> Void
    public typealias FailureCallback = (Error) -> Void

    private var completeCallbacks = [CompleteCallback]()
    private var successCallbacks = [SuccessCallback]()
    private var failureCallbacks = [FailureCallback]()

    private var value: T?
    private var error: Error?

    private(set) var fulfilled: Bool = false

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

    @discardableResult
    public func onSuccess(callback: @escaping SuccessCallback) -> Self {
        successCallbacks.append(callback)
        resolveSuccess()
        return self
    }

    @discardableResult
    public func onFailure(callback: @escaping FailureCallback) -> Self {
        failureCallbacks.append(callback)
        resolveFailure()
        return self
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
        fulfilled = true
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
        fulfilled = true
    }
}

public extension ViewModel {
    /// Executes async tasks and returns an `AsyncTask` with result
    @discardableResult
    func asyncTask<T>(callback: @escaping () async throws -> T) -> AsyncTask<T> {
        let promise = AsyncTask<T>()
        Task {
            do {
                let value = try await callback()
                promise.success(value)
            }
            catch {
                promise.failure(error)
            }
        }
        return promise
    }
}
