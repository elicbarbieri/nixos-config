# SDDM Astronaut Theme Configuration
{ pkgs, config, lib, ... }:

let
  sddm-astronaut-custom = pkgs.sddm-astronaut.override {
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
  };

in
{
  # Enable SDDM with astronaut theme
  services.displayManager.sddm = {
    enable = true;
    theme = "sddm-astronaut-theme";
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
}
