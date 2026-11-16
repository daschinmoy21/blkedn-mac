# blkedn-mac

macOS (home-manager) mirror of my NixOS config, **[blkedn](https://github.com/daschinmoy21/blkedn)**.
blkedn is the source of truth. This repo copies nothing from it: `flake.nix` takes blkedn as an input and
`home.nix` imports its modules straight from the input.

Mirrored today: **Neovim (nvf)** only (`rice/nvf.nix`). Helix and the Linux desktop stuff are left out.
It also reuses blkedn's pinned nixpkgs, home-manager and nvf, so the Mac gets the same nvim and plugin versions.

The only differences from blkedn live in the "macOS overrides" block of `home.nix` (Wayland/X11 clipboard
providers are turned off; nvim uses `pbcopy` on macOS).

## First time on the Mac

```sh
git clone https://github.com/daschinmoy21/blkedn-mac ~/blkedn-mac && cd ~/blkedn-mac
nix run home-manager/master -- switch --flake .#mac --impure -b backup   # .#mac-intel on Intel Macs
```

`--impure` is only there so the Mac username is read from `$USER`.
Needs flakes enabled (`experimental-features = nix-command flakes` in `~/.config/nix/nix.conf`).

## Staying in sync with blkedn

```sh
cd ~/blkedn-mac
nix flake update blkedn          # pulls the latest blkedn commit + its pins
home-manager switch --flake .#mac --impure
```

If you change blkedn's nvim config, push blkedn first, then run the above.

## Adding more later

Import more modules from `"${inputs.blkedn}/..."` in `home.nix`. Anything that pulls in Linux-only packages
(e.g. `wl-clipboard` in `apps/tui.nix`, `ghostty`, `zen-browser`) needs a mac override or a `lib.optionals
stdenv.isLinux` guard upstream in blkedn.
