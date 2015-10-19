import UIKit
import SafariServices

class PostsTableViewController: UITableViewController, SFSafariViewControllerDelegate, UIViewControllerTransitioningDelegate, UIViewControllerPreviewingDelegate {

    var posts = [Post]()
    let animator = SCModalPushPopAnimator()
    // TODO: allow navigating to the actual "frontpage" subreddit, store our state internally better
    var currentSubreddit = "frontpage"

    override func viewDidLoad() {
        super.viewDidLoad()

        if traitCollection.forceTouchCapability == .Available {
            registerForPreviewingWithDelegate(self, sourceView: view)
        }

        reloadData()
    }

    override func didMoveToParentViewController(parent: UIViewController?) {
        super.didMoveToParentViewController(parent)

        if parent != nil && self.navigationItem.titleView == nil {
            updateNavigationItemTitleView()
        }
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("postCell", forIndexPath: indexPath)

        let post = posts[indexPath.row]
        cell.textLabel!.text = post.title

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let post = posts[indexPath.row]
        let safariViewController = safariViewControllerForURL(post.url)
        presentSafariViewController(safariViewController)
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }

    // MARK: - SFSafariViewControllerDelegate

    func safariViewControllerDidFinish(controller: SFSafariViewController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: - UIViewControllerTransitioningDelegate

    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        animator.dismissing = false
        return animator
    }

    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        animator.dismissing = true
        return animator
    }

    func interactionControllerForDismissal(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return self.animator.percentageDriven ? self.animator : nil
    }

    // MARK: - UIViewControllerPreviewingDelegate

    // "peek"
    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = tableView.indexPathForRowAtPoint(location), cell = tableView.cellForRowAtIndexPath(indexPath) else {
            return nil
        }

        previewingContext.sourceRect = cell.frame

        let post = posts[indexPath.row]
        let safariViewController = safariViewControllerForURL(post.url)

        return safariViewController
    }

    // "pop"
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        if let vc = viewControllerToCommit as? PostSFSafariViewController {
            presentSafariViewController(vc)
        } else {
            showViewController(viewControllerToCommit, sender: self)
        }
    }

    // MARK: - Actions

    @IBAction func pullToRefresh(sender: UIRefreshControl) {
        reloadData({ () -> Void in
            // TODO: should the formatter be a class variable?
            let ptrDateFormatter = NSDateFormatter()
            ptrDateFormatter.dateFormat = "MMM d, h:mm a"
            sender.attributedTitle = NSAttributedString(string: String.localizedStringWithFormat("Last update: %@", ptrDateFormatter.stringFromDate(NSDate())))
            sender.endRefreshing()
        }, errorCallback: { () -> Void in
            sender.endRefreshing()
        })
    }

    // MARK: - Internal Methods

    func reloadData(successCallback: (() -> Void)? = nil, errorCallback: (() -> Void)? = nil) {
        func completionHandler(posts: [Post]?, error: NSError?) {
            if let error = error {
                print(error.localizedDescription)
                errorCallback?()
                return
            }

            self.posts = posts!

            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.tableView.reloadData()
                successCallback?()
            })
        }

        if currentSubreddit == "frontpage" {
            Reddit.sharedInstance.frontpage(completionHandler)
        } else {
            Reddit.sharedInstance.subreddit(currentSubreddit, completionHandler: completionHandler)
        }
    }

    func updateNavigationItemTitleView() {
        let titleView = UILabel()
        titleView.text = currentSubreddit == "frontpage" ? "Frontpage" : currentSubreddit
        titleView.font = UIFont.boldSystemFontOfSize(17)
        let width = titleView.sizeThatFits(CGSizeMake(CGFloat.max, CGFloat.max)).width
        titleView.frame = CGRect(origin:CGPointZero, size:CGSizeMake(width, 500))
        self.navigationItem.titleView = titleView

        let recognizer = UITapGestureRecognizer(target: self, action: "titleWasTapped")
        titleView.userInteractionEnabled = true
        titleView.addGestureRecognizer(recognizer)
    }

    func titleWasTapped() {
        let defaultSubreddit = "all"
        let alert = UIAlertController(title: "Subreddit", message: "Enter the name of a subreddit to visit:", preferredStyle: UIAlertControllerStyle.Alert)
        var inputTextField: UITextField?

        alert.addTextFieldWithConfigurationHandler { (textField) -> Void in
            textField.placeholder = defaultSubreddit
            inputTextField = textField
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        let defaultAction = UIAlertAction(title: "Go", style: UIAlertActionStyle.Default) { (action) -> Void in
            guard let inputTextField = inputTextField else { return }
            let subreddit = inputTextField.text ?? defaultSubreddit
            self.changeToSubreddit(subreddit)
        }

        alert.addAction(cancelAction)
        alert.addAction(defaultAction)

        presentViewController(alert, animated: true, completion: nil)
    }

    func changeToSubreddit(subreddit: String) {
        let previousSubreddit = currentSubreddit
        currentSubreddit = subreddit

        reloadData({ () -> Void in
            self.updateNavigationItemTitleView()
        }, errorCallback: { () -> Void in
            self.currentSubreddit = previousSubreddit
        })
    }

    func safariViewControllerForURL(url: NSURL) -> PostSFSafariViewController {
        let safariViewController = PostSFSafariViewController(URL: url, entersReaderIfAvailable: true)
        safariViewController.delegate = self;
        safariViewController.transitioningDelegate = self

        return safariViewController
    }
    
    func presentSafariViewController(safariViewController: PostSFSafariViewController) {
        presentViewController(safariViewController, animated: true) { () -> Void in
            let recognizer = UIScreenEdgePanGestureRecognizer(target: self, action: "handleGesture:")
            recognizer.edges = UIRectEdge.Left
            safariViewController.edgeView?.addGestureRecognizer(recognizer)
        }
    }

    func handleGesture(recognizer: UIScreenEdgePanGestureRecognizer) {
        self.animator.percentageDriven = true
        let percentComplete = recognizer.locationInView(view).x / view.bounds.size.width / 2.0
        switch recognizer.state {
        case .Began: dismissViewControllerAnimated(true, completion: nil)
        case .Changed: animator.updateInteractiveTransition(percentComplete > 0.99 ? 0.99 : percentComplete)
        case .Ended, .Cancelled:
            (recognizer.velocityInView(view).x < 0) ? animator.cancelInteractiveTransition() : animator.finishInteractiveTransition()
            self.animator.percentageDriven = false
        default: ()
        }
    }

}
