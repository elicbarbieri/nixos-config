# PRIME render offload that also reaches Vulkan; replaces nixpkgs `prime.offload.enableOffloadCmd`
{ config, lib, pkgs, ... }:

let
  enabled = config.hardware.nvidia.prime.offload.enable;
in
{
  options.nvidiaOffload.env = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    readOnly = true;
    default = lib.optionalAttrs enabled {
      __NV_PRIME_RENDER_OFFLOAD = "1";
      __NV_PRIME_RENDER_OFFLOAD_PROVIDER = "NVIDIA-G0";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      __VK_LAYER_NV_optimus = "NVIDIA_only";
      # VK_LAYER_MESA_device_select sits above NV_optimus + re-sorts compositor GPU (iGPU) first
      NODEVICE_SELECT = "1";
    };
    description = "Environment that runs a process on the NVIDIA dGPU (empty without PRIME offload).";
  };

  config = lib.mkIf enabled {
    assertions = [{
      assertion = !config.hardware.nvidia.prime.offload.enableOffloadCmd;
      message = "nvidia-offload.nix ships its own `nvidia-offload`; drop prime.offload.enableOffloadCmd";
    }];

    environment.systemPackages = [
      (pkgs.writeShellApplication {
        name = "nvidia-offload";
        runtimeEnv = config.nvidiaOffload.env;
        text = ''exec "$@"'';
      })
    ];
  };
}
