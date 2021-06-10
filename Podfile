# Uncomment the next line to define a global platform for your project
platform :ios, '13.1'

target 'socialApp' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for socialApp

pod 'Firebase/Analytics'
pod 'Firebase/Auth'
pod 'Firebase/Firestore'
pod 'FirebaseFirestoreSwift'
pod 'Firebase/Storage'
pod 'Firebase/Messaging'
pod 'GeoFire/Utils'

pod 'SDWebImage', '~> 5.0'
pod 'MessageKit'
pod 'lottie-ios'
pod 'SwiftEntryKit', '1.2.6'
pod "ApphudSDK"
pod 'CHIPageControl/Aleppo'
pod 'RealmSwift'

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      if Gem::Version.new('9.0') > Gem::Version.new(config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'])
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '9.0'
      end
    end
  end
end



