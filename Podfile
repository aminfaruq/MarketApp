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

    if target.name == 'Texture'
      target.build_configurations.each do |config|
        config.build_settings['HEADER_SEARCH_PATHS'] ||= ['$(inherited)']
        config.build_settings['HEADER_SEARCH_PATHS'] << ' "${PODS_ROOT}/IGListKit/Source"'
        config.build_settings['HEADER_SEARCH_PATHS'] << ' "${PODS_ROOT}/IGListDiffKit/Source"'
      end
    end
  end

  # Patch Texture ASTextLayout.mm chained comparison issue for modern Xcode
  text_layout_path = 'Pods/Texture/Source/TextExperiment/Component/ASTextLayout.mm'
  if File.exist?(text_layout_path)
    File.chmod(0644, text_layout_path)
    content = File.read(text_layout_path)
    patched = content.gsub(
      'position = fabs(left - point.y) < fabs(right - point.y) < (right ? prev : next);',
      'position = (fabs(left - point.y) < fabs(right - point.y)) < (right ? prev : next);'
    ).gsub(
      'position = fabs(left - point.x) < fabs(right - point.x) < (right ? prev : next);',
      'position = (fabs(left - point.x) < fabs(right - point.x)) < (right ? prev : next);'
    )
    File.write(text_layout_path, patched) if content != patched
  end
end
