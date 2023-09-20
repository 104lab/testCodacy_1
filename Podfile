# Uncomment this line to define a global platform for your project
platform :ios, '10.0'
source 'https://github.com/CocoaPods/Specs.git'
source 'git@github.com:104corp/104cac-specs.git'
inhibit_all_warnings!
# Uncomment this line if you're using Swift
use_frameworks!

target 'WKViewBase' do
    use_frameworks!
    pod 'CACBaseObjC', '~> 0.10.1'
    pod 'Firebase', '~>6.29.0',:subspecs=>['DynamicLinks', 'RemoteConfig','Performance','Crashlytics','Core','Messaging']

end

post_install do |installer|
    installer.pods_project.build_configurations.each do |config|
        config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = ''
    end
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['ENABLE_BITCODE'] = 'NO'
            config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = ''
        end
    end
end

