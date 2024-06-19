/// Copyright ⓒ 2023 Bithead LLC. All rights reserved.

import Foundation

/// Provides API for view to interact with its respective `ViewModel`
///
/// Internally, when async operations take place, the `Task` uses the `@MainActor`. This has the effect of showing the full call stack when receiving an `Output`. It also guarantees that vm operations take place on the main thread.
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

    public func send(_ input: T.Input, file: StaticString = #file, line: UInt32 = #line) {
        let name = inputName(for: input)
        let filterOutputs = viewModel.filterOutputs().map { (output: T.Output) -> String in
            inputName(for: output)
        }

        var isFiltered = false
        
        @Sendable
        func _send(_ input: T.Input, isFiltered: Bool) async {
            log.i("send(\(inputName(for: input))) from \(file):\(line)")

            do {
                try await viewModel.accept(input, respond: { [weak self] (output: T.Output) -> Void in
                    if !filterOutputs.contains(inputName(for: output)) {
                        self?.clearFilterStates(for: name, isFiltered: isFiltered)
                    }
                    self?.respond(output)
                })
            }
            catch ViewModelError.ignoreInput {
                log.i("Ignoring input (\(inputName(for: input)))")
                clearFilterStates(for: name, isFiltered: isFiltered)
            }
            catch {
                viewModel.thrownError(error, respond: { [weak self] (output: T.Output) in
                    self?.clearFilterStates(for: name, isFiltered: isFiltered)
                    self?.respond(output)
                })
            }
        }

        // Debounce `Input`.
        // Debouncing takes priority over all other `Input`s. Failing to do will cause certain configurations to never debounce `Input`s.
        if debouncedInputs.keys.contains(name) {
            let debouncer = debouncedInputs[name]
            debouncer?.debounce {
                // Using `MainActor` has the effect of showing the full callstack.
                Task { @MainActor [isFiltered] in
                    await _send(input, isFiltered: isFiltered)
                }
            }
            return
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

        // Using `MainActor` has the effect of showing the full callstack.
        Task { @MainActor [isFiltered] in
            await _send(input, isFiltered: isFiltered)
        }
    }

    private func clearFilterStates(for name: String, isFiltered: Bool) {
        isFilteringAllTests = false

        if isFiltered {
            if filterAllInputs.keys.contains(name) {
                filterAllInputs[name] = false
            }
            if filteredInputs.keys.contains(name) {
                filteredInputs[name] = false
            }
        }
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
