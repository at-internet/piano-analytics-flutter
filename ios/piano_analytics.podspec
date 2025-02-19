Pod::Spec.new do |s|
  s.name             = 'piano_analytics'
  s.version          = '1.0.2'
  s.summary          = 'Piano Analytics SDK Flutter'
  s.homepage         = 'https://piano.io/product/analytics/'
  s.license          = { :file => '../LICENSE' }
  s.author           = 'Piano Analytics'
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'PianoAnalytics', '>=3.1'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
