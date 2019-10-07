//
//  ViewController.swift
//  SubscriptionStateDemo
//
//  Created by Siarhei Ladzeika on 10/3/19.
//  Copyright © 2019 Siarhei Ladzeika. All rights reserved.
//

import UIKit
import SwiftyStoreKit
import SubscriptionState

class ViewController: UIViewController {

    private var observers: [NSObjectProtocol]!
    
    @IBOutlet weak var totalState: UILabel!
    @IBOutlet weak var products: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        observers = [
            NotificationCenter.default.addObserver(forName: .subscriptionSomeStateDidChange, object: SubscriptionState.shared, queue: .main) { (notification) in
                self.updatesProducts()
            },
            NotificationCenter.default.addObserver(forName: .subscriptionTotalStateDidChange, object: SubscriptionState.shared, queue: .main) { (_) in
                self.updateTotalState()
            }
        ]
       
        updateTotalState()
        updatesProducts()
    }
    
    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }
    
    // MARK: - Helpers
    
    private func updateTotalState() {
        totalState.backgroundColor = SubscriptionState.shared.isSubscriptionActive() ? .green : .red
    }
    
    private func updatesProducts() {
        products.text = SubscriptionState.shared.activeProducts.joined(separator: "\n")
    }
    
    // MARK: - UI Actions

    @IBAction func buy(_ sender: Any) {
        
        SwiftyStoreKit.purchaseProduct("custom.product", quantity: 1, atomically: true) { result in
            switch result {
            case .success(let purchase):
                print("Purchase Success: \(purchase.productId)")
            case .error(let error):
                switch error.code {
                case .unknown: print("Unknown error. Please contact support")
                case .clientInvalid: print("Not allowed to make the payment")
                case .paymentCancelled: break
                case .paymentInvalid: print("The purchase identifier was invalid")
                case .paymentNotAllowed: print("The device is not allowed to make the payment")
                case .storeProductNotAvailable: print("The product is not available in the current storefront")
                case .cloudServicePermissionDenied: print("Access to cloud service information is not allowed")
                case .cloudServiceNetworkConnectionFailed: print("Could not connect to the network")
                case .cloudServiceRevoked: print("User has revoked permission to use this cloud service")
                default: print((error as NSError).localizedDescription)
                }
            }
        }
        
    }
    
}

