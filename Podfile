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

  # Patch Texture ASIGListAdapterBasedDataSource.mm for IGListKit 5.0 compatibility
  adapter_ds_path = 'Pods/Texture/Source/Private/ASIGListAdapterBasedDataSource.mm'
  if File.exist?(adapter_ds_path)
    File.chmod(0644, adapter_ds_path)
    content = File.read(adapter_ds_path)
    # Replace entire configureUpdater method body with a safe no-op for IGListKit 5.0
    original_code = "+ (void)configureUpdater:(id<IGListUpdatingDelegate>)updater\n{\n  // Cast to NSObject will be removed after https://github.com/Instagram/IGListKit/pull/435\n  if ([(id<NSObject>)updater isKindOfClass:[IGListAdapterUpdater class]]) {\n    [(IGListAdapterUpdater *)updater setAllowsBackgroundReloading:NO];\n  } else {\n    static dispatch_once_t onceToken;\n    dispatch_once(&onceToken, ^{\n      NSLog(@\"WARNING: Use of non-%@ updater with AsyncDisplayKit is discouraged. Updater: %@\", NSStringFromClass([IGListAdapterUpdater class]), updater);\n    });\n  }\n}"
    replacement_code = "+ (void)configureUpdater:(id<IGListUpdatingDelegate>)updater\n{\n  // In IGListKit 5.0+, setAllowsBackgroundReloading was removed by Meta/Instagram.\n}"
    patched = content.gsub(original_code, replacement_code)
    File.write(adapter_ds_path, patched) if content != patched
  end
end
