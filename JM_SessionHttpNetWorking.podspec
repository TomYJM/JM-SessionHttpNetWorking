#
# Be sure to run `pod lib lint JM_SessionHttpNetWorking.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'JM_SessionHttpNetWorking'
  s.version          = '0.1.2'
  s.summary          = 'icommet http tcp request.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: icommet http tcp request, you can use to start stock request.
                       DESC

  s.homepage         = 'https://github.com/TomYJM/JM-SessionHttpNetWorking.git'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'tomyang' => 'yang13026165706@163.com' }
  s.source           = { :git => 'https://github.com/TomYJM/JM-SessionHttpNetWorking.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'JM_SessionHttpNetWorking/Classes/**/*'
  
  # s.resource_bundles = {
  #   'JM_SessionHttpNetWorking' => ['JM_SessionHttpNetWorking/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'Reachability', '~> 3.2'
end
