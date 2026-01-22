# react-native-sherpa-onnx-stt

Offline Speech-to-Text with sherpa-onnx for React Native

[![npm version](https://img.shields.io/npm/v/react-native-sherpa-onnx-stt.svg)](https://www.npmjs.com/package/react-native-sherpa-onnx-stt)
[![npm downloads](https://img.shields.io/npm/dm/react-native-sherpa-onnx-stt.svg)](https://www.npmjs.com/package/react-native-sherpa-onnx-stt)
[![npm license](https://img.shields.io/npm/l/react-native-sherpa-onnx-stt.svg)](https://www.npmjs.com/package/react-native-sherpa-onnx-stt)

A React Native TurboModule that provides offline speech recognition capabilities using [sherpa-onnx](https://github.com/k2-fsa/sherpa-onnx). Supports multiple model architectures including Zipformer/Transducer, Paraformer, NeMo CTC, and Whisper.

## Platform Support

| Platform | Status  |
| -------- | ------- |
| Android  | ✅ Yes  |
| iOS      | ❌ Soon |

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
- ✅ **TypeScript Support** - Full TypeScript definitions included

## Installation

```sh
npm install react-native-sherpa-onnx-stt
```

### Android

No additional setup required. The library automatically handles native dependencies.

### iOS

iOS support is currently not available. This library is Android-only at the moment.

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
- iOS: Not currently supported

## Contributing

- [Development workflow](CONTRIBUTING.md#development-workflow)
- [Sending a pull request](CONTRIBUTING.md#sending-a-pull-request)
- [Code of conduct](CODE_OF_CONDUCT.md)

## License

MIT

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
