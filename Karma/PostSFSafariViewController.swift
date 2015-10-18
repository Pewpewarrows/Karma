import SafariServices
import UIKit

class PostSFSafariViewController: SFSafariViewController {

    private var _edgeView: UIView?
    var initialURL: NSURL!

    var edgeView: UIView? {
        get {
            if (_edgeView == nil && isViewLoaded()) {
                _edgeView = UIView()
                _edgeView?.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview(_edgeView!)
                _edgeView?.backgroundColor = UIColor(white: 1.0, alpha: 0.005)

                let bindings = ["edgeView": _edgeView!]
                let options = NSLayoutFormatOptions(rawValue: 0)
                let hConstraints = NSLayoutConstraint.constraintsWithVisualFormat("|-0-[edgeView(5)]", options: options, metrics: nil, views: bindings)
                let vConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[edgeView]-0-|", options: options, metrics: nil, views: bindings)

                view?.addConstraints(hConstraints)
                view?.addConstraints(vConstraints)
            }

            return _edgeView
        }
    }

    // MARK: - Initializers

    override init(URL: NSURL, entersReaderIfAvailable: Bool) {
        super.init(URL: URL, entersReaderIfAvailable: entersReaderIfAvailable)
        initialURL = URL
    }

    // MARK: - Preview actions

    override func previewActionItems() -> [UIPreviewActionItem] {
        return [
            UIPreviewAction(title: "Share", style: UIPreviewActionStyle.Default, handler: { (previewAction, viewController ) -> Void in
                guard let vc = viewController as? PostSFSafariViewController, url = vc.initialURL else { return }
                // TODO: it takes a relatively long time for the share controls to appear
                shareItem(url: url)
            })
        ]
    }
}
