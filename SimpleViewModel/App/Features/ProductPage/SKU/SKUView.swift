/// Copyright ⓒ 2023 Bithead LLC. All rights reserved.

import Foundation
import UIKit

protocol SKUViewDelegate: AnyObject {
    func receive(_ output: SKUViewModel.Output)
}

class SKUView: UIView {
    @IBOutlet weak var colorLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!

    private var interface: ViewModelInterface<SKUViewModel>!

    weak var delegate: SKUViewDelegate?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    func configure(with sku: SKU) {
        interface = .init(viewModel: .init(sku: sku), receive: receive)
    }
    
    private func receive(output: SKUViewModel.Output) {
        // Let parent know our current state
        delegate?.receive(output)
        
        switch output {
        case let .viewState(state):
            colorLabel.text = state.color
            priceLabel.text = state.price
        case .addedToBag:
            // TODO: Display a checkmark on the 'Add' button
            break
        }
    }

    private func setup() {
        fromNib()
    }

    @IBAction func didTapAddButton(_ sender: Any) {
        interface.send(.addToBag)
    }
}
