/// Copyright ⓒ 2023 Bithead LLC. All rights reserved.

import Foundation

/// Provides API for view to interact with its respective `ViewModel`
public class ViewModelInterface<T: ViewModel> {
    private let viewModel: T

    private let callback: (T.Output) -> Void
    private var filterAllInputs = [String: Bool /* true when `Input` is active */]()
    private var filteredInputs = [String: Bool /* true when `Input` is "active" */]()
    private var debouncedInputs = [String: Debouncer]()
    private var isFilteringAllTests: Bool = false

    public init(viewModel: T, receive: @escaping (T.Output) -> Void) {
        self.viewModel = viewModel
        self.callback = receive
        
        for input in viewModel.filterAllInputs() {
            self.filterAllInputs[inputName(for: input)] = false
        }
        for input in viewModel.filter() {
            self.filteredInputs[inputName(for: input)] = false
        }
        for input in viewModel.debounce() {
            self.debouncedInputs[inputName(for: input.input)] = Debouncer(interval: input.interval)
        }
        
        viewModel.responder { [weak self] (output: T.Output) -> Void in
            self?.respond(output)
        }
        viewModel.first(respond: respond)
    }

    public func send(_ input: T.Input) {
        let name = inputName(for: input)
        var isFiltered = false
        
        func _send(_ input: T.Input) {
            viewModel.accept(input, respond: { [weak self] (output: T.Output) -> Void in
                self?.isFilteringAllTests = false

                if isFiltered {
                    if self?.filterAllInputs.keys.contains(name) ?? false {
                        self?.filterAllInputs[name] = false
                    }
                    if self?.filteredInputs.keys.contains(name) ?? false {
                        self?.filteredInputs[name] = false
                    }
                }
                self?.respond(output)
            })
        }

        // Filter all `Input`s if there is any other `Input` in-flight
        if viewModel.filterAll() {
            // An `Input` is currently in-flight
            if isFilteringAllTests {
                return
            }
            isFilteringAllTests = true
        }

        // Ignore all signals if an `Input` is in-flight and it filters all other `Input`
        let isFilteringAllInputs = filterAllInputs.first(where: { kv in kv.value }) != nil
        guard !isFilteringAllInputs else {
            return
        }
        if filterAllInputs.keys.contains(name) {
            isFiltered = true
            filterAllInputs[name] = true
        }

        // Determine if this specific `Input` is in-flight
        if filteredInputs.keys.contains(name) {
            guard !(filteredInputs[name] ?? false) else {
                return
            }
            isFiltered = true
            filteredInputs[name] = true
        }

        // Debounce `Input`
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
