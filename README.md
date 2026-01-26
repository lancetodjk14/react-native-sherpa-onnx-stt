# react-native-sherpa-onnx-stt

> ### ⚠️ Deprecation Notice
>
> This package is **deprecated** and no longer maintained.  
> Please use the new, actively maintained package instead:  
> **react-native-sherpa-onnx** → https://github.com/XDcobra/react-native-sherpa-onnx

Offline Speech-to-Text with sherpa-onnx for React Native

[![npm version](https://img.shields.io/npm/v/react-native-sherpa-onnx-stt.svg)](https://www.npmjs.com/package/react-native-sherpa-onnx-stt)
[![npm downloads](https://img.shields.io/npm/dm/react-native-sherpa-onnx-stt.svg)](https://www.npmjs.com/package/react-native-sherpa-onnx-stt)
[![npm license](https://img.shields.io/npm/l/react-native-sherpa-onnx-stt.svg)](https://www.npmjs.com/package/react-native-sherpa-onnx-stt)

A React Native TurboModule that provides offline speech recognition capabilities using [sherpa-onnx](https://github.com/k2-fsa/sherpa-onnx). Supports multiple model architectures including Zipformer/Transducer, Paraformer, NeMo CTC, and Whisper.

## Platform Support

| Platform | Status |
| -------- | ------ |
| Android  | ✅ Yes |
| iOS      | ✅ Yes |

## Supported Model Types

| Model Type               | `modelType` Value | Description                                                                              | Download Links                                                                                   |
| ------------------------ | ----------------- | ---------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| **Zipformer/Transducer** | `'transducer'`    | Requires `encoder.onnx`, `decoder.onnx`, `joiner.onnx`, and `tokens.txt`                 | [Download](https://k2-fsa.github.io/sherpa/onnx/pretrained_models/offline-transducer/index.html) |
| **Paraformer**           | `'paraformer'`    | Requires `model.onnx` (or `model.int8.onnx`) and `tokens.txt`                            | [Download](https://k2-fsa.github.io/sherpa/onnx/pretrained_models/offline-paraformer/index.html) |
| **NeMo CTC**             | `'nemo_ctc'`      | Requires `model.onnx` (or `model.int8.onnx`) and `tokens.txt`                            | [Download](https://k2-fsa.github.io/sherpa/onnx/pretrained_models/offline-ctc/nemo/index.html)   |
| **Whisper**              | `'whisper'`       | Requires `encoder.onnx`, `decoder.onnx`, and `tokens.txt`                                | [Download](https://k2-fsa.github.io/sherpa/onnx/pretrained_models/whisper/index.html)            |
| **WeNet CTC**            | `'wenet_ctc'`     | Requires `model.onnx` (or `model.int8.onnx`) and `tokens.txt`                            | [Download](https://k2-fsa.github.io/sherpa/onnx/pretrained_models/offline-ctc/wenet/index.html)  |
| **SenseVoice**           | `'sense_voice'`   | Requires `model.onnx` (or `model.int8.onnx`) and `tokens.txt`                            | [Download](https://k2-fsa.github.io/sherpa/onnx/pretrained_models/sense-voice/index.html)        |
| **FunASR Nano**          | `'funasr_nano'`   | Requires `encoder_adaptor.onnx`, `llm.onnx`, `embedding.onnx`, and `tokenizer` directory | [Download](https://k2-fsa.github.io/sherpa/onnx/pretrained_models/funasr-nano/index.html)        |

## Features

- ✅ **Offline Speech Recognition** - No internet connection required
- ✅ **Multiple Model Types** - Supports Zipformer/Transducer, Paraformer, NeMo CTC, and Whisper models
- ✅ **Model Quantization** - Automatic detection and preference for quantized (int8) models
- ✅ **Flexible Model Loading** - Asset models, file system models, or auto-detection
- ✅ **Android Support** - Fully supported on Android
- ✅ **iOS Support** - Fully supported on iOS (requires sherpa-onnx XCFramework)
- ✅ **TypeScript Support** - Full TypeScript definitions included

## Installation

```sh
npm install react-native-sherpa-onnx-stt
```

### Android

No additional setup required. The library automatically handles native dependencies via Gradle.

### iOS

The sherpa-onnx XCFramework is required but needs to be obtained separately. Simply install CocoaPods dependencies after obtaining the framework:

```sh
cd ios
pod install
```

**Note:** The XCFramework is not bundled with the npm package due to its size. You must obtain it before running `pod install`.

#### Obtaining the XCFramework

1. **Use the prebuilt version** (if available):

   - The XCFramework may be included in the repository at `ios/Frameworks/sherpa_onnx.xcframework`
   - If present, no additional steps are required

2. **Build locally** (requires macOS):

   ```sh
   git clone https://github.com/k2-fsa/sherpa-onnx.git
   cd sherpa-onnx
   git checkout v1.12.23

   # Note: ONNX Runtime is required for building sherpa-onnx
   # Make sure ONNX Runtime dependencies are installed
   ./build-ios.sh
   cp -r build-ios/sherpa_onnx.xcframework /path/to/your/project/node_modules/react-native-sherpa-onnx-stt/ios/Frameworks/
   ```

   **Important:** Building sherpa-onnx requires ONNX Runtime. Make sure all dependencies are installed before running `build-ios.sh`.

   Replace `/path/to/your/project/` with the actual path to your React Native project. The framework should be copied to `node_modules/react-native-sherpa-onnx-stt/ios/Frameworks/` in your project.

The Podspec will automatically detect and use the framework if it exists in `ios/Frameworks/`.

**Note:** The iOS implementation uses the same C++ wrapper as Android, ensuring consistent behavior across platforms.

## Quick Start

```typescript
import {
  initializeSherpaOnnx,
  transcribeFile,
  assetModelPath,
} from 'react-native-sherpa-onnx-stt';

// Initialize with a model
await initializeSherpaOnnx({
  modelPath: assetModelPath('models/sherpa-onnx-model'),
  preferInt8: true, // Optional: prefer quantized models
});

// Transcribe an audio file
const transcription = await transcribeFile('path/to/audio.wav');
console.log('Transcription:', transcription);
```

## Usage

### Initialization

```typescript
import {
  initializeSherpaOnnx,
  assetModelPath,
  autoModelPath,
} from 'react-native-sherpa-onnx-stt';

// Option 1: Asset model (bundled in app)
await initializeSherpaOnnx({
  modelPath: assetModelPath('models/sherpa-onnx-model'),
  preferInt8: true, // Prefer quantized models
});

// Option 2: Auto-detect (tries asset, then file system)
await initializeSherpaOnnx({
  modelPath: autoModelPath('models/sherpa-onnx-model'),
});

// Option 3: Simple string (backward compatible)
await initializeSherpaOnnx('models/sherpa-onnx-model');
```

### Transcription

```typescript
import { transcribeFile } from 'react-native-sherpa-onnx-stt';

// Transcribe a WAV file (16kHz, mono, 16-bit PCM)
const result = await transcribeFile('path/to/audio.wav');
console.log('Transcription:', result);
```

### Model Quantization

Control whether to prefer quantized (int8) or regular models:

```typescript
// Default: try int8 first, then regular
await initializeSherpaOnnx({ modelPath: 'models/my-model' });

// Explicitly prefer int8 models (smaller, faster)
await initializeSherpaOnnx({
  modelPath: 'models/my-model',
  preferInt8: true,
});

// Explicitly prefer regular models (higher accuracy)
await initializeSherpaOnnx({
  modelPath: 'models/my-model',
  preferInt8: false,
});
```

### Explicit Model Type

For robustness, you can explicitly specify the model type to avoid auto-detection issues:

```typescript
// Explicitly specify model type
await initializeSherpaOnnx({
  modelPath: 'models/sherpa-onnx-nemo-parakeet-tdt-ctc-en',
  modelType: 'nemo_ctc', // 'transducer', 'paraformer', 'nemo_ctc', 'whisper', or 'auto' (default)
});

// Auto-detection (default behavior)
await initializeSherpaOnnx({
  modelPath: 'models/my-model',
  // modelType defaults to 'auto'
});
```

### Cleanup

```typescript
import { unloadSherpaOnnx } from 'react-native-sherpa-onnx-stt';

// Release resources when done
await unloadSherpaOnnx();
```

## Model Setup

The library does **not** bundle models. You must provide your own models. See [MODEL_SETUP.md](./MODEL_SETUP.md) for detailed setup instructions.

### Model File Requirements

- **Zipformer/Transducer**: Requires `encoder.onnx`, `decoder.onnx`, `joiner.onnx`, and `tokens.txt`
- **Paraformer**: Requires `model.onnx` (or `model.int8.onnx`) and `tokens.txt`
- **NeMo CTC**: Requires `model.onnx` (or `model.int8.onnx`) and `tokens.txt`
- **Whisper**: Requires `encoder.onnx`, `decoder.onnx`, and `tokens.txt`
- **WeNet CTC**: Requires `model.onnx` (or `model.int8.onnx`) and `tokens.txt`
- **SenseVoice**: Requires `model.onnx` (or `model.int8.onnx`) and `tokens.txt`

### Model Files

Place models in:

- **Android**: `android/app/src/main/assets/models/`
- **iOS**: Add to Xcode project as folder reference

## API Reference

### `initializeSherpaOnnx(options)`

Initialize the speech recognition engine with a model.

**Parameters:**

- `options.modelPath`: Model path configuration (see [MODEL_SETUP.md](./MODEL_SETUP.md))
- `options.preferInt8` (optional): Prefer quantized models (`true`), regular models (`false`), or auto-detect (`undefined`, default)
- `options.modelType` (optional): Explicit model type (`'transducer'`, `'paraformer'`, `'nemo_ctc'`, `'whisper'`, `'wenet_ctc'`, `'sense_voice'`, `'funasr_nano'`), or auto-detect (`'auto'`, default)

**Returns:** `Promise<void>`

### `transcribeFile(filePath)`

Transcribe an audio file.

**Parameters:**

- `filePath`: Path to WAV file (16kHz, mono, 16-bit PCM)

**Returns:** `Promise<string>` - Transcribed text

### `unloadSherpaOnnx()`

Release resources and unload the model.

**Returns:** `Promise<void>`

### `resolveModelPath(config)`

Resolve a model path configuration to an absolute path.

**Parameters:**

- `config`: Model path configuration object

**Returns:** `Promise<string>` - Absolute path to model directory

## Requirements

- React Native >= 0.70
- Android API 24+ (Android 7.0+)
- iOS 13.0+ (requires sherpa-onnx XCFramework - see iOS Setup below)

## Example Apps

We provide example applications to help you get started with `react-native-sherpa-onnx-stt`:

### Example App (Audio to Text)

The example app included in this repository demonstrates basic audio-to-text transcription capabilities. It includes:

- Multiple model type support (Zipformer, Paraformer, NeMo CTC, Whisper, WeNet CTC, SenseVoice, FunASR Nano)
- Model selection and configuration
- Audio file transcription
- Test audio files for different languages

**Getting started:**

```sh
cd example
yarn install
yarn android  # or yarn ios
```

<div align="center">
  <img src="./docs/images/example_home_screen.png" alt="Model selection home screen" width="30%" />
  <img src="./docs/images/example_english.png" alt="Transcribe english audio" width="30%" />
  <img src="./docs/images/example_multilanguage.png" alt="Transcribe english and chinese audio" width="30%" />
</div>

### Video to Text Comparison App

A comprehensive comparison app that demonstrates video-to-text transcription using `react-native-sherpa-onnx-stt` alongside other speech-to-text solutions:

**Repository:** [mobile-videototext-stt-comparison](https://github.com/XDcobra/mobile-videototext-stt-comparison)

**Features:**

- Video to audio conversion (using native APIs)
- Audio to text transcription
- Video to text (video --> WAV --> text)
- Comparison between different STT providers
- Performance benchmarking

This app showcases how to integrate `react-native-sherpa-onnx-stt` into a real-world application that processes video files and converts them to text.

<div align="center">
  <img src="./docs/images/vtt_model_overview.png" alt="Video-to-Text Model Overview" width="30%" />
  <img src="./docs/images/vtt_result_file_picker.png" alt="Video-to-Text file picker" width="30%" />
  <img src="./docs/images/vtt_result_test_audio.png" alt="Video-to-Text test audio" width="30%" />
</div>

## Contributing

- [Development workflow](CONTRIBUTING.md#development-workflow)
- [Sending a pull request](CONTRIBUTING.md#sending-a-pull-request)
- [Code of conduct](CODE_OF_CONDUCT.md)

## License

MIT

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
