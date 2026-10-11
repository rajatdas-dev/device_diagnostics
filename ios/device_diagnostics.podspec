Pod::Spec.new do |s|
  s.name             = 'device_diagnostics'
  s.version          = '0.1.0'
  s.summary          = 'Flutter device diagnostics collectors'
  s.description      = 'Session-based Flutter diagnostics with platform collectors.'
  s.homepage         = 'https://example.invalid/device_diagnostics'
  s.license          = { :type => 'MIT' }
  s.author           = { 'Package Authors' => 'noreply@example.invalid' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.platform         = :ios, '12.0'
  s.swift_version    = '5.0'
  s.dependency 'Flutter'
end
