/// Copyright ⓒ 2023 Bithead LLC. All rights reserved.

import SwiftUI

struct ContentView: View {
    @State private var presentProduct = false

    var body: some View {
        VStack {
            Button("Load Product") {
                self.presentProduct = true
            }
            .sheet(isPresented: $presentProduct) {
                ProductView(productID: "1")
            }
        }
        .padding()
    }
}

struct ProductView: View {
    private let productID: ProductID

    init(productID: ProductID) {
        self.productID = productID
    }

    var body: some View {
        ProductController(productID: productID)
    }
}

#Preview {
    ContentView()
}
