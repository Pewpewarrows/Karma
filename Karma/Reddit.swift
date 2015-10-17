import UIKit

let redditErrorDomain = NSBundle.mainBundle().bundleIdentifier!

class Reddit: NSObject {

    static let sharedInstance = Reddit()
    let baseURL = NSURL(string: "https://www.reddit.com")

    func frontpage(completionHandler: (posts: [Post]?, error: NSError?) -> Void) {
        let request = NSURLRequest(URL: NSURL(string: "/.json", relativeToURL: baseURL)!)

        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            if let error = error {
                completionHandler(posts: nil, error: error)
                return
            }

            // We can assume that this is an NSHTTPURLResponse
            guard let response = response as! NSHTTPURLResponse? else {
                fatalError("NSURLResponse was unexpectedly nil")
            }

            if response.statusCode != 200 {
                // TODO: investigate using enums for error codes
                completionHandler(posts: nil, error: NSError(domain: redditErrorDomain, code: 1, userInfo: [
                    NSLocalizedDescriptionKey: NSHTTPURLResponse.localizedStringForStatusCode(response.statusCode)
                ]))
                return
            }

            guard let data = data else {
                fatalError("data was unexpectedly nil")
            }

            let json = JSON(data: data)
            var posts = [Post]()
            for jsonPost in json["data"]["children"].arrayValue {
                let post = Post()
                post.title = jsonPost["data"]["title"].stringValue
                post.url = NSURL(string: jsonPost["data"]["url"].stringValue)
                posts.append(post)
            }

            completionHandler(posts: posts, error: nil)
        }

        task.resume()
    }

}
