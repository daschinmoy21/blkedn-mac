{
  inputs,
  lib,
  pkgs,
  ...
}: let
  # Needs `--impure` (see README) so one flake works for any Mac username.
  user = let u = builtins.getEnv "USER"; in
    if u == "" then "user" else u;
in {
  imports = [
    # Mirrored verbatim from the main config. Edit nvim in blkedn, not here.
    "${inputs.blkedn}/rice/nvf.nix"
  ];

  home.username = user;
  home.homeDirectory = "/Users/${user}";
  home.stateVersion = "25.05";
  programs.home-manager.enable = true;

  nixpkgs.config.allowUnfree = true;

  # --- macOS overrides: the only place this repo differs from blkedn -----------
  # blkedn's clipboard providers are Wayland/X11 tools (Linux-only packages).
  # Neovim uses pbcopy/pbpaste on macOS automatically.
  programs.nvf.settings.vim.clipboard.providers = {
    wl-copy.enable = lib.mkForce false;
    xsel.enable = lib.mkForce false;
  };
}
