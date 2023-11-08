/// Copyright ⓒ 2023 Bithead LLC. All rights reserved.

import Foundation

/// Provides API for view to interact with its respective `ViewModel`
public class ViewModelInterface<T: ViewModel> {
    private let viewModel: T

    private let callback: (T.Output) -> Void
    private var filteredInputs = [String: Bool /* true when `Input` is "active" */]()
    private var debouncedInputs = [String: Debouncer]()

    public init(viewModel: T, receive: @escaping (T.Output) -> Void) {
        self.viewModel = viewModel
        self.callback = receive
        
        for input in viewModel.filter() {
            self.filteredInputs[inputName(for: input)] = false
        }
        for input in viewModel.debounce() {
            self.debouncedInputs[inputName(for: input.0)] = Debouncer(interval: input.1)
        }
        
        viewModel.first(respond: respond)
    }

    public func send(_ input: T.Input) {
        let name = inputName(for: input)
        var isFiltered = false
        
        func _send(_ input: T.Input) {
            viewModel.accept(input, respond: { [weak self] (output: T.Output) -> Void in
                if isFiltered {
                    self?.filteredInputs[name] = false
                }
                self?.respond(output)
            })
        }
        
        if filteredInputs.keys.contains(name) {
            guard !(filteredInputs[name] ?? false) else {
                return
            }
            isFiltered = true
            filteredInputs[name] = true
        }
        if debouncedInputs.keys.contains(name) {
            let debouncer = debouncedInputs[name]
            debouncer?.debounce {
                _send(input)
            }
            return
        }
        _send(input)
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
