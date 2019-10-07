//
//  Purchase.swift
//  SubscriptionState
//
//  Created by Siarhei Ladzeika on 10/3/19.
//  Copyright © 2019 Siarhei Ladzeika. All rights reserved.
//

internal class Purchase {
    
    let productIdentifier: String
    let purchased: Date
    let expires: Date
    
    private let revalidate: (() -> Void)
    private weak var timer: Timer?
    
    init(now: Date,
         productIdentifier: String,
         purchased: Date,
         expires: Date,
         revalidate: @escaping (() -> Void))
    {
        self.productIdentifier = productIdentifier
        self.purchased = purchased
        self.expires = expires
        self.revalidate =  revalidate
        if now < expires {
            assert(Thread.isMainThread)
            self.timer = Timer.scheduledTimer(withTimeInterval: expires.timeIntervalSince(now), repeats: false) { [weak self] (_) in
                #if DEBUG
                print("SubscriptionState: timer fired for", Date(), self)
                #endif
                self?.revalidate()
            }
        }
    }
    
    func stop() {
        timer?.invalidate()
    }
    
    deinit {
        timer?.invalidate()
    }
}

extension Purchase: CustomStringConvertible {
    var description: String {
        return "[\n productIdentifier = \(productIdentifier)\n purchased = \(purchased)\n expires = \(expires)\n timer = \(timer != nil)\n]"
    }
}
