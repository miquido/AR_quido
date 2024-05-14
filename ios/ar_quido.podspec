#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint ar_quido.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'ar_quido'
  s.version          = '0.0.1'
  s.summary          = 'AR Image recognition for Flutter'
  s.description      = <<-DESC
A Flutter plugin that provides an image recognition scanner widget.
Downloaded by pub (not CocoaPods)
                       DESC
  s.homepage         = 'https://github.com/miquido/AR_quido'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Miquido Flutter Division' => 'hello@miquido.com' }
  s.source           = { :http => 'https://github.com/miquido/ar_quido/tree/main/ios' }
  s.documentation_url = 'https://pub.dev/packages/ar_quido'
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.10'
end
