/// Copyright ⓒ 2023 Bithead LLC. All rights reserved.

import Foundation
import UIKit

class ProductViewController: UIViewController {

    @IBOutlet weak var productNameLabel: UILabel!
    @IBOutlet weak var productPriceLabel: UILabel!
    @IBOutlet weak var skusStackView: UIStackView!
    @IBOutlet weak var toastView: UIStackView! {
        didSet {
            toastView.backgroundColor = .green
            toastView.layer.cornerRadius = 5
            toastView.isHidden = true

            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapToast(_:)))
            toastView.addGestureRecognizer(tapGesture)
            toastView.isUserInteractionEnabled = true
        }
    }
    @IBOutlet weak var toastLabel: UILabel!
    
    private var interface: ViewModelInterface<ProductViewModel>!

    private var productID: ProductID!

    func configure(productID: ProductID) {
        self.productID = productID
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Creating the ViewModel must be done in viewDidLoad so that no view signals are lost
        interface = .init(viewModel: .init())
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

    private func showError(_ error: Error) {
        toastLabel.text = String(describing: error)
        toastView.isHidden = false
    }

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

    private func showAddedToBag() {
        toastLabel.text = "Successfully added product!"
        toastView.isHidden = false
    }

    @objc
    private func didTapToast(_ sender: Any) {
        toastView.isHidden = true
    }
}

extension ProductViewController: SKUViewDelegate {
    func receive(_ output: SKUViewModel.Output) {
        interface.send(.sku(output))
    }
}
