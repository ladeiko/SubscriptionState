//
//  SubscriptionStateDemoTests.swift
//  SubscriptionStateDemoTests
//
//  Created by Siarhei Ladzeika on 10/3/19.
//  Copyright © 2019 Siarhei Ladzeika. All rights reserved.
//

import XCTest
import SubscriptionState
@testable import SubscriptionStateDemo

class SubscriptionStateDemoTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        XCTAssertFalse(SubscriptionState.shared.isSubscriptionActive())
        XCTAssertFalse(SubscriptionState.shared.isSubscriptionActive(for: ["a"]))
    }

}
