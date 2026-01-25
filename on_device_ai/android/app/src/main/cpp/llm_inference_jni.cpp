#include <jni.h>
#include <string>
#include <vector>
#include <queue>
#include <memory>
#include <cstring>
#include <sstream>

// Include llama.cpp headers
#include "llama.h"
#include "ggml.h"

#define LOG_TAG "LLMInference"
// Simple logging without android/log.h
#define LOGI(...) fprintf(stdout, __VA_ARGS__); fprintf(stdout, "\n")
#define LOGE(...) fprintf(stderr, __VA_ARGS__); fprintf(stderr, "\n")
#define LOGD(...) fprintf(stdout, __VA_ARGS__); fprintf(stdout, "\n")

// Global state for model and context
struct InferenceState {
    llama_model* model = nullptr;
    llama_context* ctx = nullptr;
    bool initialized = false;
    int contextSize = 4096;
    int threads = 4;
    int gpuLayers = 0;
    std::vector<llama_token> tokens;
};

InferenceState g_state;

// JNI: Initialize LLM
extern "C"
JNIEXPORT jboolean JNICALL
Java_com_example_on_1device_1ai_services_LLMService_initializeNativeLLM(
    JNIEnv* env,
    jobject thiz,
    jstring modelPath,
    jint contextSize,
    jint threads,
    jint gpuLayers
) {
    LOGI("Initializing LLM with context size: %d, threads: %d, GPU layers: %d", 
         contextSize, threads, gpuLayers);
    
    const char* model_path_str = env->GetStringUTFChars(modelPath, nullptr);
    
    try {
        // Release previous model if any
        if (g_state.ctx != nullptr) {
            llama_free(g_state.ctx);
            g_state.ctx = nullptr;
        }
        if (g_state.model != nullptr) {
            llama_free_model(g_state.model);
            g_state.model = nullptr;
        }
        
        // Create model params
        llama_model_params model_params = llama_model_default_params();
        
        // Load model from file
        LOGI("Loading model from: %s", model_path_str);
        g_state.model = llama_load_model_from_file(model_path_str, model_params);
        
        if (g_state.model == nullptr) {
            LOGE("Failed to load model from %s", model_path_str);
            env->ReleaseStringUTFChars(modelPath, model_path_str);
            return JNI_FALSE;
        }
        
        LOGI("Model loaded successfully");
        
        // Create context params
        llama_context_params ctx_params = llama_context_default_params();
        ctx_params.n_ctx = contextSize;
        ctx_params.n_threads = threads;
        ctx_params.n_threads_batch = threads;
        
        // Create context
        g_state.ctx = llama_new_context_with_model(g_state.model, ctx_params);
        
        if (g_state.ctx == nullptr) {
            LOGE("Failed to create context");
            llama_free_model(g_state.model);
            g_state.model = nullptr;
            env->ReleaseStringUTFChars(modelPath, model_path_str);
            return JNI_FALSE;
        }
        
        g_state.contextSize = contextSize;
        g_state.threads = threads;
        g_state.gpuLayers = gpuLayers;
        g_state.initialized = true;
        g_state.tokens.clear();
        
        LOGI("LLM initialized successfully. Model vocab size: %d", llama_n_vocab(g_state.model));
        
        env->ReleaseStringUTFChars(modelPath, model_path_str);
        return JNI_TRUE;
        
    } catch (const std::exception& e) {
        LOGE("Error initializing LLM: %s", e.what());
        env->ReleaseStringUTFChars(modelPath, model_path_str);
        return JNI_FALSE;
    }
}

// JNI: Get streaming tokens
extern "C"
JNIEXPORT jobject JNICALL
Java_com_example_on_1device_1ai_services_LLMService_getStreamingTokens(
    JNIEnv* env,
    jobject thiz,
    jstring prompt,
    jint maxTokens
) {
    LOGI("Getting streaming tokens for prompt with max tokens: %d", maxTokens);
    
    if (!g_state.initialized || g_state.ctx == nullptr) {
        LOGE("LLM not initialized");
        jclass arrayListClass = env->FindClass("java/util/ArrayList");
        jmethodID arrayListConstructor = env->GetMethodID(arrayListClass, "<init>", "()V");
        return env->NewObject(arrayListClass, arrayListConstructor);
    }
    
    const char* prompt_str = env->GetStringUTFChars(prompt, nullptr);
    
    try {
        // Create ArrayList to return tokens
        jclass arrayListClass = env->FindClass("java/util/ArrayList");
        jmethodID arrayListConstructor = env->GetMethodID(arrayListClass, "<init>", "()V");
        jobject tokenList = env->NewObject(arrayListClass, arrayListConstructor);
        jmethodID addMethod = env->GetMethodID(arrayListClass, "add", "(Ljava/lang/Object;)Z");
        
        // Tokenize the prompt
        std::vector<llama_token> prompt_tokens = llama_tokenize(g_state.model, prompt_str, true);
        
        LOGI("Prompt tokenized into %zu tokens", prompt_tokens.size());
        
        int n_past = 0;
        std::vector<llama_token> embd;
        
        // Add prompt tokens to embd
        for (auto token : prompt_tokens) {
            embd.push_back(token);
        }
        
        // Generate new tokens
        int generated_tokens = 0;
        
        while (generated_tokens < maxTokens) {
            // Evaluate tokens
            if (llama_decode(g_state.ctx, llama_batch_get_one(embd.data(), (int)embd.size(), n_past, 0))) {
                LOGE("Failed to decode batch");
                break;
            }
            
            n_past += embd.size();
            embd.clear();
            
            // Get logits and sample next token
            const auto* logits = llama_get_logits_ith(g_state.ctx, -1);
            if (logits == nullptr) {
                LOGE("Failed to get logits");
                break;
            }
            
            // Simple greedy sampling
            float max_logit = logits[0];
            int max_token = 0;
            for (int i = 1; i < llama_n_vocab(g_state.model); i++) {
                if (logits[i] > max_logit) {
                    max_logit = logits[i];
                    max_token = i;
                }
            }
            
            llama_token next_token = max_token;
            
            // Stop if end of sequence
            if (next_token == llama_vocab_eot(g_state.model)) {
                LOGI("End of sequence reached");
                break;
            }
            
            // Get token string using the vocab
            char buf[256] = {0};
            int n = llama_token_to_piece(g_state.model, next_token, buf, sizeof(buf) - 1, 0, true);
            
            if (n > 0) {
                buf[n] = '\0';
                jstring tokenString = env->NewStringUTF(buf);
                env->CallBooleanMethod(tokenList, addMethod, tokenString);
                env->DeleteLocalRef(tokenString);
            }
            
            embd.push_back(next_token);
            generated_tokens++;
        }
        
        LOGI("Generated %d tokens", generated_tokens);
        
        env->ReleaseStringUTFChars(prompt, prompt_str);
        return tokenList;
        
    } catch (const std::exception& e) {
        LOGE("Error getting streaming tokens: %s", e.what());
        env->ReleaseStringUTFChars(prompt, prompt_str);
        
        // Return empty list on error
        jclass arrayListClass = env->FindClass("java/util/ArrayList");
        jmethodID arrayListConstructor = env->GetMethodID(arrayListClass, "<init>", "()V");
        return env->NewObject(arrayListClass, arrayListConstructor);
    }
}

