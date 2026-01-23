#include "sherpa-onnx-wrapper.h"
#include <fstream>
#include <sstream>
#include <optional>
#include <algorithm>
#include <cctype>
#include <cstring>

// iOS logging
#ifdef __APPLE__
#include <Foundation/Foundation.h>
#include <cstdio>
#define LOGI(fmt, ...) NSLog(@"SherpaOnnxWrapper: " fmt, ##__VA_ARGS__)
#define LOGE(fmt, ...) NSLog(@"SherpaOnnxWrapper ERROR: " fmt, ##__VA_ARGS__)
#else
#define LOGI(...)
#define LOGE(...)
#endif

// Use C++17 filesystem (podspec enforces C++17)
#include <filesystem>
namespace fs = std::filesystem;

// sherpa-onnx headers - use C API directly (more reliable linking)
#include "sherpa-onnx/c-api/c-api.h"

namespace sherpaonnxstt {

// PIMPL pattern implementation
class SherpaOnnxWrapper::Impl {
public:
    bool initialized = false;
    std::string modelDir;
    const SherpaOnnxOfflineRecognizer* recognizer = nullptr;
    
    ~Impl() {
        if (recognizer) {
            SherpaOnnxDestroyOfflineRecognizer(recognizer);
            recognizer = nullptr;
        }
    }
};

SherpaOnnxWrapper::SherpaOnnxWrapper() : pImpl(std::make_unique<Impl>()) {
    LOGI("SherpaOnnxWrapper created");
}

SherpaOnnxWrapper::~SherpaOnnxWrapper() {
    release();
    LOGI("SherpaOnnxWrapper destroyed");
}

bool SherpaOnnxWrapper::initialize(
    const std::string& modelDir,
    const std::optional<bool>& preferInt8,
    const std::optional<std::string>& modelType
) {
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
            return fs::exists(path);
        };

        auto isDirectory = [](const std::string& path) -> bool {
            return fs::is_directory(path);
        };

        // Check if model directory exists
        if (!fileExists(modelDir) || !isDirectory(modelDir)) {
            LOGE("Model directory does not exist or is not a directory: %s", modelDir.c_str());
            return false;
        }

        // Setup configuration - zero initialize all fields
        SherpaOnnxOfflineRecognizerConfig config;
        memset(&config, 0, sizeof(config));
        
        // Set default feature config (16kHz, 80-dim for most models)
        config.feat_config.sample_rate = 16000;
        config.feat_config.feature_dim = 80;
        
        // Build paths for model files
        std::string encoderPath = modelDir + "/encoder.onnx";
        std::string decoderPath = modelDir + "/decoder.onnx";
        std::string joinerPath = modelDir + "/joiner.onnx";
        std::string encoderPathInt8 = modelDir + "/encoder.int8.onnx";
        std::string decoderPathInt8 = modelDir + "/decoder.int8.onnx";
        std::string paraformerPathInt8 = modelDir + "/model.int8.onnx";
        std::string paraformerPath = modelDir + "/model.onnx";
        std::string ctcPathInt8 = modelDir + "/model.int8.onnx";
        std::string ctcPath = modelDir + "/model.onnx";
        std::string tokensPath = modelDir + "/tokens.txt";
        
        // FunASR Nano paths
        std::string funasrEncoderAdaptor = modelDir + "/encoder_adaptor.onnx";
        std::string funasrEncoderAdaptorInt8 = modelDir + "/encoder_adaptor.int8.onnx";
        std::string funasrLLM = modelDir + "/llm.onnx";
        std::string funasrLLMInt8 = modelDir + "/llm.int8.onnx";
        std::string funasrEmbedding = modelDir + "/embedding.onnx";
        std::string funasrEmbeddingInt8 = modelDir + "/embedding.int8.onnx";
        
