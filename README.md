# SubscriptionState

iOS module to simplify work with subscription tracking.

## Installation

### Cocoapods

```ruby
pod 'SubscriptionState'
```

### Usage

```swift

import SubscriptionState

class MyCustomSubscriptionService {

	private var observers: [NSObjectProtocol]!
	
	var isPremium: Bool = false {
		didSet {
			// TODO notify others
		}
	}
			
	deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
   }

	func init() {
		
		func updateState() {
			self.isPremium = SubscriptionState.shared.isSubscriptionActive()
		}
		
		observers = [
			NotificationCenter.default.addObserver(forName: .subscriptionSomeStateDidChange, 									object: SubscriptionState.shared, queue: .main) { (notification) in
				//let changedProductIdentifiers = notification.userInfo?[SubscriptionState.subscriptionSomeStateDidChangeProductsKey] as? [String]
				updateState()
			},
		
			NotificationCenter.default.addObserver(forName: .subscriptionTotalStateDidChange,
							object: SubscriptionState.shared, queue: .main) { (_) in
				updateState()	
			}
		]
		
		updateState()
	}
	
}

```

Check subscription status for specified product list:

```swift
let active = SubscriptionState.isSubscriptionActive(["product1", "product2"])
```

#### Grace time interval

You can add some time interval after purchase expiration date to treat it as active.

```swift
SubscriptionState.shared.graceTimeInterval = 3600
```

Example above defines 3600 seconds. It adds additional hour to expiration date.

#### Lifetime purchases

If your application supports lifetime purchases, then you can add them for tracking:

```swift
SubscriptionState.shared.lifetimeProductIdentifiers = Set(['lifetimeProduct1'])
```

If at least one product from the list was purchased, then subscription will be set to active state.

#### Custom date resolver

Also tou can set custom date resolver callback. 

```
SubscriptionState.shared.customDateResolver = { () -> Date in 
	...
}
```

It is used to determine real time and date when cheking activity of subscription.
By default NTP service is used.

#### Persistence

Subscription state is saved to keychain. So it is restored each time application starts.

## Authors

* Siarhei Ladzeika <sergey.ladeiko@gmail.com>

## LICENSE

See [LICENSE](LICENSE)
