# SimpleViewModel

A simple, robust, view model pattern.

- No "infinite sink" when debugging (e.g. `RxSwift`). Know where a signal originates from.
- Easily pass-thru child signals to parent view models. No complicated wiring. Use delegation, a pattern that has been used for decades.
- Dependency injection
- Easy to change
- Easy to test

## Introduction

This view model pattern builds on top of tried and true patterns that have been around for decades. It doesn't try to be "smart", just functional.

Here is an example of a parent view controller interfacing with its view model.

```swift
class ProductViewController: UIViewController {

    // ... Outlets

    // If no configuration is required by view model, instantiate here. It may be necessary to instantiate this in `configure` or even `viewDidLoad`. It's up to you.
    private let interface: ViewModelInterface<ProductViewModel> = .init(viewModel: .init())

    private var productID: ProductID!

    func configure(productID: ProductID) {
        self.productID = productID
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Receive before any signals are sent! This ensures no view signal is lost.
        interface.receive { [weak self] msg in
            switch msg {
            case let .showError(error):
                self?.showError(error)
                break
            case let .loadedProduct(product):
                self?.updateView(with: product)
                break
            case .addedToBag:
                self?.showAddedToBag()
            }
        }
        interface.send(.loadProduct(id: productID))
    }

    // private func showError(_ error: Error)

    private func updateView(with product: Product) {
        productNameLabel.text = product.name
        productPriceLabel.text = product.price.toString
        for sku in product.skus {
            let view = SKUView()
            view.awakeFromNib()
            view.configure(with: sku)
            // Pass-thru all of the view's output signals to our view model
            view.delegate = self
            skusStackView.addArrangedSubview(view)
        }
    }

    // private func showAddedToBag()

    @objc
    private func didTapToast(_ sender: Any) {
        toastView.isHidden = true
    }
}

extension ProductViewController: SKUViewDelegate {
    func receive(_ output: SKUViewModel.Output) {
        // Pass-thru child `Output` to our `ViewModel`
        interface.send(.sku(output))
    }
}
```

The view model.

```swift
/// Copyright ⓒ 2023 Bithead LLC. All rights reserved.

import Foundation

class ProductViewModel: ViewModel {
    enum Input {
        case loadProduct(id: ProductID)
        case didTapLike

        // This is how we compose child view models
        case sku(SKUViewModel.Output)
    }

    enum Output {
        case loadedProduct(Product)
        case addedToBag
        case likeStatus(on: Bool)
        case showError(Error)
    }

    func accept(_ input: Input, respond: (Output) -> Void) {
        switch input {
        case let .loadProduct(id):
            // NOTE: A network request would be here
            respond(.loadedProduct(
                .init(
                    id: id,
                    name: "Name",
                    price: .single(.regular(10)),
                    skus: [
                        .init(
                            id: "1",
                            color: .init(name: "Red", imageURL: nil),
                            size: .init(name: "L", metaDescription: nil),
                            price: .regular(10)
                        )
                    ]
                )
            ))
        case .didTapLike:
            break // Make network request to like `Product`
        case let .sku(msg):
            switch msg {
            case .addedToBag:
                respond(.addedToBag)
                break
            }
        }
    }
}
```
