require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

# Compute absolute paths at pod install time
# This ensures paths are correct regardless of how the pod is linked
pod_root = __dir__
ios_include_path = File.join(pod_root, 'ios', 'include')
framework_path = File.join(pod_root, 'ios', 'Frameworks', 'sherpa_onnx.xcframework')

Pod::Spec.new do |s|
  s.name         = "SherpaOnnxStt"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => min_ios_version_supported }
  s.source       = { :git => "https://github.com/XDcobra/react-native-sherpa-onnx-stt.git", :tag => "#{s.version}" }

  # Source files (implementation)
  s.source_files = "ios/**/*.{h,m,mm,swift,cpp}"
  
  # Private headers (our wrapper headers)
  s.private_header_files = [
    "ios/*.h",
    "ios/include/**/*.h"
  ]
  
  # Link with required frameworks and libraries
  s.frameworks = 'Foundation'
  s.libraries = 'c++'
  
  # Verify XCFramework exists
  unless File.exist?(framework_path)
    raise <<~MSG
      SherpaOnnxStt: Required XCFramework 'ios/Frameworks/sherpa_onnx.xcframework' was not found.

      Make sure the sherpa_onnx.xcframework is bundled with the npm package or added to:
        #{framework_path}

      You can obtain the framework by:
      1. Downloading from GitHub Actions workflow artifacts
      2. Building it yourself using the build-sherpa-onnx-framework.yml workflow
    MSG
  end
  
  # Log paths for debugging (visible during pod install)
  puts "[SherpaOnnxStt] Pod root: #{pod_root}"
  puts "[SherpaOnnxStt] Include path: #{ios_include_path}"
  puts "[SherpaOnnxStt] Framework path: #{framework_path}"
  
  # Preserve the XCFramework, xcconfig files, and headers
  s.preserve_paths = [
    'ios/Frameworks/sherpa_onnx.xcframework/**/*',
    'ios/SherpaOnnxStt.xcconfig',
    'ios/include/**/*'
  ]
  
  s.pod_target_xcconfig = {
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'CLANG_CXX_LIBRARY' => 'libc++',
    # Header search paths - use absolute path computed at pod install time
    'HEADER_SEARCH_PATHS' => "$(inherited) \"#{ios_include_path}\"",
    # Device builds - use absolute paths
    'SHERPA_ONNX_LIB_DIR[sdk=iphoneos*]' => "#{framework_path}/ios-arm64",
    # Simulator builds
    'SHERPA_ONNX_LIB_DIR[sdk=iphonesimulator*]' => "#{framework_path}/ios-arm64_x86_64-simulator",
    # Library search path (uses the conditional SHERPA_ONNX_LIB_DIR)
    'LIBRARY_SEARCH_PATHS' => '$(inherited) "$(SHERPA_ONNX_LIB_DIR)"',
    # Force load the static library
    'OTHER_LDFLAGS' => '$(inherited) -force_load "$(SHERPA_ONNX_LIB_DIR)/libsherpa-onnx.a"'
  }
  
  s.user_target_xcconfig = {
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'CLANG_CXX_LIBRARY' => 'libc++'
  }

  install_modules_dependencies(s)
end
