{ ... }:

{
  disko.devices = {
    disk = {
      main = {
        device = "/dev/disk/by-id/ata-Samsung_SSD_870_EVO_2TB_S6PNNL0T700533X";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];  # override existing partition
                subvolumes = {
                  "@" = {
                    mountpoint = "/";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = [ "compress=zstd" ];
                  };
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "@snapshots" = {
                    mountpoint = "/.snapshots";
                    mountOptions = [ "compress=zstd" ];
                  };
                  # Minecraft servers
                  "@minecraft_121_vanilla" = {
                    mountpoint = "/srv/minecraft/121_vanilla";
                    mountOptions = [ "compress=zstd" ];
                  };
                  # ARK Survival Ascended servers
                  "@asa_island" = {
                    mountpoint = "/srv/ark/island";
                    mountOptions = [ "compress=zstd" ];
                  };
                  "@asa_scorched" = {
                    mountpoint = "/srv/ark/scorched";
                    mountOptions = [ "compress=zstd" ];
                  };
                  "@asa_aberration" = {
                    mountpoint = "/srv/ark/aberration";
                    mountOptions = [ "compress=zstd" ];
                  };
                  "@asa_cluster" = {
                    mountpoint = "/srv/ark/cluster";
                    mountOptions = [ "compress=zstd" ];
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
