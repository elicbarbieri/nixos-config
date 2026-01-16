{ ... }:

{
  disko.devices = {
    disk = {
      main = {
        # TODO: Replace with actual disk ID from: ls -la /dev/disk/by-id/
        # Example: nvme-Samsung_SSD_970_EVO_Plus_500GB_S4EWNX0M123456
        device = "/dev/disk/by-id/REPLACE_WITH_YOUR_DISK_ID";
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
                  "@/home" = {
                    mountpoint = "/home";
                    mountOptions = [ "compress=zstd" ];
                  };
                  "@/nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "compress=zstd" "noatime" ];
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
