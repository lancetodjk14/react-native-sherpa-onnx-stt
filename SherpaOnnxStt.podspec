require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "SherpaOnnxStt"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => min_ios_version_supported }
  s.source       = { :git => "https://github.com/XDcobra/react-native-sherpa-onnx-stt.git", :tag => "#{s.version}" }

  s.source_files = "ios/**/*.{h,m,mm,swift,cpp}"
  s.private_header_files = "ios/**/*.h"
  
  # Include sherpa-onnx headers
  s.public_header_files = "ios/include/**/*.h"
  
  # Link with required frameworks
  s.frameworks = 'Foundation'
  s.libraries = 'c++'
  
  # sherpa-onnx framework integration
  # Automatically use pre-built XCFramework if available (bundled in npm package)
  framework_path = File.join(__dir__, 'ios', 'Frameworks', 'sherpa_onnx.xcframework')
  
  # Build pod_target_xcconfig hash with framework-specific settings if framework exists
  pod_target_xcconfig_hash = {
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'CLANG_CXX_LIBRARY' => 'libc++',
    'HEADER_SEARCH_PATHS' => '$(inherited) "$(PODS_TARGET_SRCROOT)/ios/include"'
  }
  
  if File.exist?(framework_path)
    s.vendored_frameworks = 'ios/Frameworks/sherpa_onnx.xcframework'
    s.preserve_paths = 'ios/Frameworks/sherpa_onnx.xcframework/**/*'
    
    # The XCFramework contains a static library (libsherpa-onnx.a)
    # CocoaPods sometimes has issues linking static libraries in XCFrameworks
    # Ensure framework search paths are set correctly
    pod_target_xcconfig_hash['FRAMEWORK_SEARCH_PATHS'] = '$(inherited) "$(PODS_TARGET_SRCROOT)/ios/Frameworks"'
    # Force load the static library to ensure all symbols are included
    # This is necessary because static libraries in XCFrameworks may not be auto-linked
    pod_target_xcconfig_hash['OTHER_LDFLAGS'] = '$(inherited) -framework sherpa_onnx'
  else
    # If framework is not found, fail fast with a clear error message
    raise <<~MSG
      SherpaOnnxStt: Required XCFramework 'ios/Frameworks/sherpa_onnx.xcframework' was not found.

      Make sure the sherpa_onnx.xcframework is bundled with the npm package or added to:
        #{File.join(__dir__, 'ios', 'Frameworks')}

      You can obtain the framework by:
      1. Downloading from GitHub Actions workflow artifacts
      2. Building it yourself using the build-sherpa-onnx-framework.yml workflow

      If you need to add custom build settings or post_install logic to handle this case,
      define a `post_install` hook in your consuming app's Podfile instead of the podspec.
    MSG
  end
  
  # Set pod_target_xcconfig with all accumulated settings
  s.pod_target_xcconfig = pod_target_xcconfig_hash
  s.user_target_xcconfig = {
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'CLANG_CXX_LIBRARY' => 'libc++'
  }

  install_modules_dependencies(s)
end
