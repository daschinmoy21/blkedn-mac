{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  # Defaults to this Mac's user so a plain (pure) switch works. If your username
  # differs, change it here (or pass `--impure` to read $USER instead).
  user = let u = builtins.getEnv "USER"; in
    if u == "" then "daschinmoy" else u;
in {
  imports = [
    # Mirrored verbatim from the main config. Edit nvim in blkedn, not here.
    "${inputs.blkedn}/rice/nvf.nix"
    "${inputs.blkedn}/apps/fish.nix" # fish (vi keys); aliases overridden below
    "${inputs.blkedn}/apps/tui.nix" # fzf, zoxide, eza, fd, bat, bottom, numbat, lazygit

    # Mac-only: niri can't run here, so its keybinds are translated for OmniWM.
    ./omniwm.nix
  ];

  home.username = user;
  home.homeDirectory = "/Users/${user}";
  home.stateVersion = "25.05";
  programs.home-manager.enable = true;

  # Same as blkedn's home.nix. Put user-installed CLIs (claude, npm -g, pipx, ...) on PATH.
  # To add a dir, edit this list: ~/.config/fish/config.fish is read-only (managed by Nix).
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.npm-global/bin"
    # Mac extras: where common installers drop binaries (cargo install, bun, go install).
    "$HOME/.cargo/bin"
    "$HOME/.bun/bin"
    "$HOME/go/bin"
  ];

  nixpkgs.config.allowUnfree = true;

  # CLI agents from the same llm-agents flake blkedn uses. Add more here
  # (codex, pi, omp, ccusage, herdr are in blkedn's home.nix).
  home.packages = [
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code
  ];

  # --- macOS overrides: the only place this repo differs from blkedn -----------
  # tui.nix installs wl-clipboard (Wayland, Linux-only). Swap it for an empty
  # package here instead of editing blkedn. macOS has pbcopy/pbpaste built in.
  nixpkgs.overlays = [(final: prev: {wl-clipboard = final.emptyDirectory;})];

  # The Nix installer only wires zsh/bash into PATH, so a fish login shell starts without
  # `nix`, `home-manager`, fzf, zoxide, ... Source the installer's fish profile, then make sure
  # the profile dirs are on PATH (session-only, no-op for dirs that don't exist). This runs
  # before the fzf/zoxide integrations, which need those binaries.
  programs.fish.shellInit = lib.mkBefore ''
    if test -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
      source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
    end
    fish_add_path --path --move $HOME/.nix-profile/bin $HOME/.local/state/nix/profile/bin /nix/var/nix/profiles/default/bin
    fish_add_path --path ${lib.concatStringsSep " " config.home.sessionPath}
    # Writable escape hatch for machine-local fish config (not managed by Nix).
    test -f ~/.config/fish/local.fish; and source ~/.config/fish/local.fish
  '';

  # blkedn's aliases drive `nh os switch` (NixOS-only). Replace them with Mac equivalents.
  programs.fish.shellAliases = lib.mkForce {
    build = "home-manager switch --flake ~/blkedn-mac#mac";
    update = "nix flake update --flake ~/blkedn-mac && home-manager switch --flake ~/blkedn-mac#mac";
    scrub = "nix-collect-garbage --delete-older-than 7d";
    sweep = "nix-collect-garbage -v";
    assess = "nix-collect-garbage -v --dry-run";
  };

  # blkedn's clipboard providers are Wayland/X11 tools (Linux-only packages).
  # Neovim uses pbcopy/pbpaste on macOS automatically.
  programs.nvf.settings.vim.clipboard.providers = {
    wl-copy.enable = lib.mkForce false;
    xsel.enable = lib.mkForce false;
  };
}
