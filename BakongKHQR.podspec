Pod::Spec.new do |s|
  s.name             = 'BakongKHQR'
  s.version          = '1.0.0.16'
  s.summary          = 'Private cocoapod for Bakong KHQR provided by NBC'

  s.description      = <<-DESC
    This library provides the standard KHQR. It is developed and maintained by the National Bank of Cambodia.
  DESC

  s.homepage         = 'https://gitlab.nbc.gov.kh/khqr/sdk-ios.git'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.authors          = { 'Sambo' => 'sambo.seth@nbc.gov.kh' }
  s.source           = { :git => 'https://gitlab.nbc.gov.kh/khqr/sdk-ios.git', :tag => s.version.to_s }

  s.platform         = :ios, '11.0'
  s.source_files     = 'BakongKHQR/Classes/**/*'
  s.public_header_files = 'BakongKHQR/Classes/Public/**/*.h'
  s.private_header_files = 'BakongKHQR/Classes/Private/**/*.h'
end
