# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.1] - 2025-01-XX

### Fixed

- Fixed header files not being included in npm package distribution
- Updated `package.json` files configuration to explicitly include header directories
- Added `prepack` and `prepublishOnly` scripts to ensure headers are copied before publishing

## [0.1.0] - 2025-01-XX

### Added

- Added `copy-headers` script to automatically copy sherpa-onnx header files to Android and iOS include directories
- Header files (`c-api.h` and `cxx-api.h`) are now bundled in the npm package, eliminating the need for git submodule initialization when installing from npm
- iOS header structure prepared for future iOS support
- Added `checkHeaderSource` Gradle task to log which header source is being used (bundled vs submodule)

### Changed

- Updated CMakeLists.txt to prioritize bundled headers over git submodule (for npm package compatibility)
- `prepare` script now automatically runs `copy-headers` before building
- Reduced verbose logging in `extractNativeLibs` Gradle task

### Fixed

- Fixed build errors when installing package from npm without git submodule initialized
- Fixed unused parameter warning in `nativeRelease` JNI function

## [0.0.2] - 2025-01-XX

### Added

- Initial release
- Android support for offline speech-to-text
- Support for multiple model types (Zipformer/Transducer, Paraformer, NeMo CTC, Whisper, WeNet CTC, SenseVoice, FunASR Nano)
- Model quantization support (int8 models)
- Flexible model loading (asset models, file system models, auto-detection)
- TypeScript definitions

### Known Issues

- iOS support not yet available (coming soon)

[Unreleased]: https://github.com/XDcobra/react-native-sherpa-onnx-stt/compare/v0.1.1...HEAD
[0.1.1]: https://github.com/XDcobra/react-native-sherpa-onnx-stt/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/XDcobra/react-native-sherpa-onnx-stt/compare/v0.0.2...v0.1.0
[0.0.2]: https://github.com/XDcobra/react-native-sherpa-onnx-stt/releases/tag/v0.0.2
