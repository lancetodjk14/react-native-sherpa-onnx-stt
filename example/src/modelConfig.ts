/**
 * Model configuration for the example app.
 * This is app-specific and not part of the library.
 * Users should create their own model configuration based on their needs.
 */

import {
  autoModelPath,
  assetModelPath,
  fileModelPath,
  getDefaultModelPath,
  type ModelPathConfig,
} from 'react-native-sherpa-onnx-stt';

/**
 * Predefined model identifiers for this example app
 */
export const MODELS = {
  ZIPFORMER_EN: 'sherpa-onnx-zipformer-small-en',
  PARAFORMER_ZH: 'sherpa-onnx-paraformer-zh-small',
  NEMO_CTC_EN: 'sherpa-onnx-nemo-parakeet-tdt-ctc-en',
} as const;

export type ModelId = (typeof MODELS)[keyof typeof MODELS];

/**
 * Get model path for a predefined model identifier.
 * Uses auto-detection (tries asset first, then file system).
 *
 * @param modelId - Predefined model identifier (e.g., MODELS.ZIPFORMER_EN)
 * @returns Model path configuration
 */
export function getModelPath(modelId: ModelId): ModelPathConfig {
  return autoModelPath(`models/${modelId}`);
}

/**
 * Get asset model path for a predefined model identifier.
 *
 * @param modelId - Predefined model identifier (e.g., MODELS.ZIPFORMER_EN)
 * @returns Model path configuration
 */
export function getAssetModelPath(modelId: ModelId): ModelPathConfig {
  return assetModelPath(`models/${modelId}`);
}

/**
 * Get file system model path for a predefined model identifier.
 *
 * @param modelId - Predefined model identifier (e.g., MODELS.ZIPFORMER_EN)
 * @param basePath - Base path for file system models (default: platform-specific)
 * @returns Model path configuration
 */
export function getFileModelPath(
  modelId: ModelId,
  basePath?: string
): ModelPathConfig {
  const path = basePath
    ? `${basePath}/${modelId}`
    : `${getDefaultModelPath()}/${modelId}`;
  return fileModelPath(path);
}
