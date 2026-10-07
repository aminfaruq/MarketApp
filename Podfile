platform :ios, '17.0'
use_frameworks!

# MarketApp (UI Target: Texture, IGListKit, UIKit, RxCocoa)
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

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
    end
  end
end
