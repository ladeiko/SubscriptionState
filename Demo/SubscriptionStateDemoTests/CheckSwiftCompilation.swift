//
//  CheckSwiftCompilation.swift
//  SubscriptionStateDemoTests
//
//  Created by Sergey Ladeiko on 10/30/19.
//  Copyright © 2019 Siarhei Ladzeika. All rights reserved.
//

import SubscriptionState

// Check compilations only
class MyCustomSubscriptionService1: NSObject, SubscriptionStateObserver {

    private var observers: [NSObjectProtocol]!
    
    var isPremium: Bool = false {
        didSet {
            // TODO notify others
        }
    }
            
    deinit {
        SubscriptionState.shared.removeObserver(self)
    }

    override init() {
        super.init()
        SubscriptionState.shared.addObserver(self)
        updateState()
    }
    
    // MARK: - Helpers
    
    func updateState() {
        self.isPremium = SubscriptionState.shared.isSubscriptionActive()
    }

    // MARK: - SubscriptionStateObserver
        
    func subscriptionStateDidChangeTotalState(_ subscriptionState: SubscriptionState) {
        updateState()
    }
        
    func subscriptionStateDidChangeSomeState(_ subscriptionState: SubscriptionState) {
        // TODO
    }
}

// Check compilations only
class MyCustomSubscriptionService2 {

    private var observers: [NSObjectProtocol]!
    
    var isPremium: Bool = false {
        didSet {
            // TODO notify others
        }
    }
            
    deinit {
            observers.forEach { NotificationCenter.default.removeObserver($0) }
       }

    init() {
        
        func updateState() {
            self.isPremium = SubscriptionState.shared.isSubscriptionActive()
        }
        
        observers = [
            NotificationCenter.default.addObserver(forName: .subscriptionSomeStateDidChange,                                     object: SubscriptionState.shared, queue: .main) { (notification) in
                //let changedProductIdentifiers = notification.userInfo?[SubscriptionState.subscriptionSomeStateDidChangeProductsKey] as? [String]
                // TODO
            },
        
            NotificationCenter.default.addObserver(forName: .subscriptionTotalStateDidChange,
                            object: SubscriptionState.shared, queue: .main) { (_) in
                updateState()
            }
        ]
        
        updateState()
    }
    
}
