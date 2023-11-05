/// Copyright ⓒ 2023 Bithead LLC. All rights reserved.

import Foundation
import UIKit

extension UIView {
    var rootSuperview: UIView {
        var view: UIView = self
        while true {
            if let v = view.superview {
                view = v
            }
            else {
                break
            }
        }
        return view
    }

    /**
     Load view's respective nib.

     The following must be done for this to work:
       - The name of the xib must be the same name as the class
       - Set the File Owner's Custom Class property to the respective class
       - Leave the custom view Custom Class _empty_
       - Create outlets as usual. They should all be associated to the File Owner's

     Even though the constraints are set, the view itself (as well as the parent view), may require that the height of the view MUST be set. Especially when it is added to a `UIStackView` and the height is not yet known.
     */
    @discardableResult
    func fromNib() -> UIView? {
        let bundle = Bundle(for: type(of: self))
        let nibName = String(describing: type(of: self))
        let nib = UINib(nibName: nibName, bundle: bundle)
        guard let contentView = nib.instantiate(withOwner: self, options: nil).first as? UIView else {
            return nil
        }

        self.addSubview(contentView)
        contentView.constrainToAllSides(of: self)
        return contentView
    }

    func constrainToAllSides(of parent: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        leadingAnchor.constraint(equalTo: parent.safeAreaLayoutGuide.leadingAnchor, constant: 0).isActive = true
        topAnchor.constraint(equalTo: parent.safeAreaLayoutGuide.topAnchor, constant: 0).isActive = true
        trailingAnchor.constraint(equalTo: parent.safeAreaLayoutGuide.trailingAnchor, constant: 0).isActive = true
        bottomAnchor.constraint(equalTo: parent.safeAreaLayoutGuide.bottomAnchor, constant: 0).isActive = true
    }
}

// MARK: - Builders

extension UIView {
    @discardableResult
    func setIdentifier(_ id: ViewIdentifiable) -> Self {
        self.identifier = id
        return self
    }
}
