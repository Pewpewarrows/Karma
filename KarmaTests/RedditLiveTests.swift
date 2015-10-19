@testable import Karma
import XCTest

class RedditLiveTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSharedInstance() {
        XCTAssertNotNil(Reddit.sharedInstance)
    }

    func testFrontpage() {
        let expectation = expectationWithDescription("Reddit Frontpage")

        Reddit.sharedInstance.frontpage { (posts, latestFullname, error) -> Void in
            XCTAssertNil(error)
            if let posts = posts {
                XCTAssertGreaterThan(posts.count, 0)
            }
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(2.0, handler: nil)
    }

}
