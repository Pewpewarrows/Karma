import UIKit

let redditErrorDomain = NSBundle.mainBundle().bundleIdentifier!

class Reddit: NSObject {

    static let sharedInstance = Reddit()

    func subreddit(name: String? = nil, after: String? = nil, completionHandler: (posts: [Post]?, latestFullname: String?, error: NSError?) -> Void) {
        let components = NSURLComponents()
        components.scheme = "https"
        components.host = "www.reddit.com"

        if let name = name {
            components.path = "/r/\(name).json"
        } else {
            components.path = "/.json"
        }

        var queryItems: [NSURLQueryItem] = (components.queryItems ?? [])
        queryItems.append(NSURLQueryItem(name: "raw_json", value: "1"))

        if let after = after {
            queryItems.append(NSURLQueryItem(name: "after", value: after))
            queryItems.append(NSURLQueryItem(name: "limit", value: "100"))
        }

        components.queryItems = queryItems

        let request = NSURLRequest(URL: components.URL!)

        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            if let error = error {
                completionHandler(posts: nil, latestFullname: nil, error: error)
                return
            }

            // We can assume that this is an NSHTTPURLResponse
            guard let response = response as! NSHTTPURLResponse? else {
                fatalError("NSURLResponse was unexpectedly nil")
            }

            if response.statusCode != 200 {
                // TODO: investigate using enums for error codes
                completionHandler(posts: nil, latestFullname: nil, error: NSError(domain: redditErrorDomain, code: 1, userInfo: [
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
            let latestFullname = json["data"]["after"].stringValue

            completionHandler(posts: posts, latestFullname: latestFullname, error: nil)
        }

        task.resume()
    }

    func frontpage(after: String? = nil, completionHandler: (posts: [Post]?, latestFullname: String?, error: NSError?) -> Void) {
        return subreddit(after: after, completionHandler: completionHandler)
    }

}
