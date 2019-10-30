//
//  CheckObjCCompilation.m
//  SubscriptionStateDemoTests
//
//  Created by Sergey Ladeiko on 10/30/19.
//  Copyright © 2019 Siarhei Ladzeika. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SubscriptionState/SubscriptionState-Swift.h>

@interface MyCustomSubscriptionService1 : NSObject<SubscriptionStateObserver> {
    BOOL isPremium;
}
@end

// Check compilations only
@implementation MyCustomSubscriptionService1

-(instancetype)init {
    self = [super init];
    [[SubscriptionState shared] addObserver:self];
    [self updateState];
    return self;
}
    
- (void)dealloc {
    [[SubscriptionState shared] removeObserver:self];
}

    // MARK: - Helpers
    
- (void)updateState {
    isPremium = [[SubscriptionState shared] isSubscriptionActive];
}

// MARK: - SubscriptionStateObserver
        
- (void)subscriptionStateDidChangeTotalState:(SubscriptionState*)subscriptionState {
    [self updateState];
}

- (void)subscriptionStateDidChangeSomeState:(SubscriptionState*)subscriptionState {
    // TODO
}

@end

// Check compilations only
@interface MyCustomSubscriptionService2: NSObject {
    BOOL isPremium;
    NSArray<NSObject*>* observers;
}
@end

@implementation MyCustomSubscriptionService2

- (void)dealloc
{
    [observers enumerateObjectsUsingBlock:^(NSObject* obj, NSUInteger idx, BOOL *stop) {
        [[NSNotificationCenter defaultCenter] removeObserver: obj];
    }];
}

-(instancetype)init {
    
    self = [super init];
    
    void (^updateState)(void) = ^{
        self->isPremium = [[SubscriptionState shared] isSubscriptionActive];
    };

    observers = @[
        [[NSNotificationCenter defaultCenter] addObserverForName: NSNotification.SubscriptionTotalStateDidChangeNotification
                                                          object: [SubscriptionState shared]
                                                           queue: [NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification* notification) {
//            NSArray<NSString*>* const changedProductIdentifiers = [notification.userInfo objectForKey: SubscriptionState.subscriptionSomeStateDidChangeProductsKey];
            // TODO
        }],
        [[NSNotificationCenter defaultCenter] addObserverForName: NSNotification.SubscriptionSomeStateDidChangeNotification
                                                          object: [SubscriptionState shared]
                                                           queue: [NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification* notification) {
            updateState();
        }]
    ];

    updateState();
    return self;
}

@end
