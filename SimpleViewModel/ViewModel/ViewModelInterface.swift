/// Copyright ⓒ 2023 Bithead LLC. All rights reserved.

import Foundation

/// Provides API for view to interact with its respective `ViewModel`
class ViewModelInterface<T: ViewModel> {
    let viewModel: T

    private let callback: (T.Output) -> Void
    private var filteredInputs: [String: Bool /* true when `Input` is "active" */]

    init(viewModel: T, receive: @escaping (T.Output) -> Void) {
        self.viewModel = viewModel
        self.callback = receive
        
        let filteredInputs = viewModel.filter().map {
            inputName(for: $0)
        }
        self.filteredInputs = filteredInputs.reduce(into: [String: Bool]()) {
            $0[$1] = false
        }
        
        viewModel.first(respond: respond)
    }

    func send(_ input: T.Input) {
        let name = inputName(for: input)
        var isFiltered = false
        if filteredInputs.keys.contains(name) {
            guard !(filteredInputs[name] ?? false) else {
                return
            }
            isFiltered = true
            filteredInputs[name] = true
        }
        viewModel.accept(input, respond: { [weak self] (output: T.Output) -> Void in
            if isFiltered {
                self?.filteredInputs[name] = false
            }
            self?.respond(output)
        })
    }

    private func respond(_ output: T.Output) {
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

private func inputName(for input: Any) -> String {
    var name = String(describing: input)
    if let dotRange = name.range(of: "(") {
        name.removeSubrange(dotRange.lowerBound..<name.endIndex)
    }
    return name
}
