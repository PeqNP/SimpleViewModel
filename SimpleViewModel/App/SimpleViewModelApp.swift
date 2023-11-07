/// Copyright ⓒ 2023 Bithead LLC. All rights reserved.

import SwiftUI

var globalAssembly: Assembly!

struct TestView: View {
    var body: some View {
        EmptyView()
    }
}

@main
struct SimpleViewModelApp: App {
    @State var runningTests = isRunningUnitTests()
    
    init() {
        // This assumes that the `Container` instance is internal to the `Foundation` module
        if !isRunningUnitTests() {
            globalAssembly = Assembly()
            setContainer(globalAssembly.container)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            if runningTests {
                TestView()
            }
            else {
                ContentView()
            }
        }
    }
}

func isRunningUnitTests() -> Bool {
#if DEBUG
    let env = ProcessInfo.processInfo.environment
    if let injectBundle = env["XCTestBundlePath"] {
        return NSString(string: injectBundle).pathExtension == "xctest"
    }
    return false
#else
    return false
#endif
}
