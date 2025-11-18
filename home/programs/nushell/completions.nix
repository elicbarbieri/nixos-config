{ pkgs, ... }:

let
  # Auto-generate completions at build time
  generatedCompletions = {
    uv = pkgs.runCommand "uv-completion.nu" {} ''
      ${pkgs.uv}/bin/uv generate-shell-completion nushell > $out
    '';
    
    ruff = pkgs.runCommand "ruff-completion.nu" {} ''
      ${pkgs.ruff}/bin/ruff generate-shell-completion nushell > $out
    '';
    
    atuin = pkgs.runCommand "atuin-completion.nu" {} ''
      ${pkgs.atuin}/bin/atuin gen-completions --shell nushell > $out
    '';
  };
  
  # Source all generated completions
  sourceCompletions = builtins.concatStringsSep "\n" (
    builtins.map (path: "source ${path}") (builtins.attrValues generatedCompletions)
  );
  
in {
  inherit sourceCompletions;
}
