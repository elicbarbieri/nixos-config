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
    # Run the greeter under Wayland. The session (Hyprland) is Wayland, so an
    # X11 greeter forced a full Xorg spin-up + X->Wayland VT handoff that left a
    # frozen greeter frame on screen for ~6s after the password was accepted. A
    # Wayland greeter makes the handoff Wayland->Wayland (no stale frame, no Xorg).
    wayland.enable = true;
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
