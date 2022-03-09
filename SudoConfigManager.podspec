Pod::Spec.new do |spec|
  spec.name                  = 'SudoConfigManager'
  spec.version               = '2.0.2'
  spec.author                = { 'Sudo Platform Engineering' => 'sudoplatform-engineering@anonyome.com' }
  spec.homepage              = 'https://sudoplatform.com'
  spec.summary               = 'Config Manager SDK for the Sudo Platform by Anonyome Labs.'
  spec.license               = { :type => 'Apache License, Version 2.0', :file => 'LICENSE' }
  spec.source                = { :git => 'https://github.com/sudoplatform/sudo-config-manager-ios.git', :tag => "v#{spec.version}" }
  spec.source_files          = 'SudoConfigManager/**/*.swift'
  spec.ios.deployment_target = '14.0'
  spec.requires_arc          = true
  spec.swift_version         = '5.0'
  spec.dependency 'SudoLogging', '~> 0.3'
  spec.dependency 'AWSS3', '~> 2.26.0'
end
