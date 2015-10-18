import UIKit

func shareItem(text text: String? = nil, image: UIImage? = nil, url: NSURL? = nil) {
    var sharingItems = [AnyObject]()

    if let text = text {
        sharingItems.append(text)
    }
    if let image = image {
        sharingItems.append(image)
    }
    if let url = url {
        sharingItems.append(url)
    }

    let activityViewController = UIActivityViewController(activityItems: sharingItems, applicationActivities: nil)
    // We need a global shareItem since callers (such as SFSafariViewController) might not be on the view stack, which means self.presentViewController won't work
    UIApplication.sharedApplication().delegate!.window!!.rootViewController!.presentViewController(activityViewController, animated: true, completion: nil)
}