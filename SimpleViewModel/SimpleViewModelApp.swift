/// Copyright ⓒ 2023 Bithead LLC. All rights reserved.

import SwiftUI

var globalAssembly = Assembly()

@main
struct SimpleViewModelApp: App {
    init() {
        // This assumes that the `Container` instance is internal to the `Foundation` module
        setContainer(globalAssembly.container)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
