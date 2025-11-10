Pod::Spec.new do |s|
  s.name             = 'SwiftCache'
  s.version          = '2.0.0'
  s.summary          = 'A modern, actor-based image caching library for iOS and macOS'
  s.description      = <<-DESC
SwiftCache is a modern, lightweight image caching library built with 100% Swift Concurrency.
Features three-tier caching (Memory → Disk → Network), Chain of Responsibility pattern,
pluggable Strategy pattern for custom loaders, and full macOS support with image downscaling.
                       DESC

  s.homepage         = 'https://github.com/SudhirGadhvi/SwiftCache-SDK'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Sudhir Gadhvi' => 'sudhirgadhviwork@gmail.com' }
  s.source           = { :git => 'https://github.com/SudhirGadhvi/SwiftCache-SDK.git', :tag => "v#{s.version}" }

  s.ios.deployment_target = '14.0'
  s.osx.deployment_target = '12.0'
  s.tvos.deployment_target = '14.0'
  s.watchos.deployment_target = '7.0'

  s.swift_version = '5.9'
  
  s.source_files = 'Sources/SwiftCache/**/*.swift'
  
  s.frameworks = 'Foundation'
  s.ios.frameworks = 'UIKit'
  s.osx.frameworks = 'AppKit'
  s.tvos.frameworks = 'UIKit'
  s.watchos.frameworks = 'WatchKit'
end

