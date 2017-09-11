Pod::Spec.new do |s|
  s.name             = 'CHTTPManager'
  s.version          = '0.1'
  s.summary          = 'Convenience wrapper for AFNetworking.'
  s.description      = <<-DESC
                       DESC

  s.homepage         = 'https://github.com/nbyh100@sina.com/CHTTPManager'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'nbyh100@sina.com' => 'Jiuzhou Zhang' }
  s.source           = { :git => 'https://github.com/nbyh100@sina.com/CHTTPManager.git', :tag => s.version.to_s }
  s.ios.deployment_target = '8.0'
  s.source_files = 'CHTTPManager/Classes/**/*'
  s.dependency 'PromiseKit/Promise', '1.7.2'
  s.dependency 'AFNetworking', '3.1.0'
end
