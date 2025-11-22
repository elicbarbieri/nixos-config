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
                  "@minecraft" = {
                    mountpoint = "/minecraft";
                    mountOptions = [ "compress=zstd" ];
                  };
                  "@snapshots" = {
                    mountpoint = "/.snapshots";
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
