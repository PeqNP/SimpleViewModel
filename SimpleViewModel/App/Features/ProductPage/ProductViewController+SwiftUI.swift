/// Copyright ⓒ 2023 Bithead LLC. All rights reserved.

import Foundation
import SwiftUI

/// Wraps the legacy ProductViewController into a SwiftUI controller
struct ProductController: UIViewControllerRepresentable {
    private let productID: ProductID

    init(productID: ProductID) {
        self.productID = productID
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> some UIViewController {
        let storyboard = UIStoryboard(name: "ProductViewController", bundle: Bundle(for: ProductViewController.self))
        guard let vc = storyboard.instantiateInitialViewController() as? ProductViewController else {
            fatalError("Failed to load view controller")
        }
        vc.configure(productID: productID)
        vc.modalPresentationStyle = .fullScreen
        return vc

    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {

    }

    class Coordinator: NSObject {
        let controller: ProductController

        init(_ controller: ProductController) {
            self.controller = controller
        }
    }
}
