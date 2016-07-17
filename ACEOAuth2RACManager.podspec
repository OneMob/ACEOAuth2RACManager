Pod::Spec.new do |s|

  s.name     = 'ACEOAuth2RACManager'
  s.version  = '1.0.5'
  s.license  = 'MIT'
  s.summary  = 'Network manager with RAC OAuth2 support.'
  s.homepage = 'https://github.com/acerbetti/ACEOAuth2RACManager'
  s.authors  = { 'Stefano Acerbetti' => 'acerbetti@gmail.com' }
  s.source   = { :git => 'https://github.com/acerbetti/ACEOAuth2RACManager.git', :tag => s.version }
  s.source_files  = 'ACEOAuth2RACManager/*.{h,m}', 'AFNetworkHelpers/**/*.{h,m}'
  s.requires_arc = true
  
  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.9'
  # s.watchos.deployment_target = '2.0'
  # s.tvos.deployment_target = '9.0'

  s.dependency 'AFOAuth2Manager', '~> 3.0'
  s.dependency 'ReactiveCocoa', '~> 2.5'
  s.dependency 'NSURL+QueryDictionary', '~> 1.2'

  s.subspec 'AppExtension' do |ss|
    ss.ios.deployment_target = '8.0'
    ss.source_files = 'ACEOAuth2RACManager/*.{h,m}', 'AFNetworkHelpers/**/*.{h,m}'
    ss.xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'ACE_APP_EXTENSION=1' }
    ss.requires_arc = true

    ss.dependency 'AFOAuth2Manager', '~> 3.0'
    ss.dependency 'ReactiveCocoa', '~> 2.5'
    ss.dependency 'NSURL+QueryDictionary', '~> 1.2'
  end

end