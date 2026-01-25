# ARK: Survival Ascended Server Cluster Configuration
{ config, pkgs, lib, ... }:

let
  # =============================================================================
  # SHARED SERVER SETTINGS
  # =============================================================================
  # Settings are organized by INI file and section.
  # Only keys defined here will be managed - everything else is preserved.
  # Files must already exist (created by ARK on first run).

  # GameUserSettings.ini settings
  gameUserSettings = {
    ServerSettings = {
      # -- Difficulty --
      DifficultyOffset = 1.0;
      OverrideOfficialDifficulty = 5.0;  # Max wild dino level 150

      # -- Server Type --
      ServerPVE = "False";  # PvP mode
      ServerHardcore = "False";
      AllowThirdPersonPlayer = "True";
      ServerCrosshair = "True";
      ShowMapPlayerLocation = "True";
      ShowFloatingDamageText = "True";
      AllowHitMarkers = "True";
      EnablePvPGamma = "True";  # Allow gamma adjustment in PvP

      # -- XP & Harvesting --
      XPMultiplier = 3.0;
      HarvestAmountMultiplier = 2.0;
      HarvestHealthMultiplier = 1.0;
      ResourcesRespawnPeriodMultiplier = 0.25;

      # -- Taming --
      TamingSpeedMultiplier = 5.0;
      AllowRaidDinoFeeding = "False";

      # -- Dino Stats --
      DinoCharacterFoodDrainMultiplier = 1.0;
      DinoCharacterHealthRecoveryMultiplier = 1.0;
      DinoCharacterStaminaDrainMultiplier = 1.0;
      DinoDamageMultiplier = 1.0;
      DinoResistanceMultiplier = 1.0;

      # -- Player Stats --
      PlayerDamageMultiplier = 1.0;
      PlayerResistanceMultiplier = 1.0;
      PlayerCharacterFoodDrainMultiplier = 1.0;
      PlayerCharacterWaterDrainMultiplier = 1.0;
      PlayerCharacterHealthRecoveryMultiplier = 1.0;
      PlayerCharacterStaminaDrainMultiplier = 1.0;

      # -- Day/Night Cycle --
      DayCycleSpeedScale = 1.0;
      DayTimeSpeedScale = 1.0;
      NightTimeSpeedScale = 1.0;

      # -- Structures --
      StructureDamageMultiplier = 1.0;
      StructureResistanceMultiplier = 1.0;
      PerPlatformMaxStructuresMultiplier = 1.0;
      TheMaxStructuresInRange = 10500;
      DisableStructureDecayPvE = "True";
      OverrideStructurePlatformPrevention = "True";
      AllowIntegratedSPlusStructures = "True";

      # -- Quality of Life --
      AllowAnyoneBabyImprintCuddle = "True";
      AllowFlyerCarryPvE = "True";
      ForceAllowCaveFlyers = "True";
      PreventDiseases = "False";
      NonPermanentDiseases = "True";
      ItemStackSizeMultiplier = 5.0;

      # -- Cryopods --
      DisableCryopodFridgeRequirement = "True";
      DisableCryopodEnemyCheck = "True";
      AllowCryoFridgeOnSaddle = "True";
      EnableCryopodNerf = "False";

      # -- Cluster/Transfers --
      NoTributeDownloads = "False";
      PreventDownloadSurvivors = "False";
      PreventDownloadItems = "False";
      PreventDownloadDinos = "False";

      # -- Offline Raid Protection --
      PreventOfflinePvP = "True";       # Structures/dinos invulnerable when tribe offline
      PreventOfflinePvPInterval = 900;  # 15 min delay before ORP activates

      # -- Server Limits --
      MaxTamedDinos = 5000;
      KickIdlePlayersPeriod = 3600;
      AutoSavePeriodMinutes = 15;
    };

    "/Script/Engine.GameSession" = {
      MaxPlayers = 20;
    };
  };

  # Game.ini settings
  gameIniSettings = {
    "/Script/ShooterGame.ShooterGameMode" = {
      # -- Breeding --
      BabyImprintingStatScaleMultiplier = 2.0;
      BabyCuddleIntervalMultiplier = 0.2;
      BabyCuddleGracePeriodMultiplier = 2.0;
      BabyFoodConsumptionSpeedMultiplier = 1.0;
      EggHatchSpeedMultiplier = 5.0;
      BabyMatureSpeedMultiplier = 10.0;
      MatingIntervalMultiplier = 0.1;
      LayEggIntervalMultiplier = 0.5;
      BabyImprintAmountMultiplier = 2.0;  # More imprint % per cuddle

      # -- Harvesting --
      DinoHarvestingDamageMultiplier = 2.0;
      PlayerHarvestingDamageMultiplier = 1.0;

      # -- Loot & Crafting --
      SupplyCrateLootQualityMultiplier = 2.0;
      FishingLootQualityMultiplier = 2.0;
      CraftingSkillBonusMultiplier = 1.0;

      # -- Spoiling & Decay --
      GlobalSpoilingTimeMultiplier = 2.0;
      GlobalItemDecompositionTimeMultiplier = 2.0;
      GlobalCorpseDecompositionTimeMultiplier = 2.0;
      CropGrowthSpeedMultiplier = 2.0;
      CropDecaySpeedMultiplier = 1.0;

      # -- QoL --
      bAllowCustomRecipes = "True";
      bAllowUnlimitedRespecs = "True";
      bUseCorpseLocator = "True";
      bAllowSpeedLeveling = "True";        # Ground dino speed leveling
      bAllowFlyerSpeedLeveling = "True";   # Flyer speed (mod 937389 fixes this)
      MaxDifficulty = "True";

      # -- Player Stats Per Level --
      # Index: 0=Health 1=Stamina 2=Torpidity 3=Oxygen 4=Food 5=Water 6=Temp 7=Weight 8=Melee 9=Speed 10=Fortitude
      "PerLevelStatsMultiplier_Player[1]" = 2.0;   # Stamina
      "PerLevelStatsMultiplier_Player[7]" = 3.0;   # Weight
      "PerLevelStatsMultiplier_Player[10]" = 2.0;  # Fortitude

      # -- Dino Stat Multipliers (per level) --
      # Index: 0=Health 1=Stamina 2=Torpidity 3=Oxygen 4=Food 5=Water 6=Temp 7=Weight 8=Melee 9=Speed 10=Fortitude
      # DEFAULTS: Health=0.09, Stamina=1, Weight=1, Melee=0.07, Speed=1
      "PerLevelStatsMultiplier_DinoTamed[0]" = 0.18;   # Health (2x default)
      "PerLevelStatsMultiplier_DinoTamed[1]" = 2.0;    # Stamina (2x default)
      "PerLevelStatsMultiplier_DinoTamed[7]" = 2.0;    # Weight (2x default)
      "PerLevelStatsMultiplier_DinoTamed[8]" = 0.14;   # Melee (2x default)
      "PerLevelStatsMultiplier_DinoTamed[9]" = 3.0;    # Speed (3x default)
    };
  };

  # =============================================================================
  # PER-MAP OVERRIDES
  # =============================================================================

  mapOverrides = {
    island = { };
    scorched = { };
    aberration = {
      gameUserSettings = {
        ServerSettings = {
          ForceAllowCaveFlyers = "False";
        };
      };
    };
  };

  # =============================================================================
  # MODS & CLUSTER
  # =============================================================================
  mods = [
    "1195096" # Genetic Traits Mutator
    "1099220"  # Better Traits (No-DLC TraitScanner and Storage)
    "929420"   # Super Spyglass Plus
  ];
  modString = lib.concatStringsSep "," mods;
  clusterID = "y5YKVK4wfc4J";

  # =============================================================================
  # CONFIG SCRIPT GENERATION
  # =============================================================================

  # Deep merge settings with per-map overrides
  mergeSettings = base: override:
    lib.recursiveUpdate base override;

  getGameUserSettings = map:
    mergeSettings gameUserSettings (mapOverrides.${map}.gameUserSettings or {});

  getGameIniSettings = map:
    mergeSettings gameIniSettings (mapOverrides.${map}.gameIniSettings or {});

  # Generate crudini commands for a settings attrset
  # crudini --set FILE SECTION KEY VALUE
  mkCrudiniCommands = file: settings:
    lib.concatStringsSep "\n" (
      lib.flatten (
        lib.mapAttrsToList (section: keys:
          lib.mapAttrsToList (key: value:
            ''    ${pkgs.crudini}/bin/crudini --set "${file}" "${section}" "${key}" "${toString value}"''
          ) keys
        ) settings
      )
    );

  # Create the config sync script for a map
  mkConfigScript = map:
    let
      configDir = "/srv/ark/${map}/ShooterGame/Saved/Config/WindowsServer";
      gameUserSettingsFile = "${configDir}/GameUserSettings.ini";
      gameIniFile = "${configDir}/Game.ini";
    in pkgs.writeShellScript "ark-${map}-config-sync" ''
      set -euo pipefail

      echo "=== ARK Config Sync: ${map} ==="

      # GameUserSettings.ini must exist (created by ARK on first run)
      if [[ ! -f "${gameUserSettingsFile}" ]]; then
        echo "WARNING: ${gameUserSettingsFile} does not exist."
        echo "ARK needs to run once to create default configs."
        echo "Skipping config sync - server will start with defaults."
        exit 0
      fi

      # Game.ini is NOT auto-created by ASA - create it with proper header if missing
      if [[ ! -f "${gameIniFile}" ]]; then
        echo "Creating ${gameIniFile} (ASA does not auto-create this file)..."
        echo "[/script/shootergame.shootergamemode]" > "${gameIniFile}"
      fi

      echo "Applying managed settings to GameUserSettings.ini..."
