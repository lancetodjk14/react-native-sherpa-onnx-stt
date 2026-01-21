# react-native-sherpa-onnx-stt

Offline Speech-to-Text with sherpa-onnx for React Native

A React Native TurboModule that provides offline speech recognition capabilities using [sherpa-onnx](https://github.com/k2-fsa/sherpa-onnx). Supports both Zipformer/Transducer and Paraformer model architectures.

## Features

- ✅ **Offline Speech Recognition** - No internet connection required
- ✅ **Multiple Model Types** - Supports Zipformer, Paraformer, and other sherpa-onnx models
- ✅ **Model Quantization** - Automatic detection and preference for quantized (int8) models
- ✅ **Flexible Model Loading** - Asset models, file system models, or auto-detection
- ✅ **Cross-Platform** - Works on both iOS and Android
- ✅ **TypeScript Support** - Full TypeScript definitions included

## Installation

```sh
npm install react-native-sherpa-onnx-stt
```

### iOS

```sh
cd ios && pod install
```

### Android

No additional setup required. The library automatically handles native dependencies.

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

### Cleanup

```typescript
import { unloadSherpaOnnx } from 'react-native-sherpa-onnx-stt';

// Release resources when done
await unloadSherpaOnnx();
```

## Model Setup

The library does **not** bundle models. You must provide your own models. See [MODEL_SETUP.md](./MODEL_SETUP.md) for detailed setup instructions.

### Supported Model Types

- **Zipformer/Transducer**: Requires `encoder.onnx`, `decoder.onnx`, `joiner.onnx`, and `tokens.txt`
- **Zipformer/Transducer int8**: Requires `encoder.int8.onnx`, `decoder.int8.onnx`, `joiner.int8.onnx`, and `tokens.txt`
- **Paraformer**: Requires `model.onnx` (or `model.int8.onnx`) and `tokens.txt`

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
- iOS 13.0+
- Android API 24+ (Android 7.0+)

## Contributing

- [Development workflow](CONTRIBUTING.md#development-workflow)
- [Sending a pull request](CONTRIBUTING.md#sending-a-pull-request)
- [Code of conduct](CODE_OF_CONDUCT.md)

## License

MIT

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
