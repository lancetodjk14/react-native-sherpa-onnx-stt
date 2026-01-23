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
  # Include .cc for cxx-api.cc (C++ wrapper around C API)
  s.source_files = "ios/**/*.{h,m,mm,swift,cpp,cc}"
  
  # Private headers (our wrapper headers)
  s.private_header_files = [
    "ios/*.h",
    "ios/include/**/*.h"
  ]
  
  # Link with required frameworks and libraries
  # CoreML is required by ONNX Runtime's CoreML execution provider
  s.frameworks = 'Foundation', 'Accelerate', 'CoreML'
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
  
  # Use vendored_frameworks for the XCFramework - this properly handles
  # architecture-specific linking for static libraries within XCFrameworks
  s.vendored_frameworks = 'ios/Frameworks/sherpa_onnx.xcframework'
  
  # Preserve headers and config files
  s.preserve_paths = [
    'ios/SherpaOnnxStt.xcconfig',
    'ios/include/**/*'
  ]
  
  # Note: vendored_frameworks automatically handles linking the XCFramework
  # No need for manual LIBRARY_SEARCH_PATHS or force_load configuration
  
  s.pod_target_xcconfig = {
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'CLANG_CXX_LIBRARY' => 'libc++',
    # Header search paths - use absolute path computed at pod install time
    'HEADER_SEARCH_PATHS' => "$(inherited) \"#{ios_include_path}\"",
    # Note: LIBRARY_SEARCH_PATHS removed - vendored_frameworks handles linking automatically
    # Adding LIBRARY_SEARCH_PATHS was causing duplicate symbol errors
  }
  
  # Settings that propagate to the app target for final linking
  s.user_target_xcconfig = {
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'CLANG_CXX_LIBRARY' => 'libc++',
    # Note: LIBRARY_SEARCH_PATHS removed - vendored_frameworks handles linking automatically
    # SHERPA_ONNX_DEVICE_LIB and SHERPA_ONNX_SIMULATOR_LIB removed as they're no longer needed
  }
  

  install_modules_dependencies(s)
end
