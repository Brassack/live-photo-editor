# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'Livepc' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Livepc
    pod 'RxSwift',    '~> 4.0'
    pod 'RxCocoa',    '~> 4.0'
    pod 'RxOptional'

    pod 'JGProgressHUD'
    pod 'IQKeyboardManagerSwift'
    pod 'ABVideoRangeSlider'

	post_install do |installer|
  	installer.pods_project.targets.each do |target|
      if ['ABVideoRangeSlider'].include? target.name
          target.build_configurations.each do |config|
              config.build_settings['SWIFT_VERSION'] = '3.2'
          end
      	end
 	 end
	end
end
