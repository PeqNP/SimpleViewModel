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
    private lazy var interface: ViewModelInterface<ProductViewModel> = .init(viewModel: .init(), receive: receive)

    private var productID: ProductID!

    func configure(productID: ProductID) {
        self.productID = productID
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        interface.send(.loadProduct(id: productID))
    }

    @objc
    private func didTapToast(_ sender: Any) {
        toastView.isHidden = true
    }

    @IBAction func didTapLikeButton(_ sender: Any) {
        interface.send(.didTapLike)
    }
}

extension ProductViewController {
    private func receive(output: ProductViewModel.Output) {
        switch output {
        case let .showError(error):
            toastLabel.text = String(describing: error)
            toastView.isHidden = false
        case let .viewState(state):
            productNameLabel.text = state.productName
            productPriceLabel.text = state.productPrice
            if state.isLiked {
                likeButton.setTitle("Liked", for: .normal)
            }
            else {
                likeButton.setTitle("Like", for: .normal)
            }
        case let .skus(skus):
            for sku in skus {
                let view = SKUView()
                view.awakeFromNib()
                view.configure(with: sku)
                // Pass-thru all of the view's output signals to our view model
                view.delegate = self
                skusStackView.addArrangedSubview(view)
            }
        case .addedToBag:
            toastLabel.text = "Successfully added product!"
            toastView.isHidden = false
        }
    }
}

extension ProductViewController: SKUViewDelegate {
    func receive(_ output: SKUViewModel.Output) {
        interface.send(.sku(output))
    }
}
