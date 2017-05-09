Pod::Spec.new do |s|

  s.name     = 'ACEOAuth2RACManager'
  s.version  = '1.1.0'
  s.license  = 'MIT'
  s.summary  = 'Network manager with RAC OAuth2 support.'
  s.homepage = 'https://github.com/acerbetti/ACEOAuth2RACManager'
  s.authors  = { 'Stefano Acerbetti' => 'acerbetti@gmail.com' }
  s.source   = { :git => 'https://github.com/acerbetti/ACEOAuth2RACManager.git', :tag => s.version }
  s.default_subspec = 'Core'
  s.requires_arc = true
  
  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.9'
  # s.watchos.deployment_target = '2.0'
  # s.tvos.deployment_target = '9.0'

  s.subspec 'Core' do |ss|
    ss.source_files  = 'ACEOAuth2RACManager/*.{h,m}', 'ACEOAuth2RACManager/ACEOAuth2RACManagerPrivate.h'
    ss.private_header_files = 'ACEOAuth2RACManager/ACEOAuth2RACManagerPrivate.h'

    ss.dependency 'ACEOAuth2RACManager/AFNetworkActivityLogger'
    ss.dependency 'ACEOAuth2RACManager/AFNetworking-RACRetryExtensions'
    ss.dependency 'NSURL+QueryDictionary', '~> 1.2'
  end

  s.subspec "AFNetworkActivityLogger" do |ss|
    ss.source_files = 'AFNetworkHelpers/AFNetworkActivityLogger/*.{h,m}'

    ss.dependency 'AFOAuth2Manager', '~> 3.0'
  end

  s.subspec "AFNetworking-RACRetryExtensions" do |ss|
    ss.source_files = 'AFNetworkHelpers/AFNetworking-RACRetryExtensions/*.{h,m}'

    ss.dependency 'AFOAuth2Manager', '~> 3.0'
    ss.dependency "ReactiveObjC", "~> 3.0"
  end

  s.subspec "CocoaLumberjack" do |ss|
    ss.dependency 'ACEOAuth2RACManager/Core'
    ss.dependency 'CocoaLumberjack', '~> 2.0'
  end

end