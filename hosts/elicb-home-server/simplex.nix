# SimpleX Chat CLI — private messaging without user identifiers
# Runs in a tmux session as a dedicated system user
# Access: sudo -u simplex tmux attach -t simplex
{ pkgs, ... }:
let
  simplex-chat = pkgs.callPackage ../../pkgs/simplex-chat.nix {};
in
{
  users.users.simplex = {
    isSystemUser = true;
    group = "simplex";
    home = "/var/lib/simplex";
    createHome = true;
    shell = pkgs.bash;
  };
  users.groups.simplex = {};

  systemd.services.simplex-chat = {
    description = "SimpleX Chat CLI in tmux";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "forking";
      User = "simplex";
      Group = "simplex";
      WorkingDirectory = "/var/lib/simplex";
      ExecStart = "${pkgs.tmux}/bin/tmux new-session -d -s simplex '${simplex-chat}/bin/simplex-chat -d /var/lib/simplex/data'";
      ExecStop = "${pkgs.tmux}/bin/tmux kill-session -t simplex";
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };

  environment.systemPackages = [ pkgs.tmux ];
}
