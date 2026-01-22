# Model Setup Guide

This guide explains how to provide models for `react-native-sherpa-onnx-stt`.

## Overview

The library does **not** bundle models. App developers must provide models themselves. The library supports multiple ways to load models:

1. **Asset Models** - Bundled in app (for smaller models)
2. **File System Models** - Downloaded or user-provided (recommended for larger models)
3. **Auto-detection** - Tries asset first, then file system

## Model Requirements

- Valid sherpa-onnx ASR model directory structure
- Model files must be accessible by the app
- Supported formats: Zipformer, Parakeet, etc.

## Setup Options

### Option 1: Asset Models (Bundled)

For smaller models that can be bundled with your app:

#### iOS

1. Add model directory to Xcode project:

   - Right-click your project --> "Add Files to..."
   - Select your model directory
   - Check "Create folder references" (blue folder icon)
   - Ensure "Copy items if needed" is checked

2. Model will be available at: `Bundle.main.path(forResource: "model-name", ofType: nil)`

#### Android

1. Place models in `android/app/src/main/assets/models/`:

   **For Zipformer/Transducer models:**

   ```
   android/app/src/main/assets/models/sherpa-onnx-zipformer-small-en/
     ├── encoder.onnx          (or encoder.int8.onnx for quantized)
     ├── decoder.onnx          (or decoder.int8.onnx for quantized)
     ├── joiner.onnx           (or joiner.int8.onnx for quantized)
     └── tokens.txt            (REQUIRED)
   ```

   **For Paraformer models:**

   ```
   android/app/src/main/assets/models/sherpa-onnx-paraformer-zh-small/
     ├── model.onnx            (or model.int8.onnx for quantized)
     └── tokens.txt            (REQUIRED)
   ```

   **For NeMo CTC models:**

   ```
   android/app/src/main/assets/models/sherpa-onnx-nemo-parakeet-tdt-ctc-en/
     ├── model.onnx            (or model.int8.onnx for quantized)
     └── tokens.txt            (REQUIRED)
   ```

   **For Whisper models:**

   ```
   android/app/src/main/assets/models/sherpa-onnx-whisper-tiny-en/
     ├── encoder.onnx          (or encoder.int8.onnx for quantized)
     ├── decoder.onnx          (or decoder.int8.onnx for quantized)
     └── tokens.txt            (REQUIRED)
   ```

   **For WeNet CTC models:**

   ```
   android/app/src/main/assets/models/sherpa-onnx-wenetspeech-ctc-zh-en-cantonese/
     ├── model.onnx            (or model.int8.onnx for quantized)
     └── tokens.txt            (REQUIRED)
   ```

   **For SenseVoice models:**

   ```
   android/app/src/main/assets/models/sherpa-onnx-sense-voice-zh-en-ja-ko-yue/
     ├── model.onnx            (or model.int8.onnx for quantized)
     └── tokens.txt            (REQUIRED)
   ```

   **For FunASR Nano models:**

   ```
   android/app/src/main/assets/models/sherpa-onnx-funasr-nano-2025-12-30/
     ├── encoder_adaptor.onnx  (or encoder_adaptor.int8.onnx for quantized)
     ├── llm.onnx              (or llm.int8.onnx for quantized)
     ├── embedding.onnx        (or embedding.int8.onnx for quantized)
     └── Qwen3-0.6B/           (tokenizer directory)
         ├── vocab.json        (REQUIRED)
         ├── merges.txt         (REQUIRED)
         └── tokenizer.json     (REQUIRED)
   ```

   **Note:** The library automatically detects and prefers quantized `.int8.onnx` models when available. You can control this behavior with the `preferInt8` option (see Usage section).

2. Model will be available at: `assets/models/sherpa-onnx-zipformer-small-en`

#### Usage

```typescript
import {
  initializeSherpaOnnx,
  assetModelPath,
} from 'react-native-sherpa-onnx-stt';

await initializeSherpaOnnx({
  modelPath: assetModelPath('models/sherpa-onnx-model'),
});
```

### Option 2: File System Models (Downloaded)

