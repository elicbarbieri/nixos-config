# Minecraft Server Configuration - G-Chat Create
{ config, pkgs, lib, ... }:

let
  serverDir = "/srv/minecraft/g_chat_create";

  # mrpack4server launcher - simple modpack server runner
  mrpack4server = pkgs.fetchurl {
    url = "https://github.com/Patbox/mrpack4server/releases/download/0.5.0/mrpack4server-0.5.0.jar";
    sha256 = "sha256-6Jvar8Pw9cB+2RLLKca+q2FxZXmWB4DrfFtxKbuqxl8=";
  };

  # Modpack file path
  modpackFile = ../../assets/minecraft/g-chat-create-1.1.0.mrpack;
in
{
  # Java runtime for Minecraft
  environment.systemPackages = [ pkgs.jdk21 ];

  # Firewall
  networking.firewall.allowedTCPPorts = [ 25565 ];

  # Minecraft user
  users.users.minecraft = {
    isSystemUser = true;
    group = "minecraft";
    home = serverDir;
    createHome = true;
  };
  users.groups.minecraft = {};

  # Systemd service
  systemd.services.minecraft-g_chat_create = {
    description = "G-Chat Create Minecraft Server";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "local-fs.target" ];

    serviceConfig = {
      Type = "simple";
      User = "minecraft";
      Group = "minecraft";
      WorkingDirectory = serverDir;
      Restart = "on-failure";
      RestartSec = "30s";

      # + prefix runs as root
      ExecStartPre = "+" + pkgs.writeShellScript "minecraft-setup" ''
        # Ensure directory exists and is owned by minecraft
        mkdir -p "${serverDir}"
        chown minecraft:minecraft "${serverDir}"

        # Copy the modpack if not present
        if [ ! -f "${serverDir}/local.mrpack" ]; then
          cp "${modpackFile}" "${serverDir}/local.mrpack"
          chown minecraft:minecraft "${serverDir}/local.mrpack"
        fi

        # Copy the launcher if not present
        if [ ! -f "${serverDir}/mrpack4server.jar" ]; then
          cp "${mrpack4server}" "${serverDir}/mrpack4server.jar"
          chown minecraft:minecraft "${serverDir}/mrpack4server.jar"
        fi

        # Accept EULA
        echo "eula=true" > "${serverDir}/eula.txt"
        chown minecraft:minecraft "${serverDir}/eula.txt"
      '';

      ExecStart = "${pkgs.jdk21}/bin/java -Xms4G -Xmx8G -jar ${serverDir}/mrpack4server.jar nogui";
    };
  };
}
