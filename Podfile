platform :ios, '17.0'
use_frameworks!

# 1. MarketPresentation (Only RxSwift & RxRelay - ZERO UIKit/RxCocoa!)
target 'MarketPresentation' do
  pod 'RxSwift', '~> 6.8'
  pod 'RxRelay', '~> 6.8'

  target 'MarketPresentationTests' do
    inherit! :search_paths
    pod 'RxTest', '~> 6.8'
    pod 'RxBlocking', '~> 6.8'
  end
end

# 2. MarketApp (UI Target: Texture, IGListKit, UIKit, RxCocoa)
target 'MarketApp' do
  pod 'Texture', '~> 3.1'
  pod 'IGListKit', '~> 5.0'
  pod 'RxSwift', '~> 6.8'
  pod 'RxCocoa', '~> 6.8'
  pod 'RxRelay', '~> 6.8'

  target 'MarketAppTests' do
    inherit! :search_paths
  end
end