For larger models or when you want to download models at runtime:

#### iOS

1. Download models to app's Documents directory:
   ```swift
   let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
   let modelPath = documentsPath.appendingPathComponent("models/sherpa-onnx-model")
   ```

#### Android

1. Download models to app's internal storage:
   ```kotlin
   val modelDir = File(context.filesDir, "models/sherpa-onnx-model")
   ```

#### Usage

```typescript
import {
  initializeSherpaOnnx,
  fileModelPath,
} from 'react-native-sherpa-onnx-stt';
import RNFS from 'react-native-fs';

// Download model first (example)
const modelUrl = 'https://example.com/models/sherpa-onnx-model.zip';
const downloadPath = `${RNFS.DocumentDirectoryPath}/models/sherpa-onnx-model`;
await RNFS.downloadFile({ fromUrl: modelUrl, toFile: downloadPath }).promise;

// Initialize with file path
await initializeSherpaOnnx({
  modelPath: fileModelPath(downloadPath),
  preferInt8: true, // Optional: prefer quantized models
});
```

### Option 3: Auto-detection

Let the library try asset first, then file system:

```typescript
import {
  initializeSherpaOnnx,
  autoModelPath,
} from 'react-native-sherpa-onnx-stt';

await initializeSherpaOnnx({
  modelPath: autoModelPath('models/sherpa-onnx-model'),
  preferInt8: true, // Optional: prefer quantized models
});
```

### Option 4: Simple String (Backward Compatible)

For backward compatibility, you can pass a simple string:

```typescript
import { initializeSherpaOnnx } from 'react-native-sherpa-onnx-stt';

// Will auto-detect (tries asset, then file system)
// Default behavior: tries int8 models first, then regular models
await initializeSherpaOnnx('models/sherpa-onnx-model');

// With preferInt8 option
await initializeSherpaOnnx({
  modelPath: 'models/sherpa-onnx-model',
  preferInt8: true,
});
```

## Model Quantization Preference

The library supports both regular and quantized (int8) model formats. By default, it tries quantized models first (smaller, faster), then falls back to regular models.

- **Quantized models** (`*.int8.onnx`): Smaller file size (~70% reduction), faster inference, slightly lower accuracy
- **Regular models** (`*.onnx`): Larger file size, higher accuracy

Control this behavior with the `preferInt8` option:

```typescript
// Default: try int8 first, then regular
await initializeSherpaOnnx({ modelPath: 'models/my-model' });

// Explicitly prefer int8 models
await initializeSherpaOnnx({
  modelPath: 'models/my-model',
  preferInt8: true,
});

// Explicitly prefer regular models
await initializeSherpaOnnx({
  modelPath: 'models/my-model',
  preferInt8: false,
});
```

## Example: Complete Setup

```typescript
import {
  initializeSherpaOnnx,
  assetModelPath,
  transcribeFile,
} from 'react-native-sherpa-onnx-stt';

async function setupSTT() {
  try {
    // Initialize with asset model
    await initializeSherpaOnnx({
      modelPath: assetModelPath('models/sherpa-onnx-model'),
      preferInt8: true, // Prefer quantized models for mobile
    });
    console.log('STT initialized successfully');

    // Transcribe an audio file
    const transcription = await transcribeFile('path/to/audio.wav');
    console.log('Transcription:', transcription);
  } catch (error) {
    console.error('Failed to initialize STT:', error);
  }
}
```

## Platform-Specific Notes

### iOS

- Asset models: Must be added to Xcode project
- File models: Use `Documents/` or `Library/Application Support/`
- Paths are case-sensitive

### Android

- Asset models: Place in `android/app/src/main/assets/`
- File models: Use `getFilesDir()` or `getExternalFilesDir()`
- Paths are case-sensitive

## Troubleshooting

### Model Not Found

- Verify model directory structure matches sherpa-onnx requirements
- Check path is correct (case-sensitive)
- Ensure models are accessible (permissions, bundle inclusion)

### Initialization Fails

- Check model files are complete
- Verify model format is supported
- Check native logs for detailed error messages
