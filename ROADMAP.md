# react-native-sherpa-onnx-stt – Specification

## Project Goal

The goal of this project is to build a **React Native TurboModule** that provides a clean, idiomatic JavaScript/TypeScript API for **offline speech-to-text (STT)** using **sherpa-onnx** on **Android and iOS**.

The library should:

- Run **fully on-device**, without any network/API calls.
- Support **file-based transcription** (e.g. WAV from disk) as first-class feature.
- Be **publishable on npm** and usable as a standard React Native dependency.
- Be designed so that it can later be extended to support **streaming STT** and additional sherpa-onnx features.

---

## Scope (MVP)

### Platforms

- React Native (New Architecture, TurboModule)
- Android (Kotlin, NDK where required)
- iOS (Swift)

Out of scope for the MVP:

- Web, Windows, macOS, tvOS, etc.
- Text-to-Speech and other sherpa-onnx features (may be added later).

### Core Features

1. **Offline file transcription**

   - Input: Path to a local audio file (initially WAV 16 kHz mono 16‑bit PCM).
   - Processing: sherpa-onnx offline ASR model.
   - Output: Recognized text (string) and optional metadata (e.g. duration, timings in a later version).

2. **Basic model management**

   - Ability to specify the **model directory** (where sherpa-onnx models are stored).
   - Initialize and reuse a model/recognizer instance across multiple calls.
   - Simple API to:
     - Load a model
     - Release model resources (e.g. on app exit or memory pressure)

3. **Error handling**

   - Clear errors for:
     - Invalid file path
     - Unsupported audio format
     - Model not found / not initialized
     - Internal sherpa-onnx errors
   - Errors should be surfaced as **rejected Promises** in JS.

4. **TypeScript-friendly API**
   - Public API fully typed (TS definitions shipped with the package).
   - Minimal, intuitive API surface.

---

## Non-Goals (for the first version)

- Real-time microphone streaming STT (can be added later).
- VAD, keyword spotting, diarization, etc.
- Model download/updates (MVP assumes models are already present on the device).
- Complex configuration / custom pipelines exposed to JS.
- Platform-agnostic audio transcoding (MVP tries to work with a standard WAV format).

---

## High-Level Architecture

### JavaScript / TypeScript API

Public module name (example):

```ts
import {
  initializeSherpaOnnx,
  transcribeFile,
  unloadSherpaOnnx,
  type SherpaOnnxInitOptions,
  type SherpaOnnxTranscriptionResult,
} from 'react-native-sherpa-onnx-stt';
```

#### Types

```ts
export type SherpaOnnxInitOptions = {
  modelDir: string; // Absolute or app-relative path to sherpa-onnx ASR model files
  numThreads?: number; // Optional: threading hint for performance
  sampleRate?: number; // Expected sample rate (default: 16000)
};

export type SherpaOnnxTranscriptionResult = {
  text: string;
  durationMs?: number;
  // Future: word-level timestamps, confidence, etc.
};
```

#### Public API (MVP)

```ts
/**
 * Initialize sherpa-onnx recognizer with a given model directory.
 * Must be called once before transcribeFile.
 */
export function initializeSherpaOnnx(
  options: SherpaOnnxInitOptions
): Promise<void>;

/**
 * Transcribe a local audio file using the initialized sherpa-onnx recognizer.
 */
export function transcribeFile(
  filePath: string
): Promise<SherpaOnnxTranscriptionResult>;

/**
 * Release underlying sherpa-onnx resources.
 */
export function unloadSherpaOnnx(): Promise<void>;
```

Contract:

- `initializeSherpaOnnx`:
  - Throws/rejects if models cannot be loaded.
  - Is idempotent (calling it multiple times either reuses or reinitializes cleanly).
- `transcribeFile`:
  - Rejects if called before initialization.
  - Rejects if file path is invalid or cannot be decoded.
- `unloadSherpaOnnx`:
  - Frees native resources and resets internal state.

### Native Layer (TurboModule)

- TurboModule name (example): `RNSherpaOnnxStt`
- Implemented in:
  - Android: `RNSherpaOnnxSttModule.kt`
  - iOS: `RNSherpaOnnxSttModule.swift`
- Uses sherpa-onnx APIs to:
  - Load offline ASR model(s).
  - Create and hold a recognizer instance.
  - Read audio file, convert to expected format if necessary.
  - Run recognition and return a string.

#### Native Responsibilities

- **Android**

  - Integrate sherpa-onnx through Gradle/CMake (AAR, .so, etc.).
  - Implement JNI/NDK glue where required.
  - Handle file I/O and audio decoding (preferably via platform APIs / libraries).
  - Convert to PCM 16 kHz mono if needed.

- **iOS**
  - Integrate sherpa-onnx via Swift/Objective‑C (XCFramework, CocoaPods, SPM).
  - Use AVFoundation or other APIs to decode audio file.
  - Convert to PCM 16 kHz mono if needed.

---

## Model Handling

### Model Location

- Models are not bundled inside the library.
- App developer is responsible for:
  - Downloading and placing model files in an app-accessible directory.
  - Passing `modelDir` to `initializeSherpaOnnx`.

### Requirements (MVP)

- At least one English offline ASR model (e.g. sherpa-onnx Zipformer or Parakeet).
- Library should not assume a specific model name; it should just require a valid sherpa-onnx ASR directory structure.

---

## Developer Experience & Publishing

### Package Name

- npm package: `react-native-sherpa-onnx-stt`

### Repository Contents

- `src/` – TypeScript API
- `android/` – Kotlin module + sherpa-onnx integration
- `ios/` – Swift module + sherpa-onnx integration
- `example/` – Example React Native app demonstrating:
  - Initialization
  - File picking
  - Transcription
  - Basic error handling
- `README.md` – Usage, setup, supported platforms, limitations
- `LICENSE` – Open source license (e.g. MIT or Apache-2.0, compatible with sherpa-onnx)

### Publishing Goals

- Library should:
  - Build cleanly on CI for Android and iOS.
  - Work with React Native New Architecture (TurboModule).
  - Be installable via:
    - `npm install react-native-sherpa-onnx-stt`
    - `yarn add react-native-sherpa-onnx-stt`
  - Follow React Native community conventions for libraries (e.g. using `react-native-builder-bob`).

---

## Roadmap (nach dem MVP)

- Streaming microphone STT (real-time recognition).
- Voice activity detection (VAD) integration.
- Multi-language model switching from JS.
- Word/segment timestamps and confidence scores.
- Helper utilities for model download and management.
- Optional TTS exposure in the same package or a sibling package.

---