${mkCrudiniCommands gameUserSettingsFile (getGameUserSettings map)}

      echo "Applying managed settings to Game.ini..."
${mkCrudiniCommands gameIniFile (getGameIniSettings map)}

      echo "Config sync complete for ${map}"
    '';

  # =============================================================================
  # CONTAINER DEFINITION
  # =============================================================================

  mkArkServer = { map }: {
    image = "mschnitzer/asa-linux-server:latest";
    autoStart = true;
    entrypoint = "/usr/bin/start_server";
    user = "gameserver";
    volumes = [
      "/srv/ark/${map}:/home/gameserver/server-files:rw"
      "/srv/ark/steam/${map}/steam:/home/gameserver/Steam:rw"
      "/srv/ark/steam/${map}/steamcmd:/home/gameserver/steamcmd:rw"
      "/srv/ark/cluster:/home/gameserver/cluster-shared:rw"
      "/etc/localtime:/etc/localtime:ro"
    ];
    environmentFiles = [ config.sops.templates."ark-${map}.env".path ];
    extraOptions = [ "--memory=14g" "--cpus=4" "--tty" "--network=host" ];
  };

  maps = [ "island" "scorched" "aberration" ];

in
{
  # ===========================================================================
  # SOPS TEMPLATES
  # ===========================================================================

  # With host networking, each server needs unique ports
  # Island: 7777 (game) + 7778 (query auto), RCON 27020
  # Scorched: 7779 (game) + 7780 (query auto), RCON 27021
  # Aberration: 7781 (game) + 7782 (query auto), RCON 27022
  sops.templates."ark-island.env".content = ''
    ASA_START_PARAMS=TheIsland_WP?listen?SessionName=NA-G-Chat-Island?Port=7777?RCONPort=27020?RCONEnabled=True?ServerPassword=${config.sops.placeholder."ark/server-password"}?ServerAdminPassword=${config.sops.placeholder."ark/admin-password"} -WinLiveMaxPlayers=20 -clusterid=${clusterID} -ClusterDirOverride="/home/gameserver/cluster-shared" -NoTransferFromFiltering -NoBattlEye -AllowFlyerSpeedLeveling -mods=${modString}
  '';
  sops.templates."ark-scorched.env".content = ''
    ASA_START_PARAMS=ScorchedEarth_WP?listen?SessionName=NA-G-Chat-Scorched?Port=7779?RCONPort=27021?RCONEnabled=True?ServerPassword=${config.sops.placeholder."ark/server-password"}?ServerAdminPassword=${config.sops.placeholder."ark/admin-password"} -WinLiveMaxPlayers=20 -clusterid=${clusterID} -ClusterDirOverride="/home/gameserver/cluster-shared" -NoTransferFromFiltering -NoBattlEye -AllowFlyerSpeedLeveling -mods=${modString}
  '';
  sops.templates."ark-aberration.env".content = ''
    ASA_START_PARAMS=Aberration_WP?listen?SessionName=NA-G-Chat-Aberration?Port=7781?RCONPort=27022?RCONEnabled=True?ServerPassword=${config.sops.placeholder."ark/server-password"}?ServerAdminPassword=${config.sops.placeholder."ark/admin-password"} -WinLiveMaxPlayers=20 -clusterid=${clusterID} -ClusterDirOverride="/home/gameserver/cluster-shared" -NoTransferFromFiltering -NoBattlEye -AllowFlyerSpeedLeveling -mods=${modString}
  '';

  # ===========================================================================
  # CONFIG SYNC SERVICES
  # ===========================================================================
  # These run before each container starts, applying only our managed settings.
  # If config files don't exist yet, they exit gracefully and let ARK create them.

  systemd.services = lib.listToAttrs (map (mapName: {
    name = "ark-${mapName}-config";
    value = {
      description = "Sync ARK ${mapName} server configuration";
      wantedBy = [ "docker-ark-${mapName}.service" ];
      before = [ "docker-ark-${mapName}.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = mkConfigScript mapName;
      };
    };
  }) maps);

  # ===========================================================================
  # CONTAINERS
  # ===========================================================================

  virtualisation.oci-containers.containers = {
    ark-island = mkArkServer { map = "island"; };
    ark-scorched = mkArkServer { map = "scorched"; };
    ark-aberration = mkArkServer { map = "aberration"; };
  };
}
