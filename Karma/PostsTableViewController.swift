import UIKit
import SafariServices

class PostsTableViewController: UITableViewController, SFSafariViewControllerDelegate, UIViewControllerTransitioningDelegate {

    var posts = [Post]()
    let animator = SCModalPushPopAnimator()

    override func viewDidLoad() {
        super.viewDidLoad()

        Reddit.sharedInstance.frontpage { (posts, error) -> Void in
            if let error = error {
                print(error.localizedDescription)
                return
            }

            self.posts = posts!

            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.tableView.reloadData()
            })
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
        showSafariViewController(post.url)
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

    // MARK: - Custom Methods
    
    func showSafariViewController(url: NSURL){
        let safariViewController = PostSFSafariViewController(URL: url, entersReaderIfAvailable: true)
        safariViewController.delegate = self;
        safariViewController.transitioningDelegate = self
        self.presentViewController(safariViewController, animated: true) { () -> Void in
            let recognizer = UIScreenEdgePanGestureRecognizer(target: self, action: "handleGesture:")
            recognizer.edges = UIRectEdge.Left
            safariViewController.edgeView?.addGestureRecognizer(recognizer)
        }
    }

    func handleGesture(recognizer:UIScreenEdgePanGestureRecognizer) {
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
