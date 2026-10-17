# Minecraft servers (mrpack4server, one systemd unit per entry in `servers`)
{ config, pkgs, lib, ... }:

let
  mrpack4server = pkgs.fetchurl {
    url = "https://github.com/Patbox/mrpack4server/releases/download/0.5.0/mrpack4server-0.5.0.jar";
    sha256 = "sha256-6Jvar8Pw9cB+2RLLKca+q2FxZXmWB4DrfFtxKbuqxl8=";
  };

  players = {
    CrazedInvento = { uuid = "31a86a8f-95d9-4c14-a620-2fc0691a7a52"; op = true; };
    mallanin = { uuid = "2ed115bf-5c8c-476c-ae31-2cb3513d3fe9"; };
    RareJaimiller = { uuid = "c107d6d9-2d54-405f-a702-c0c53d5dffe1"; };
    stonkmaster3000 = { uuid = "edaee148-c36a-4e22-b31d-e0213edeae8c"; }; # Benn
    Sacajaweagle = { uuid = "196e9640-0f23-4934-ba73-4f923bba8e1b"; }; # Julia
    taintgoblin7 = { uuid = "ef563009-0c41-467c-92aa-9ef98d8367a9"; }; # Agustin
  };

  servers = {
    g_chat_create = {
      description = "G-Chat Create";
      modpack = ../../assets/minecraft/g-chat-create-1.5.0.mrpack;
      port = 25565;
      memory = { min = "4G"; max = "8G"; };
    };
    "121_rebirth" = {
      description = "Rebirth";
      modpack = ../../assets/minecraft/rebirth-1.0.0.mrpack;
      port = 25566;
      memory = { min = "4G"; max = "10G"; };
    };
  };

  whitelistJson = pkgs.writeText "whitelist.json" (builtins.toJSON
    (lib.mapAttrsToList (name: p: { inherit name; inherit (p) uuid; }) players));

  opsJson = pkgs.writeText "ops.json" (builtins.toJSON
    (lib.mapAttrsToList (name: p: {
      inherit name;
      inherit (p) uuid;
      level = 4;
      bypassesPlayerLimit = false;
    }) (lib.filterAttrs (_: p: p.op or false) players)));

  serverProperties = server: {
    white-list = true;
    enforce-whitelist = true;
    online-mode = true;
    # vanilla fly check kicks riders of Sable ships / Create contraptions (whitelist = trusted players)
    allow-flight = true;
    server-port = server.port;
  };

  mkService = name: server:
    let
      dir = "/srv/minecraft/${name}";
      setProperties = lib.concatStrings (lib.mapAttrsToList (key: value:
        let line = "${key}=${lib.generators.mkValueStringDefault { } value}"; in ''
          if grep -q '^${key}=' server.properties; then
            sed -i 's|^${key}=.*|${line}|' server.properties
          else
            echo '${line}' >> server.properties
          fi
        '') (serverProperties server));
    in
    lib.nameValuePair "minecraft-${name}" {
      description = "${server.description} Minecraft Server";
      wantedBy = [ "multi-user.target" ];
      # resetup = tmpfiles on switch (new server's subvol must exist before WorkingDirectory)
      after = [ "network.target" "local-fs.target" "systemd-tmpfiles-resetup.service" ];
      serviceConfig = {
        Type = "simple";
        User = "minecraft";
        Group = "minecraft";
        WorkingDirectory = dir;
        Restart = "on-failure";
        RestartSec = "30s";
        # 10× default share under contention (tick thread loses to plex transcodes / deluge otherwise)
        CPUWeight = 1000;
        # + = root (install -o)
        ExecStartPre = "+" + pkgs.writeShellScript "minecraft-${name}-setup" ''
          set -euo pipefail
          cd "${dir}"
          install -o minecraft -g minecraft -m 644 "${server.modpack}" local.mrpack
          install -o minecraft -g minecraft -m 644 "${mrpack4server}" mrpack4server.jar
          install -o minecraft -g minecraft -m 644 ${whitelistJson} whitelist.json
          install -o minecraft -g minecraft -m 644 ${opsJson} ops.json
          echo "eula=true" > eula.txt
          touch server.properties
          ${setProperties}
          chown minecraft:minecraft eula.txt server.properties
        '';
        ExecStart = "${pkgs.jdk21}/bin/java -Xms${server.memory.min} -Xmx${server.memory.max} -jar ${dir}/mrpack4server.jar nogui";
      };
    };
in
{
  environment.systemPackages = [ pkgs.jdk21 ];

  networking.firewall.allowedTCPPorts = lib.mapAttrsToList (_: s: s.port) servers;

  users.users.minecraft = {
    isSystemUser = true;
    group = "minecraft";
    home = "/var/lib/minecraft";
    createHome = true;
  };
  users.groups.minecraft = { };

  systemd.tmpfiles.rules = lib.mapAttrsToList (name: _: "v /srv/minecraft/${name} 0700 minecraft minecraft -") servers;

  systemd.services = lib.mapAttrs' mkService servers;
}
