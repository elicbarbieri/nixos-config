# SDDM Astronaut Theme Configuration
{ pkgs, config, lib, ... }:

let
  # Custom astronaut theme with our settings and keyd status indicator
  sddm-astronaut-custom = (pkgs.sddm-astronaut.override {
    themeConfig = {
      # Font
      Font = "JetBrainsMono Nerd Font";

      # Date/Time
      HourFormat = "HH:mm";
      DateFormat = "dddd d MMMM";

      # Form
      FormPosition = "center";
      PartialBlur = "true";
      BlurMax = "48";
      Blur = "2.0";
      RoundCorners = "10";

      # Behavior
      ForceLastUser = "true";
      PasswordFocus = "true";
      HideCompletePassword = "true";
      HideLoginButton = "false";
      HideSystemButtons = "false";
      HideVirtualKeyboard = "true";
    };
  }).overrideAttrs (old: {
    # Add keyd status indicator to the theme
    postInstall = (old.postInstall or "") + ''
      chmod -R u+w $out

      # Add keyd status indicator before the MouseArea in Main.qml
      substituteInPlace $out/share/sddm/themes/sddm-astronaut-theme/Main.qml \
        --replace-fail 'MouseArea {
            anchors.fill: backgroundImage
            onClicked: parent.forceActiveFocus()
        }' '// Keyd status indicator - bottom left
        Column {
            id: statusLabels
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.leftMargin: 20
            anchors.bottomMargin: 20
            spacing: 4
            z: 2

            Text {
                text: sddm.hostName
                color: config.DateTextColor || "#ffffff"
                font.family: root.font.family
                font.pointSize: root.font.pointSize * 0.9
                opacity: 0.7
            }

            Text {
                id: keydStatus
                text: "○ keyd"
                color: "#666666"
                font.family: root.font.family
                font.pointSize: root.font.pointSize * 0.9

                Timer {
                    interval: 200
                    running: true
                    repeat: true
                    triggeredOnStart: true
                    onTriggered: {
                        var xhr = new XMLHttpRequest();
                        xhr.open("GET", "file:///run/sddm/keyd-status", false);
                        try {
                            xhr.send();
                            if (xhr.status === 200 && xhr.responseText.trim() === "active") {
                                keydStatus.text = "● keyd";
                                keydStatus.color = "#00ff88";
                            } else {
                                keydStatus.text = "○ keyd";
                                keydStatus.color = "#666666";
                            }
                        } catch (e) {
                            keydStatus.text = "○ keyd";
                            keydStatus.color = "#666666";
                        }
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: backgroundImage
            onClicked: parent.forceActiveFocus()
        }'
    '';
  });

  # Wrap SDDM to include sddm-greeter symlink (Qt6 renamed it to sddm-greeter-qt6)
  sddmPackage = pkgs.kdePackages.sddm.overrideAttrs (old: {
    buildCommand = old.buildCommand + ''
      ln -s $out/bin/sddm-greeter-qt6 $out/bin/sddm-greeter
    '';
  });

in
{
  # Enable SDDM with astronaut theme
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "sddm-astronaut-theme";
    package = sddmPackage;
    extraPackages = with pkgs.kdePackages; [
      qtmultimedia
      qtsvg
      qtvirtualkeyboard
    ];
  };

  # Install the theme package
  environment.systemPackages = [
    sddm-astronaut-custom
  ];

  # Systemd service to monitor keyd status for SDDM display
  systemd.services.sddm-keyd-status = {
    description = "Monitor keyd status for SDDM";
    wantedBy = [ "display-manager.service" ];
    before = [ "display-manager.service" ];
    serviceConfig = {
      Type = "simple";
      RuntimeDirectory = "sddm";
      RuntimeDirectoryMode = "0755";
      ExecStart = pkgs.writeShellScript "sddm-keyd-status" ''
        while true; do
          if ${pkgs.procps}/bin/pgrep -x keyd > /dev/null 2>&1; then
            echo "active" > /run/sddm/keyd-status
          else
            echo "inactive" > /run/sddm/keyd-status
          fi
          sleep 0.2
        done
      '';
      Restart = "always";
    };
  };
}
