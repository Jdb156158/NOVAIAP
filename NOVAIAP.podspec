#
#  Be sure to run `pod spec lint NOVAIAP.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  spec.name         = "NOVAIAP"
  spec.version      = "0.0.1"
  spec.summary      = "NOVAIAP 内购"

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  spec.description  = <<-DESC
  NOVAIAP 内购.
                   DESC

  spec.homepage     = "https://github.com/Jdb156158/NOVAIAP.git"
  # spec.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"


  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Licensing your code is important. See https://choosealicense.com for more info.
  #  CocoaPods will detect a license file if there is a named LICENSE*
  #  Popular ones are 'MIT', 'BSD' and 'Apache License, Version 2.0'.
  #

  spec.license      = "MIT"
  # spec.license      = { :type => "MIT", :file => "FILE_LICENSE" }


  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the authors of the library, with email addresses. Email addresses
  #  of the authors are extracted from the SCM log. E.g. $ git log. CocoaPods also
  #  accepts just a name if you'd rather not provide an email address.
  #
  #  Specify a social_media_url where others can refer to, for example a twitter
  #  profile URL.
  #

  spec.author             = { "json" => "1183843590@qq.com" }
  # Or just: spec.author    = "json"
  # spec.authors            = { "json" => "1183843590@qq.com" }
  # spec.social_media_url   = "https://twitter.com/json"

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If this Pod runs only on iOS or OS X, then specify the platform and
  #  the deployment target. You can optionally include the target after the platform.
  #

  # spec.platform     = :ios
  spec.platform     = :ios, "11.0"

  #  When using multiple platforms
  # spec.ios.deployment_target = "5.0"
  # spec.osx.deployment_target = "10.7"
  # spec.watchos.deployment_target = "2.0"
  # spec.tvos.deployment_target = "9.0"


  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the location from where the source should be retrieved.
  #  Supports git, hg, bzr, svn and HTTP.
  #

  spec.source       = { :git => "https://github.com/Jdb156158/NOVAIAP.git", :tag => "#{spec.version}" }


  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  CocoaPods is smart about how it includes source code. For source files
  #  giving a folder will include any swift, h, m, mm, c & cpp files.
  #  For header files it will include any header in the folder.
  #  Not including the public_header_files will make all headers public.
  #

  spec.source_files  = "NOVAIAP/NOVAIAPKit.h"
  spec.public_header_files = "NOVAIAP/NOVAIAPKit.h"
  spec.requires_arc = true

  spec.subspec 'Core' do |ss|
    ss.source_files  = "NOVAIAP/IAP/**/*.{h,m}"
    ss.dependency 'NOVUtilities'
  end

  spec.subspec 'openssl' do |ss|
    ss.source_files  = "NOVAIAP/Validator/LocalReceiptValidator/openssl/include/**/*.h"
    ss.vendored_libraries = 'NOVAIAP/Validator/LocalReceiptValidator/openssl/libcrypto.a', 'NOVAIAP/Validator/LocalReceiptValidator/openssl/libssl.a'
    ss.private_header_files = 'NOVAIAP/Validator/LocalReceiptValidator/openssl/include/**/*.h' # 让openssl本身能够使用<>引用文件
  end

  spec.subspec 'LocalReceiptValidator' do |ss|
      ss.source_files = "NOVAIAP/Validator/LocalReceiptValidator/**/*.{h,m}"
      ss.exclude_files = "NOVAIAP/Validator/LocalReceiptValidator/openssl"
      ss.dependency 'NOVAIAP/Core'
      ss.dependency 'NOVAIAP/openssl'
      ss.dependency 'NOVUtilities'
      ss.resource = 'NOVAIAP/Validator/LocalReceiptValidator/AppleIncRootCertificate.cer'
      ss.xcconfig = {"HEADER_SEARCH_PATHS" => "$(PODS_TARGET_SRCROOT)/NOVAIAP/Validator/LocalReceiptValidator/openssl/include"} # 让RMAppReceipt能够使用<>引用openssl文件
  end
  
  spec.subspec 'UserDefaultProductStore' do |ss|
      ss.source_files = "NOVAIAP/ProductStore/**/*.{h,m}"
      ss.dependency 'NOVAIAP/Core'
      ss.dependency 'NOVUtilities'
  end
end
