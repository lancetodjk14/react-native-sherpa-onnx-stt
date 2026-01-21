#include "sherpa-onnx-wrapper.h"
#include <android/log.h>
#include <fstream>
#include <sstream>
#include <optional>
#include <sys/stat.h>

// Use filesystem if available (C++17), otherwise fallback
#if __cplusplus >= 201703L && __has_include(<filesystem>)
#include <filesystem>
namespace fs = std::filesystem;
#elif __has_include(<experimental/filesystem>)
#include <experimental/filesystem>
namespace fs = std::experimental::filesystem;
#else
// Fallback: use stat/opendir for older compilers
#include <sys/stat.h>
#include <dirent.h>
#endif

// sherpa-onnx headers - use cxx-api which is compatible with libsherpa-onnx-cxx-api.so
#include "sherpa-onnx/c-api/cxx-api.h"

#define LOG_TAG "SherpaOnnxWrapper"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

namespace sherpaonnxstt {

// PIMPL pattern implementation
class SherpaOnnxWrapper::Impl {
public:
    bool initialized = false;
    std::string modelDir;
    std::optional<sherpa_onnx::cxx::OfflineRecognizer> recognizer;
};

SherpaOnnxWrapper::SherpaOnnxWrapper() : pImpl(std::make_unique<Impl>()) {
    LOGI("SherpaOnnxWrapper created");
}

SherpaOnnxWrapper::~SherpaOnnxWrapper() {
    release();
    LOGI("SherpaOnnxWrapper destroyed");
}

bool SherpaOnnxWrapper::initialize(const std::string& modelDir, const std::optional<bool>& preferInt8) {
    if (pImpl->initialized) {
        release();
    }

    if (modelDir.empty()) {
        LOGE("Model directory is empty");
        return false;
    }

    try {
        // Helper function to check if file exists
        auto fileExists = [](const std::string& path) -> bool {
#if __cplusplus >= 201703L && __has_include(<filesystem>)
            return std::filesystem::exists(path);
#elif __has_include(<experimental/filesystem>)
            return std::experimental::filesystem::exists(path);
#else
            struct stat buffer;
            return (stat(path.c_str(), &buffer) == 0);
#endif
        };

        auto isDirectory = [](const std::string& path) -> bool {
#if __cplusplus >= 201703L && __has_include(<filesystem>)
            return std::filesystem::is_directory(path);
#elif __has_include(<experimental/filesystem>)
            return std::experimental::filesystem::is_directory(path);
#else
            struct stat buffer;
            if (stat(path.c_str(), &buffer) != 0) return false;
            return S_ISDIR(buffer.st_mode);
#endif
        };

        // Check if model directory exists
        if (!fileExists(modelDir) || !isDirectory(modelDir)) {
            LOGE("Model directory does not exist or is not a directory: %s", modelDir.c_str());
            return false;
        }

        // Setup configuration
        sherpa_onnx::cxx::OfflineRecognizerConfig config;
        
        // Build paths for model files
        std::string encoderPath = modelDir + "/encoder.onnx";
        std::string decoderPath = modelDir + "/decoder.onnx";
        std::string joinerPath = modelDir + "/joiner.onnx";
        std::string paraformerPathInt8 = modelDir + "/model.int8.onnx";
        std::string paraformerPath = modelDir + "/model.onnx";
        std::string tokensPath = modelDir + "/tokens.txt";

        // Check if tokens file exists (required for both model types)
        if (!fileExists(tokensPath)) {
            LOGE("Tokens file not found: %s", tokensPath.c_str());
            return false;
        }
        config.model_config.tokens = tokensPath;

        // Configure based on model type
        // Check for Paraformer model based on preferInt8 preference
        std::string paraformerModelPath;
        if (preferInt8.has_value()) {
            if (preferInt8.value()) {
                // Prefer int8 models
                if (fileExists(paraformerPathInt8)) {
                    paraformerModelPath = paraformerPathInt8;
                } else if (fileExists(paraformerPath)) {
                    paraformerModelPath = paraformerPath;
                }
            } else {
                // Prefer regular models
                if (fileExists(paraformerPath)) {
                    paraformerModelPath = paraformerPath;
                } else if (fileExists(paraformerPathInt8)) {
                    paraformerModelPath = paraformerPathInt8;
                }
            }
        } else {
            // Default: try int8 first, then regular
            if (fileExists(paraformerPathInt8)) {
                paraformerModelPath = paraformerPathInt8;
            } else if (fileExists(paraformerPath)) {
                paraformerModelPath = paraformerPath;
            }
        }
        
        if (!paraformerModelPath.empty()) {
            // Paraformer model
            LOGI("Detected Paraformer model: %s", paraformerModelPath.c_str());
            config.model_config.paraformer.model = paraformerModelPath;
        } else if (fileExists(encoderPath) && 
                   fileExists(decoderPath) && 
                   fileExists(joinerPath)) {
            // Zipformer/Transducer model
            LOGI("Detected Transducer model: encoder=%s, decoder=%s, joiner=%s", 
                 encoderPath.c_str(), decoderPath.c_str(), joinerPath.c_str());
            config.model_config.transducer.encoder = encoderPath;
            config.model_config.transducer.decoder = decoderPath;
            config.model_config.transducer.joiner = joinerPath;
        } else {
            LOGE("No valid model files found in directory: %s", modelDir.c_str());
            LOGE("Checked paths:");
            LOGE("  Paraformer (int8): %s (exists: %s)", paraformerPathInt8.c_str(), fileExists(paraformerPathInt8) ? "yes" : "no");
            LOGE("  Paraformer: %s (exists: %s)", paraformerPath.c_str(), fileExists(paraformerPath) ? "yes" : "no");
            LOGE("  Encoder: %s (exists: %s)", encoderPath.c_str(), fileExists(encoderPath) ? "yes" : "no");
            LOGE("  Decoder: %s (exists: %s)", decoderPath.c_str(), fileExists(decoderPath) ? "yes" : "no");
            LOGE("  Joiner: %s (exists: %s)", joinerPath.c_str(), fileExists(joinerPath) ? "yes" : "no");
            LOGE("Expected either paraformer model (model.onnx or model.int8.onnx) or transducer model (encoder.onnx, decoder.onnx, joiner.onnx)");
            return false;
        }

        // Set common configuration
        config.decoding_method = "greedy_search";
        config.model_config.num_threads = 4;
        config.model_config.provider = "cpu";

        // Create recognizer
        LOGI("Creating OfflineRecognizer with config: tokens=%s, num_threads=%d, provider=%s", 
             config.model_config.tokens.c_str(), config.model_config.num_threads, config.model_config.provider.c_str());
        try {
            auto recognizer = sherpa_onnx::cxx::OfflineRecognizer::Create(config);
            // Check if recognizer is valid by checking internal pointer
            if (recognizer.Get() == nullptr) {
                LOGE("Failed to create OfflineRecognizer: Create returned invalid object (nullptr)");
                return false;
            }
            pImpl->recognizer = std::move(recognizer);
            LOGI("OfflineRecognizer created successfully");
        } catch (const std::exception& e) {
            LOGE("Failed to create OfflineRecognizer: %s", e.what());
            return false;
        }

        pImpl->modelDir = modelDir;
        pImpl->initialized = true;
        return true;
    } catch (const std::exception& e) {
        LOGE("Exception during initialization: %s", e.what());
        return false;
    } catch (...) {
        LOGE("Unknown exception during initialization");
        return false;
    }
}

std::string SherpaOnnxWrapper::transcribeFile(const std::string& filePath) {
    if (!pImpl->initialized || !pImpl->recognizer.has_value()) {
        LOGE("Not initialized. Call initialize() first.");
        return "";
    }

    try {
        // Helper function to check if file exists
        auto fileExists = [](const std::string& path) -> bool {
#if __cplusplus >= 201703L && __has_include(<filesystem>)
            return std::filesystem::exists(path);
#elif __has_include(<experimental/filesystem>)
            return std::experimental::filesystem::exists(path);
#else
            struct stat buffer;
            return (stat(path.c_str(), &buffer) == 0);
#endif
        };

        // Check if file exists
        if (!fileExists(filePath)) {
            LOGE("Audio file does not exist: %s", filePath.c_str());
            return "";
        }

        // Read audio file using cxx-api
        sherpa_onnx::cxx::Wave wave = sherpa_onnx::cxx::ReadWave(filePath);
        
        if (wave.samples.empty()) {
            LOGE("Failed to read wave file or file is empty: %s", filePath.c_str());
            return "";
        }

        // Create a stream
        auto stream = pImpl->recognizer.value().CreateStream();
        
        // Feed audio data to the stream (all samples at once for offline recognition)
        stream.AcceptWaveform(wave.sample_rate, wave.samples.data(), wave.samples.size());

        // Decode the stream
        pImpl->recognizer.value().Decode(&stream);

        // Get result
        auto result = pImpl->recognizer.value().GetResult(&stream);

        return result.text;
    } catch (const std::exception& e) {
        LOGE("Exception during transcription: %s", e.what());
        return "";
    } catch (...) {
        LOGE("Unknown exception during transcription");
        return "";
    }
}

bool SherpaOnnxWrapper::isInitialized() const {
    return pImpl->initialized;
}

void SherpaOnnxWrapper::release() {
    if (pImpl->initialized) {
        // OfflineRecognizer uses RAII - destruction happens automatically when optional is reset
        pImpl->recognizer.reset();
        pImpl->initialized = false;
        pImpl->modelDir.clear();
    }
}

} // namespace sherpaonnxstt
