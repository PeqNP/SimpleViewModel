/// Copyright ⓒ 2023 Bithead LLC. All rights reserved.

import Foundation

/// Provides API for a view to interact with its respective `ViewModel`
class ViewModelInterface<T: ViewModel> {
    let viewModel: T

    private var callback: (T.Output) -> Void = { _ in }

    init(viewModel: T) {
        self.viewModel = viewModel
    }

    func send(_ input: T.Input) {
        viewModel.accept(input, respond: respond)
    }

    func receive(callback: @escaping (T.Output) -> Void) {
        self.callback = callback
    }

    private func respond(with output: T.Output) {
        // This is intended to always be used by `UIKit` elements. Therefore, ensure signal is always returned on the main thread. This ensures UI elements can update state immediately w/o switching to main thread first. This will also prevent crashes.
        if Thread.isMainThread {
            callback(output)
        }
        else {
            DispatchQueue.main.async { [weak self] in
                self?.callback(output)
            }
        }
    }
}
