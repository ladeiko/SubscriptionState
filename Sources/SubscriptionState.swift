//
//  SubscriptionState.swift
//  SubscriptionState
//
//  Created by Siarhei Ladzeika on 10/3/19.
//  Copyright © 2019 Siarhei Ladzeika. All rights reserved.
//

import TrueTime
import TPInAppReceipt
import StoreKit
import Valet
import SwiftSelfAware

extension NSNotification.Name {
    public static let subscriptionTotalStateDidChange: NSNotification.Name = NSNotification.Name("subscriptionTotalStateDidChange")
    public static let subscriptionSomeStateDidChange: NSNotification.Name = NSNotification.Name("subscriptionSomeStateDidChange")
}

public typealias SubscriptionStateDateResolver = () -> Date

@objc
public class SubscriptionState: NSObject {
    
    // MARK: - Public
    
    public static let subscriptionSomeStateDidChangeProductsKey = "productIdentifiers"
    
    @objc
    public static let shared = SubscriptionState()
    
    @objc
    public var graceTimeInterval: TimeInterval = 0 {
        didSet {
            assert(graceTimeInterval >= 0)
            assert(Thread.isMainThread)
            if graceTimeInterval != oldValue {
                revalidate()
            }
        }
    }
    
    @objc
    public var customDateResolver: SubscriptionStateDateResolver? {
        didSet {
            assert(Thread.isMainThread)
            revalidate()
        }
    }
    
    @objc
    public func isSubscriptionActive(for productIdentifiers: [String]? = nil) -> Bool {
        return onMain {
            return productIdentifiers == nil ?
                self.totalSubscribed
                    : productIdentifiers!.contains(where: { self.subscribed.contains($0) })
        }
    }
    
