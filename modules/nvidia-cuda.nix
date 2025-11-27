# NVIDIA CUDA configuration for development
# This module provides CUDA toolkit and runtime libraries for GPU development
{ pkgs, config, lib, ... }:

{
  nixpkgs.config.cudaSupport = true;

  environment.systemPackages = with pkgs; [
    # CUDA development tools (needed for vLLM/FlashInfer JIT compilation)
    ninja
    cmake
    cudaPackages.cudatoolkit  # Provides nvcc and other CUDA tools
  ];

  # CUDA-specific libraries for nix-ld (merges with common.nix base libraries)
  programs.nix-ld.libraries = with pkgs; [
    # NVIDIA Driver libraries (required for CUDA/vLLM)
    linuxPackages.nvidia_x11

    # CUDA core runtime libraries
    cudaPackages.cuda_cudart
    cudaPackages.cuda_nvrtc
    cudaPackages.libcublas
    cudaPackages.libcufft
    cudaPackages.libcusparse
    cudaPackages.libcusolver
    cudaPackages.cudnn
    cudaPackages.nccl

    # Additional CUDA libraries for ML frameworks
    cudaPackages.libcurand
  ];

  # Session variables for CUDA development
  environment.sessionVariables = {
    # CUDA support for vLLM and other CUDA-dependent tools
    CUDA_HOME = "${pkgs.cudaPackages.cudatoolkit}";

    # Library paths for CUDA linking (needed for FlashInfer JIT compilation)
    LIBRARY_PATH = "${pkgs.cudaPackages.cudatoolkit}/lib:${pkgs.cudaPackages.cudatoolkit}/lib/stubs";

    # Triton CUDA library path (NixOS standard location for NVIDIA libs)
    TRITON_LIBCUDA_PATH = "/run/opengl-driver/lib";
  };
}
