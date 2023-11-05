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
    @IBOutlet weak var likeButton: UIButton!
    
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
            case let .update(state):
                self?.updateView(with: state)
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

    private func updateView(with state: ProductViewModel.ViewState) {
        productNameLabel.text = state.productName
        productPriceLabel.text = state.productPrice
        if state.isLiked {
            likeButton.setTitle("Liked", for: .normal)
        }
        else {
            likeButton.setTitle("Like", for: .normal)
        }

        // SKUs do not necessarily need to be part of the `ViewState`. For example, when changing the "Like" button status, is it really necessary to redraw all of the `SKUView`s? No. These could be two separate signals. OR, an alternative is to do this only once.
        skusStackView.removeAllArrangedSubviews()
        
        for sku in state.skus {
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

    @IBAction func didTapLikeButton(_ sender: Any) {
        interface.send(.didTapLike)
    }
}

extension ProductViewController: SKUViewDelegate {
    func receive(_ output: SKUViewModel.Output) {
        interface.send(.sku(output))
    }
}
