Pod::Spec.new do |s|

  s.name                  = "SubscriptionState"
  s.version               = "1.0.0"
  s.summary               = "iOS subscription tracking"
  s.homepage              = "https://github.com/ladeiko/SubscriptionState"
  s.license               = 'MIT'
  s.authors               = { "Siarhei Ladzeika" => "sergey.ladeiko@gmail.com" }
  s.source                = { :git => "https://github.com/ladeiko/SubscriptionState.git", :tag => s.version.to_s }
  s.platform              = :ios
  s.ios.deployment_target = '10.0'
  s.requires_arc          = true
  s.source_files          =  "Sources/*.{swift,m}"
  s.swift_versions        = ['4.2', '5.0', '5.1']
  s.framework             = 'StoreKit'
  s.dependency            'TrueTime'
  s.dependency            'TPInAppReceipt'
  s.dependency            'SwiftSelfAware'
  s.dependency            'Valet'
end
