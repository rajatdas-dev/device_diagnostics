
Pod::Spec.new do |s|
  s.name             = 'device_diagnostics'
  s.version          = '0.1.0'
  s.summary          = 'Flutter device diagnostics collectors'
  s.description      = 'Session-based Flutter diagnostics with platform collectors.'
  s.homepage         = 'https://github.com/rajatdas-dev/device_diagnostics'
  s.license          = { :type => 'MIT' }
  s.author           = { 'Rajat Das' => 'rajatd565@gmail.com' }
  s.source           = {
    :git => 'https://github.com/rajatdas-dev/device_diagnostics.git',
    :tag => s.version.to_s
  }

  s.source_files     = 'device_diagnostics/Sources/device_diagnostics/**/*.swift'
  s.platform         = :ios, '12.0'
  s.swift_version    = '5.0'
  s.dependency       'Flutter'

  s.frameworks       = 'UIKit', 'Foundation', 'Network'
end
