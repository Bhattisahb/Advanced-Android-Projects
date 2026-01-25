cmake_minimum_required(VERSION 3.22.1)
project(llm_inference CXX C)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Compiler warnings and optimizations
add_compile_options(-Wall -Wextra -fPIC)

# Optimization flags
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

if(CMAKE_BUILD_TYPE STREQUAL "Release")
    add_compile_options(-O3)
else()
    add_compile_options(-O2 -g)
endif()

# NEON optimization for ARM
if(ANDROID_ABI STREQUAL "arm64-v8a")
    add_compile_options(-march=armv8-a)
    add_compile_definitions(__ARM_NEON)
elseif(ANDROID_ABI STREQUAL "armeabi-v7a")
    add_compile_options(-march=armv7-a+neon)
    add_compile_definitions(__ARM_NEON)
endif()

# Source files - main llama.cpp entry point  
set(LLAMA_CPP_SOURCES
    llama.cpp/src/llama.cpp
    llama.cpp/ggml/src/ggml.c
    llama.cpp/ggml/src/ggml-alloc.c
    llama.cpp/ggml/src/ggml-backend.cpp
    llama.cpp/ggml/src/ggml-quants.c
)

# Create library
add_library(llm_inference SHARED
    llm_inference_jni.cpp
    ${LLAMA_CPP_SOURCES}
)

# Include directories
target_include_directories(llm_inference PRIVATE
    llama.cpp/include
    llama.cpp/src
    llama.cpp/ggml/include
    llama.cpp/ggml/src
)

# Link libraries - using Android NDK
target_link_libraries(llm_inference
    android
)
