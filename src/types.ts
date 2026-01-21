/**
 * Model path configuration options
 */
export type ModelPathConfig =
  | {
      /**
       * Path type: 'asset' - Model is bundled in app assets
       * On iOS: Bundle path (e.g., "models/sherpa-onnx-model")
       * On Android: Asset path (e.g., "models/sherpa-onnx-model")
       */
      type: 'asset';
      path: string;
    }
  | {
      /**
       * Path type: 'file' - Model is in file system
       * Absolute path to model directory
       */
      type: 'file';
      path: string;
    }
  | {
      /**
       * Path type: 'auto' - Automatically detect path type
       * Tries asset first, then file system
       */
      type: 'auto';
      path: string;
    };

/**
 * Model type for explicit model detection
 */
export type ModelType = 'transducer' | 'paraformer' | 'nemo_ctc' | 'auto';

/**
 * Model initialization options
 */
export interface InitializeOptions {
  /**
   * Model directory path configuration
   */
  modelPath: ModelPathConfig | string; // string for backward compatibility

  /**
   * Model quantization preference
   * - true: Prefer int8 quantized models (model.int8.onnx) - smaller, faster
   * - false: Prefer regular models (model.onnx) - higher accuracy
   * - undefined: Try int8 first, then fall back to regular (default behavior)
   */
  preferInt8?: boolean;

  /**
   * Explicit model type specification
   * - 'transducer': Force detection as Zipformer/Transducer model
   * - 'paraformer': Force detection as Paraformer model
   * - 'nemo_ctc': Force detection as NeMo CTC model
   * - 'auto': Automatic detection based on files (default)
   */
  modelType?: ModelType;
}