// JNI: Get non-streaming inference
extern "C"
JNIEXPORT jstring JNICALL
Java_com_example_on_1device_1ai_services_LLMService_getNativeInference(
    JNIEnv* env,
    jobject thiz,
    jstring prompt,
    jint maxTokens
) {
    LOGI("Getting inference for prompt with max tokens: %d", maxTokens);
    
    if (!g_state.initialized || g_state.ctx == nullptr) {
        LOGE("LLM not initialized");
        return env->NewStringUTF("Error: Model not initialized");
    }
    
    const char* prompt_str = env->GetStringUTFChars(prompt, nullptr);
    
    try {
        std::string response;
        
        // Tokenize the prompt
        std::vector<llama_token> prompt_tokens = llama_tokenize(g_state.model, prompt_str, true);
        
        LOGI("Prompt tokenized into %zu tokens", prompt_tokens.size());
        
        int n_past = 0;
        std::vector<llama_token> embd;
        
        // Add prompt tokens to embd
        for (auto token : prompt_tokens) {
            embd.push_back(token);
        }
        
        // Generate response tokens
        int generated_tokens = 0;
        
        while (generated_tokens < maxTokens) {
            // Evaluate tokens
            if (llama_decode(g_state.ctx, llama_batch_get_one(embd.data(), (int)embd.size(), n_past, 0))) {
                LOGE("Failed to decode batch");
                break;
            }
            
            n_past += embd.size();
            embd.clear();
            
            // Get logits and sample next token
            const auto* logits = llama_get_logits_ith(g_state.ctx, -1);
            if (logits == nullptr) {
                LOGE("Failed to get logits");
                break;
            }
            
            // Simple greedy sampling
            float max_logit = logits[0];
            int max_token = 0;
            for (int i = 1; i < llama_n_vocab(g_state.model); i++) {
                if (logits[i] > max_logit) {
                    max_logit = logits[i];
                    max_token = i;
                }
            }
            
            llama_token next_token = max_token;
            
            // Stop if end of sequence
            if (next_token == llama_vocab_eot(g_state.model)) {
                LOGI("End of sequence reached");
                break;
            }
            
            // Get token string using the vocab
            char buf[256] = {0};
            int n = llama_token_to_piece(g_state.model, next_token, buf, sizeof(buf) - 1, 0, true);
            
            if (n > 0) {
                buf[n] = '\0';
                response += buf;
            }
            
            embd.push_back(next_token);
            generated_tokens++;
        }
        
        LOGI("Generated %d tokens", generated_tokens);
        
        env->ReleaseStringUTFChars(prompt, prompt_str);
        return env->NewStringUTF(response.c_str());
        
    } catch (const std::exception& e) {
        LOGE("Error getting inference: %s", e.what());
        env->ReleaseStringUTFChars(prompt, prompt_str);
        return env->NewStringUTF("Error: Inference failed");
    }
}

// JNI: Release model
extern "C"
JNIEXPORT void JNICALL
Java_com_example_on_1device_1ai_services_LLMService_releaseNativeLLM(
    JNIEnv* env,
    jobject thiz
) {
    LOGI("Releasing LLM resources");
    
    try {
        if (g_state.ctx != nullptr) {
            llama_free(g_state.ctx);
            g_state.ctx = nullptr;
        }
        
        if (g_state.model != nullptr) {
            llama_free_model(g_state.model);
            g_state.model = nullptr;
        }
        
        g_state.initialized = false;
        g_state.tokens.clear();
        
        LOGI("LLM resources released");
        
    } catch (const std::exception& e) {
        LOGE("Error releasing LLM: %s", e.what());
    }
}

// Load native library
jint JNI_OnLoad(JavaVM* vm, void* reserved) {
    LOGI("Loading native LLM library");
    return JNI_VERSION_1_6;
}

void JNI_OnUnload(JavaVM* vm, void* reserved) {
    LOGI("Unloading native LLM library");
}