        // Helper function to find FunASR Nano tokenizer directory
        auto findFunAsrTokenizer = [&fileExists, &modelDir]() -> std::string {
            std::string vocabInMain = modelDir + "/vocab.json";
            if (fileExists(vocabInMain)) {
                return modelDir;
            }
            
            try {
                for (const auto& entry : fs::directory_iterator(modelDir)) {
                    if (entry.is_directory()) {
                        std::string dirName = entry.path().filename().string();
                        std::string dirNameLower = dirName;
                        std::transform(dirNameLower.begin(), dirNameLower.end(), dirNameLower.begin(),
                                       [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
                        if (dirNameLower.find("qwen3") != std::string::npos) {
                            std::string vocabPath = entry.path().string() + "/vocab.json";
                            if (fileExists(vocabPath)) {
                                return entry.path().string();
                            }
                        }
                    }
                }
            } catch (const std::exception& e) {
                // Error accessing directory
            }
            
            std::string commonPath = modelDir + "/Qwen3-0.6B";
            if (fileExists(commonPath + "/vocab.json")) {
                return commonPath;
            }
            
            return "";
        };
        
        std::string funasrTokenizer = findFunAsrTokenizer();

        bool tokensRequired = true;

        // Configure based on model type - same logic as Android version
        std::string paraformerModelPath;
        if (preferInt8.has_value()) {
            if (preferInt8.value()) {
                if (fileExists(paraformerPathInt8)) {
                    paraformerModelPath = paraformerPathInt8;
                } else if (fileExists(paraformerPath)) {
                    paraformerModelPath = paraformerPath;
                }
            } else {
                if (fileExists(paraformerPath)) {
                    paraformerModelPath = paraformerPath;
                } else if (fileExists(paraformerPathInt8)) {
                    paraformerModelPath = paraformerPathInt8;
                }
            }
        } else {
            if (fileExists(paraformerPathInt8)) {
                paraformerModelPath = paraformerPathInt8;
            } else if (fileExists(paraformerPath)) {
                paraformerModelPath = paraformerPath;
            }
        }
        
        std::string ctcModelPath;
        if (preferInt8.has_value()) {
            if (preferInt8.value()) {
                if (fileExists(ctcPathInt8)) {
                    ctcModelPath = ctcPathInt8;
                } else if (fileExists(ctcPath)) {
                    ctcModelPath = ctcPath;
                }
            } else {
                if (fileExists(ctcPath)) {
                    ctcModelPath = ctcPath;
                } else if (fileExists(ctcPathInt8)) {
                    ctcModelPath = ctcPathInt8;
                }
            }
        } else {
            if (fileExists(ctcPathInt8)) {
                ctcModelPath = ctcPathInt8;
            } else if (fileExists(ctcPath)) {
                ctcModelPath = ctcPath;
            }
        }
        
        bool hasTransducer = fileExists(encoderPath) && 
                             fileExists(decoderPath) && 
                             fileExists(joinerPath);
        
        bool hasWhisperEncoder = fileExists(encoderPath) || fileExists(encoderPathInt8);
        bool hasWhisperDecoder = fileExists(decoderPath) || fileExists(decoderPathInt8);
        bool hasWhisper = hasWhisperEncoder && hasWhisperDecoder && !fileExists(joinerPath);
        
        bool hasFunAsrEncoderAdaptor = fileExists(funasrEncoderAdaptor) || fileExists(funasrEncoderAdaptorInt8);
        bool hasFunAsrLLM = fileExists(funasrLLM) || fileExists(funasrLLMInt8);
        bool hasFunAsrEmbedding = fileExists(funasrEmbedding) || fileExists(funasrEmbeddingInt8);
        bool hasFunAsrTokenizer = !funasrTokenizer.empty() && fileExists(funasrTokenizer + "/vocab.json");
        bool hasFunAsrNano = hasFunAsrEncoderAdaptor && hasFunAsrLLM && hasFunAsrEmbedding && hasFunAsrTokenizer;
        
        bool isLikelyNemoCtc = modelDir.find("nemo") != std::string::npos ||
                                modelDir.find("parakeet") != std::string::npos;
        bool isLikelyWenetCtc = modelDir.find("wenet") != std::string::npos;
        bool isLikelySenseVoice = modelDir.find("sense") != std::string::npos ||
                                  modelDir.find("sensevoice") != std::string::npos;
        bool isLikelyFunAsrNano = modelDir.find("funasr") != std::string::npos ||
                                  modelDir.find("funasr-nano") != std::string::npos;
        bool isLikelyWhisper = modelDir.find("whisper") != std::string::npos;
        
        bool modelConfigured = false;
        
        // Store paths as member variables to ensure they stay alive
        // We need to keep these strings alive for the lifetime of the config
        static thread_local std::string s_encoderPath, s_decoderPath, s_joinerPath;
        static thread_local std::string s_paraformerModel, s_ctcModel, s_tokensPath;
        static thread_local std::string s_whisperEncoder, s_whisperDecoder;
        static thread_local std::string s_funasrEncoderAdaptor, s_funasrLLM, s_funasrEmbedding, s_funasrTokenizer;
        static thread_local std::string s_senseVoiceLanguage;
        
        // Use explicit model type if provided
        if (modelType.has_value()) {
            std::string type = modelType.value();
            if (type == "transducer" && hasTransducer) {
                LOGI("Using explicit Transducer model type");
                s_encoderPath = encoderPath;
                s_decoderPath = decoderPath;
                s_joinerPath = joinerPath;
                config.model_config.transducer.encoder = s_encoderPath.c_str();
                config.model_config.transducer.decoder = s_decoderPath.c_str();
                config.model_config.transducer.joiner = s_joinerPath.c_str();
                modelConfigured = true;
            } else if (type == "paraformer" && !paraformerModelPath.empty()) {
                LOGI("Using explicit Paraformer model type: %s", paraformerModelPath.c_str());
                s_paraformerModel = paraformerModelPath;
                config.model_config.paraformer.model = s_paraformerModel.c_str();
                modelConfigured = true;
            } else if (type == "nemo_ctc" && !ctcModelPath.empty()) {
                LOGI("Using explicit NeMo CTC model type: %s", ctcModelPath.c_str());
                s_ctcModel = ctcModelPath;
                config.model_config.nemo_ctc.model = s_ctcModel.c_str();
                modelConfigured = true;
            } else if (type == "wenet_ctc" && !ctcModelPath.empty()) {
                LOGI("Using explicit WeNet CTC model type: %s", ctcModelPath.c_str());
                s_ctcModel = ctcModelPath;
                config.model_config.wenet_ctc.model = s_ctcModel.c_str();
                modelConfigured = true;
            } else if (type == "sense_voice" && !ctcModelPath.empty()) {
                LOGI("Using explicit SenseVoice model type: %s", ctcModelPath.c_str());
                s_ctcModel = ctcModelPath;
                s_senseVoiceLanguage = "auto";
                config.model_config.sense_voice.model = s_ctcModel.c_str();
                config.model_config.sense_voice.language = s_senseVoiceLanguage.c_str();
                config.model_config.sense_voice.use_itn = 0;
                modelConfigured = true;
            } else if (type == "funasr_nano" && hasFunAsrNano) {
                LOGI("Using explicit FunASR Nano model type");
                s_funasrEncoderAdaptor = fileExists(funasrEncoderAdaptorInt8) ? funasrEncoderAdaptorInt8 : funasrEncoderAdaptor;
                s_funasrLLM = fileExists(funasrLLMInt8) ? funasrLLMInt8 : funasrLLM;
                s_funasrEmbedding = fileExists(funasrEmbeddingInt8) ? funasrEmbeddingInt8 : funasrEmbedding;
                s_funasrTokenizer = funasrTokenizer;
                config.model_config.funasr_nano.encoder_adaptor = s_funasrEncoderAdaptor.c_str();
                config.model_config.funasr_nano.llm = s_funasrLLM.c_str();
                config.model_config.funasr_nano.embedding = s_funasrEmbedding.c_str();
                config.model_config.funasr_nano.tokenizer = s_funasrTokenizer.c_str();
                tokensRequired = false;
                modelConfigured = true;
            } else if (type == "whisper" && hasWhisper) {
                LOGI("Using explicit Whisper model type");
                s_whisperEncoder = fileExists(encoderPathInt8) ? encoderPathInt8 : encoderPath;
                s_whisperDecoder = fileExists(decoderPathInt8) ? decoderPathInt8 : decoderPath;
                config.model_config.whisper.encoder = s_whisperEncoder.c_str();
                config.model_config.whisper.decoder = s_whisperDecoder.c_str();
                config.model_config.whisper.language = "en";
                config.model_config.whisper.task = "transcribe";
                tokensRequired = true;
                if (fileExists(tokensPath)) {
                    s_tokensPath = tokensPath;
                    config.model_config.tokens = s_tokensPath.c_str();
                    LOGI("Using tokens file for Whisper: %s", tokensPath.c_str());
                } else {
                    LOGE("Tokens file not found for Whisper model: %s", tokensPath.c_str());
                    return false;
                }
                modelConfigured = true;
            } else {
                LOGE("Explicit model type '%s' specified but required files not found", type.c_str());
                return false;
            }
        }
        
        // Auto-detect if no explicit type
        if (!modelConfigured) {
            if (hasTransducer) {
                LOGI("Auto-detected Transducer model");
                s_encoderPath = encoderPath;
                s_decoderPath = decoderPath;
                s_joinerPath = joinerPath;
                config.model_config.transducer.encoder = s_encoderPath.c_str();
                config.model_config.transducer.decoder = s_decoderPath.c_str();
                config.model_config.transducer.joiner = s_joinerPath.c_str();
                modelConfigured = true;
            } else if (hasFunAsrNano && isLikelyFunAsrNano) {
                s_funasrEncoderAdaptor = fileExists(funasrEncoderAdaptorInt8) ? funasrEncoderAdaptorInt8 : funasrEncoderAdaptor;
                s_funasrLLM = fileExists(funasrLLMInt8) ? funasrLLMInt8 : funasrLLM;
                s_funasrEmbedding = fileExists(funasrEmbeddingInt8) ? funasrEmbeddingInt8 : funasrEmbedding;
                s_funasrTokenizer = funasrTokenizer;
                LOGI("Auto-detected FunASR Nano model");
                config.model_config.funasr_nano.encoder_adaptor = s_funasrEncoderAdaptor.c_str();
                config.model_config.funasr_nano.llm = s_funasrLLM.c_str();
                config.model_config.funasr_nano.embedding = s_funasrEmbedding.c_str();
                config.model_config.funasr_nano.tokenizer = s_funasrTokenizer.c_str();
                tokensRequired = false;
                modelConfigured = true;
            } else if (hasWhisper && isLikelyWhisper) {
                s_whisperEncoder = fileExists(encoderPathInt8) ? encoderPathInt8 : encoderPath;
                s_whisperDecoder = fileExists(decoderPathInt8) ? decoderPathInt8 : decoderPath;
                LOGI("Auto-detected Whisper model");
                config.model_config.whisper.encoder = s_whisperEncoder.c_str();
                config.model_config.whisper.decoder = s_whisperDecoder.c_str();
                config.model_config.whisper.language = "en";
                config.model_config.whisper.task = "transcribe";
                tokensRequired = true;
                if (fileExists(tokensPath)) {
                    s_tokensPath = tokensPath;
                    config.model_config.tokens = s_tokensPath.c_str();
                    LOGI("Using tokens file for Whisper: %s", tokensPath.c_str());
                } else {
                    LOGE("Tokens file not found for Whisper model: %s", tokensPath.c_str());
                    return false;
                }
                modelConfigured = true;
            } else if (!ctcModelPath.empty() && isLikelySenseVoice) {
                LOGI("Auto-detected SenseVoice model: %s", ctcModelPath.c_str());
                s_ctcModel = ctcModelPath;
                s_senseVoiceLanguage = "auto";
                config.model_config.sense_voice.model = s_ctcModel.c_str();
                config.model_config.sense_voice.language = s_senseVoiceLanguage.c_str();
                config.model_config.sense_voice.use_itn = 0;
                modelConfigured = true;
            } else if (!ctcModelPath.empty() && isLikelyWenetCtc) {
                LOGI("Auto-detected WeNet CTC model: %s", ctcModelPath.c_str());
                s_ctcModel = ctcModelPath;
                config.model_config.wenet_ctc.model = s_ctcModel.c_str();
                modelConfigured = true;
            } else if (!ctcModelPath.empty() && isLikelyNemoCtc) {
                LOGI("Auto-detected NeMo CTC model: %s", ctcModelPath.c_str());
                s_ctcModel = ctcModelPath;
                config.model_config.nemo_ctc.model = s_ctcModel.c_str();
                modelConfigured = true;
            } else if (!paraformerModelPath.empty()) {
                LOGI("Auto-detected Paraformer model: %s", paraformerModelPath.c_str());
                s_paraformerModel = paraformerModelPath;
                config.model_config.paraformer.model = s_paraformerModel.c_str();
                modelConfigured = true;
            } else if (!ctcModelPath.empty()) {
                // Fallback: try as CTC model
                LOGI("Auto-detected CTC model (fallback): %s", ctcModelPath.c_str());
                s_ctcModel = ctcModelPath;
                config.model_config.nemo_ctc.model = s_ctcModel.c_str();
                modelConfigured = true;
            }
        }
        
        if (tokensRequired) {
            if (!fileExists(tokensPath)) {
                LOGE("Tokens file not found: %s", tokensPath.c_str());
                return false;
            }
            s_tokensPath = tokensPath;
            config.model_config.tokens = s_tokensPath.c_str();
            LOGI("Using tokens file: %s", tokensPath.c_str());
        } else if (modelConfigured && fileExists(tokensPath)) {
            s_tokensPath = tokensPath;
            config.model_config.tokens = s_tokensPath.c_str();
            LOGI("Using tokens file (optional): %s", tokensPath.c_str());
        }
        
        if (!modelConfigured) {
            LOGE("No valid model files found in directory: %s", modelDir.c_str());
            return false;
        }

        // Set remaining config
        config.decoding_method = "greedy_search";
        config.model_config.num_threads = 4;
        config.model_config.provider = "cpu";
        config.model_config.debug = 0;

        // Create the recognizer using C API
        const SherpaOnnxOfflineRecognizer* recognizer = SherpaOnnxCreateOfflineRecognizer(&config);
        if (recognizer == nullptr) {
            LOGE("Failed to create OfflineRecognizer: SherpaOnnxCreateOfflineRecognizer returned NULL");
            return false;
        }
        
        pImpl->recognizer = recognizer;
        pImpl->modelDir = modelDir;
        pImpl->initialized = true;
        LOGI("OfflineRecognizer created successfully using C API");
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
    if (!pImpl->initialized || pImpl->recognizer == nullptr) {
        LOGE("Not initialized. Call initialize() first.");
        return "";
    }

    try {
        if (!fs::exists(filePath)) {
            LOGE("Audio file does not exist: %s", filePath.c_str());
            return "";
        }

        // Read the wave file using C API
        const SherpaOnnxWave* wave = SherpaOnnxReadWave(filePath.c_str());
        if (wave == nullptr) {
            LOGE("Failed to read wave file: %s", filePath.c_str());
            return "";
        }
        
        if (wave->num_samples == 0) {
            LOGE("Wave file is empty: %s", filePath.c_str());
            SherpaOnnxFreeWave(wave);
            return "";
        }

        // Create a stream
        const SherpaOnnxOfflineStream* stream = SherpaOnnxCreateOfflineStream(pImpl->recognizer);
        if (stream == nullptr) {
            LOGE("Failed to create offline stream");
            SherpaOnnxFreeWave(wave);
            return "";
        }

        // Accept waveform
        SherpaOnnxAcceptWaveformOffline(stream, wave->sample_rate, wave->samples, wave->num_samples);
        
        // Decode
        SherpaOnnxDecodeOfflineStream(pImpl->recognizer, stream);
        
        // Get result
        const SherpaOnnxOfflineRecognizerResult* result = SherpaOnnxGetOfflineStreamResult(stream);
        
        std::string text;
        if (result != nullptr && result->text != nullptr) {
            text = result->text;
        }
        
        // Cleanup
        if (result != nullptr) {
            SherpaOnnxDestroyOfflineRecognizerResult(result);
        }
        SherpaOnnxDestroyOfflineStream(stream);
        SherpaOnnxFreeWave(wave);

        return text;
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
        if (pImpl->recognizer != nullptr) {
            SherpaOnnxDestroyOfflineRecognizer(pImpl->recognizer);
            pImpl->recognizer = nullptr;
        }
        pImpl->initialized = false;
        pImpl->modelDir.clear();
        LOGI("Resources released");
    }
}

} // namespace sherpaonnxstt
