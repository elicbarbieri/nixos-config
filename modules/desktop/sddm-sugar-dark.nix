# SDDM Sugar Dark Theme Package and Configuration
{ pkgs, config, lib, ... }:

let
  # Package the Sugar Dark theme
  sddm-sugar-dark = pkgs.stdenv.mkDerivation {
    pname = "sddm-sugar-dark";
    version = "1.2";

    src = pkgs.fetchFromGitHub {
      owner = "MarianArlt";
      repo = "sddm-sugar-dark";
      rev = "v1.2";
      sha256 = "0gx0am7vq1ywaw2rm1p015x90b75ccqxnb1sz3wy8yjl27v82yhb";
    };

    dontBuild = true;

    # SCAFFOLD: Uncomment and modify postPatch to add custom status labels later
    # postPatch = ''
    #   substituteInPlace Main.qml \
    #     --replace-fail 'MouseArea {
    #         anchors.fill: backgroundImage
    #         onClicked: parent.forceActiveFocus()
    #     }
    #   }
    # }' '// Custom status labels - bottom left
    #     Column {
    #         id: statusLabels
    #         anchors.left: parent.left
    #         anchors.bottom: parent.bottom
    #         anchors.leftMargin: 20
    #         anchors.bottomMargin: 20
    #         spacing: 4
    #         z: 2
    #
    #         Text {
    #             text: sddm.hostName
    #             color: "#cccccc"
    #             font.family: config.Font
    #             font.pointSize: 10
    #         }
    #
    #         Text {
    #             color: "#00ff88"
    #             text: "● keyd active"
    #             font.family: config.Font
    #             font.pointSize: 10
    #         }
    #     }
    #
    #     MouseArea {
    #         anchors.fill: backgroundImage
    #         onClicked: parent.forceActiveFocus()
    #     }
    #   }
    # }'
    # '';

    installPhase = ''
      mkdir -p $out/share/sddm/themes/sugar-dark
      cp -r * $out/share/sddm/themes/sugar-dark/
      rm -rf $out/share/sddm/themes/sugar-dark/{Previews,*.md,AUTHORS,CREDITS,CHANGELOG.md,COPYING}
    '';
  };

  # Custom theme.conf
  themeConfig = pkgs.writeText "theme.conf" ''
    [General]

    ## Path to the wallpaper
    Background="${config.programs.ax-shell.defaultWallpaper}"

    ## Blur settings
    FullBlur="false"
    PartialBlur="false"

    ## Colors
    MainColor="#00ff88"
    AccentColor="#00ff88"
    BackgroundColor="#1e1e1e"

    ## Font settings
    Font="JetBrainsMono Nerd Font"
    FontSize="10"
    HeaderFontSize="48"

    ## Date and time
    HourFormat="HH:mm"
    DateFormat="dddd, MMMM d"

    ## Display options
    ForceHideCompletePassword="true"
    ForceLastUser="true"
    
    ## Translations (English by default)
    TranslationLogin=""
    TranslationLoginFailed=""
    TranslationPassword=""
    TranslationPrompt=""
    TranslationPowerOff=""
    TranslationReboot=""
    TranslationSuspend=""
  '';

in
{
  # Enable SDDM with our custom theme
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "sugar-dark";
    package = pkgs.kdePackages.sddm;
    extraPackages = with pkgs.kdePackages; [
      qt5compat  # Provides QtGraphicalEffects for Sugar Dark theme
    ];
  };

  # Install the theme package
  environment.systemPackages = [
    sddm-sugar-dark
    # Symlink sddm-greeter to sddm-greeter-qt6 (Qt6 SDDM uses different binary name)
    (pkgs.runCommand "sddm-greeter-symlink" {} ''
      mkdir -p $out/bin
      ln -s ${pkgs.kdePackages.sddm}/bin/sddm-greeter-qt6 $out/bin/sddm-greeter
    '')
  ];

  # Link our custom theme.conf
  environment.etc."sddm/themes/sugar-dark/theme.conf" = {
    source = themeConfig;
  };
}
