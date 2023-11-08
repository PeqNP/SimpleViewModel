Pod::Spec.new do |spec|
  spec.name         = "SimpleViewModelTest"
  spec.version      = "1.0.1"
  spec.summary      = "Test helpers for SimpleViewModel library."

  spec.description  = <<-DESC
  Provides test helpers for the SimpleViewModel library.
                   DESC

  spec.homepage     = "https://github.com/PeqNP/SimpleViewModel"
  spec.license      = "MIT"
  spec.author             = { "Eric Chamberlain" => "eric.chamberlain@hotmail.com" }

  spec.swift_versions = "5.0"
  spec.ios.deployment_target = "15.0"
  spec.osx.deployment_target = "14.0"

  spec.source       = { :git => "https://github.com/PeqNP/SimpleViewModel.git", :tag => "#{spec.version}" }

  spec.source_files = "SimpleViewModel/ViewModel/Test*.swift"

  spec.framework = 'XCTest'
end