    @objc
    public var lifetimeProductIdentifiers: Set<String> {
        get {
            
            guard let str = valet.string(forKey: lifetimeProductIdentifiersKey) else {
                return Set<String>()
            }
            
            let lifetimeProductIdentifiers = str
                .split(separator: ",")
                .map{ $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            return Set<String>(lifetimeProductIdentifiers)
        }
        set {
            valet.set(string: String(Array(newValue).joined(separator: ",")), forKey: lifetimeProductIdentifiersKey)
            self.revalidate()
        }
    }
    
    @objc
    public var activeProducts: [String] {
        return onMain {
            return Array(self.subscribed)
        }
    }
    
    // MARK: - Helpers
    
    private func revalidate() {
        
        let lifetimeProductIdentifiers = self.lifetimeProductIdentifiers
        let rawPurchases: [[String: String]]? = {
            do {
                let receipt = try InAppReceipt.localReceipt()
                return receipt.purchases
                    .filter { $0.subscriptionExpirationDate != nil}
                    .compactMap {
                        if $0.subscriptionExpirationDate != nil {
                            return [
                                "productIdentifier": $0.productIdentifier,
                                "purchased": String($0.purchaseDate.timeIntervalSince1970),
                                "expires": String($0.subscriptionExpirationDate!.timeIntervalSince1970),
                            ]
                        }
                        else if lifetimeProductIdentifiers.contains($0.productIdentifier) {
                            return [
                                "productIdentifier": $0.productIdentifier,
                                "purchased": String($0.purchaseDate.timeIntervalSince1970),
                                "expires": "0",
                            ]
                        }
                        else {
                            return nil
                        }
                    }
            } catch {
                
                #if DEBUG
                print(error)
                #endif
                
                if let saved = valet.string(forKey: purchasesKey),
                    let jsonData = Data(base64Encoded: saved),
                    let json = try? JSONDecoder().decode([[String: String]].self, from: jsonData) {
                    return json.filter({
                        return $0["productIdentifier"] != nil
                            && $0["purchased"] != nil && TimeInterval($0["purchased"]!) != nil
                            && $0["expires"] != nil && TimeInterval($0["expires"]!) != nil
                    })
                }
            }
            
            return nil
        }()
        
        onMain { () -> Void in
            
            let now = self.now
            
            self.purchases?.forEach({ $0.stop() })
            
            if let rawPurchases = rawPurchases {
                self.purchases = rawPurchases.map {
                    let expires = TimeInterval($0["expires"]!)!
                    return Purchase(now: now,
                             productIdentifier: $0["productIdentifier"]!,
                             purchased: Date(timeIntervalSince1970: TimeInterval($0["purchased"]!)!),
                             expires: expires > 0 ? (Date(timeIntervalSince1970: expires) + self.graceTimeInterval) : Date(timeIntervalSince1970: 0),
                             revalidate: {[weak self] in self?.revalidate() })
                }
            }
            else {
                self.purchases = nil
            }
            
            let lifetimeProductIdentifiers = self.lifetimeProductIdentifiers
            self.subscribed = (self.purchases ?? [Purchase]()).reduce(into: Set<String>(), {
                guard !$0.contains($1.productIdentifier) && ((($1.purchased <= now) && (now < $1.expires)) || (lifetimeProductIdentifiers.contains($1.productIdentifier))) else {
                    return
                }
                $0.insert($1.productIdentifier)
            })
        }

    }
    
    private var now: Date {
        assert(Thread.isMainThread)
        return customDateResolver?() ?? self.client.referenceTime?.now() ?? Date()
    }
    
    private override init() {
        super.init()
        
        observers = [
            NSNotification.Name.NSSystemTimeZoneDidChange,
            NSNotification.Name.NSSystemClockDidChange
            ].map {
                NotificationCenter.default.addObserver(forName: $0, object: nil, queue: .main) { [weak self] (_) in
                    self?.revalidate()
                }
            }
        
        SKPaymentQueue.default().add(self)
        
        client.start()
        client.fetchIfNeeded { result in
            switch result {
            case .success:
                self.onMain { () -> Void in
                    self.revalidate()
                }
            case let .failure(error):
                #if DEBUG
                print(error)
                #endif
                break
            }
        }
        
        revalidate()
    }
    
    deinit {
        SKPaymentQueue.default().remove(self)
        client.pause()
        observers?.forEach({ NotificationCenter.default.removeObserver($0) })
    }

    private let purchasesKey = "purchases"
    private let lifetimeProductIdentifiersKey = "lifetimeProductIdentifiers"
    private let valet = Valet.valet(with: Identifier(nonEmpty: "SubscriptionState")!, accessibility: .whenUnlocked)
    private let client = TrueTimeClient.sharedInstance
    private var purchases: [Purchase]? {
        didSet {
            if let purchases = purchases,
                let data = try? JSONEncoder().encode(purchases.map({ purchase -> [String: String] in
                    return [
                        "productIdentifier": purchase.productIdentifier,
                        "purchased": String(purchase.purchased.timeIntervalSince1970),
                        "expires": String(purchase.expires.timeIntervalSince1970),
                    ]
                }))
            {
                valet.set(string: data.base64EncodedString(), forKey: purchasesKey)
            }
            else {
                valet.removeObject(forKey: purchasesKey)
            }
        }
    }
    private var observers: [NSObjectProtocol]?
    private var totalSubscribed = false {
        didSet {
            assert(Thread.isMainThread)
            if oldValue != totalSubscribed {
                NotificationCenter.default.post(name: .subscriptionTotalStateDidChange, object: self)
            }
        }
    }
    private var subscribed = Set<String>() {
        didSet {
            assert(Thread.isMainThread)
            
            if oldValue != subscribed {
                let common = oldValue.intersection(subscribed)
                let all = oldValue.union(subscribed)
                let changed = all.subtracting(common)
                NotificationCenter.default.post(name: .subscriptionSomeStateDidChange, object: self, userInfo: [ SubscriptionState.subscriptionSomeStateDidChangeProductsKey: Array(changed) ])
            }
            
            totalSubscribed = !subscribed.isEmpty
        }
    }
    
    private func onMain<T>(_ block: @escaping (() -> T)) -> T {
        if Thread.isMainThread {
            return block()
        }
        else {
            var result: T!
            DispatchQueue.main.sync {
                result = block()
            }
            return result
        }
    }
}

extension SubscriptionState: SelfAware {
    
    public static func awake() {
        _ = shared
    }
    
}

extension SubscriptionState: SKPaymentTransactionObserver {
    
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {

        guard transactions.contains(where: { $0.transactionState == .purchased || $0.transactionState == .restored }) else {
            return
        }

        self.revalidate()
    }
    
}
