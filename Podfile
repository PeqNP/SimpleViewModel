ENV['COCOAPODS_DISABLE_STATS'] = "true"
install! 'cocoapods', :warn_for_unused_master_specs_repo => false

platform :ios, '17.0'

inhibit_all_warnings!
use_frameworks!

def app_pods
    pod 'Alamofire', '~> 5.4'
    pod "PromiseKit", "~> 8"
    pod 'Swinject', '2.6.2'
end

target 'SimpleViewModel' do
    app_pods
end

target 'SimpleViewModelTests' do
    app_pods

    pod 'KIF', '3.7.8'
    pod 'KIF/IdentifierTests', '3.7.8'
end

post_install do |installer|
    installer.aggregate_targets.each do |target|
      target.xcconfigs.each do |variant, xcconfig|
        xcconfig_path = target.client_root + target.xcconfig_relative_path(variant)
        IO.write(xcconfig_path, IO.read(xcconfig_path).gsub("DT_TOOLCHAIN_DIR", "TOOLCHAIN_DIR"))
      end
    end
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'

            if config.base_configuration_reference.is_a? Xcodeproj::Project::Object::PBXFileReference
              xcconfig_path = config.base_configuration_reference.real_path
              IO.write(xcconfig_path, IO.read(xcconfig_path).gsub("DT_TOOLCHAIN_DIR", "TOOLCHAIN_DIR"))
            end
        end
    end
end

