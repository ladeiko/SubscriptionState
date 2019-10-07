//
//  SubscriptionStateDemoTestsObjC.m
//  SubscriptionStateDemoTests
//
//  Created by Siarhei Ladzeika on 10/3/19.
//  Copyright © 2019 Siarhei Ladzeika. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <SubscriptionState/SubscriptionState-Swift.h>

@interface SubscriptionStateDemoTestsObjC : XCTestCase

@end

@implementation SubscriptionStateDemoTestsObjC

- (void)setUp {
    
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    XCTAssertFalse([[SubscriptionState shared] isSubscriptionActiveFor:nil]);
    XCTAssertFalse([[SubscriptionState shared] isSubscriptionActiveFor:@[@"aaa"]]);
}

@end
