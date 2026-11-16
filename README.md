# blkedn-mac

macOS (home-manager) mirror of my NixOS config, **[blkedn](https://github.com/daschinmoy21/blkedn)**.
blkedn is the source of truth. This repo copies nothing from it: `flake.nix` takes blkedn as an input and
`home.nix` imports its modules straight from the input.

Mirrored today: **Neovim (nvf)** only (`rice/nvf.nix`). Helix and the Linux desktop stuff are left out.
It also reuses blkedn's pinned nixpkgs, home-manager and nvf, so the Mac gets the same nvim and plugin versions.

The only differences from blkedn live in the "macOS overrides" block of `home.nix` (Wayland/X11 clipboard
providers are turned off; nvim uses `pbcopy` on macOS).

## First time on the Mac

Starting from a fresh Nix install? Do these in order. Home-manager needs no separate install:
step 3 runs it straight from GitHub, and it then manages itself.

**1. Check Nix works** (open a new terminal first so it's on your PATH):

```sh
nix --version
```

If `nix` is not found, run `. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh` or restart the terminal.

**2. Enable flakes** (not on by default with the official installer; the Determinate installer already has it):

```sh
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

**3. Clone and apply** (Apple Silicon only; nixpkgs 26.11 dropped Intel Macs):

```sh
git clone https://github.com/daschinmoy21/blkedn-mac ~/blkedn-mac && cd ~/blkedn-mac
nix run home-manager/master -- switch --flake .#mac --impure -b backup
```

- `git` comes with the Xcode command line tools; macOS offers to install them on first use.
- `--impure` is only there so the Mac username is read from `$USER`.
- `-b backup` renames any existing conflicting dotfile (e.g. `~/.config/nvim`) to `*.backup` instead of failing.
- The first run downloads and builds a lot; later runs are fast.
- If it warns about untrusted substituters, add your user to `trusted-users` in `/etc/nix/nix.conf` (or ignore it; it just builds more locally).

**4. Use it.** Open a new terminal and run `nvim`. From now on `home-manager` is on your PATH:

```sh
home-manager switch --flake ~/blkedn-mac#mac --impure
```

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
