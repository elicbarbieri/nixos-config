{ pkgs }:

# Auto-generate completions at build time
{
  uv = pkgs.runCommand "uv-completion.nu" {} ''
    ${pkgs.uv}/bin/uv generate-shell-completion nushell > $out
  '';
  
  ruff = pkgs.runCommand "ruff-completion.nu" {} ''
    ${pkgs.ruff}/bin/ruff generate-shell-completion nushell > $out
  '';
  
  atuin = pkgs.runCommand "atuin-completion.nu" {} ''
    ${pkgs.atuin}/bin/atuin gen-completions --shell nushell > $out
  '';
  
  carapace = pkgs.runCommand "carapace-completion.nu" {} ''
    ${pkgs.carapace}/bin/carapace _carapace nushell > $out
  '';
}
