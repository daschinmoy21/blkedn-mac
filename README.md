# blkedn-mac

macOS (home-manager) mirror of my NixOS config, **[blkedn](https://github.com/daschinmoy21/blkedn)**.
blkedn is the source of truth. This repo copies nothing from it: `flake.nix` takes blkedn as an input and
`home.nix` imports its modules straight from the input.

Mirrored today:

- **Neovim (nvf)**: `rice/nvf.nix`, including the LSPs nvf installs for its enabled languages.
- **Fish + CLI tools**: `apps/fish.nix` and `apps/tui.nix` (fzf, zoxide, eza, fd, bat, bottom, numbat, lazygit).

Helix and the Linux desktop stuff are left out.
It also reuses blkedn's pinned nixpkgs, home-manager and nvf, so the Mac gets the same nvim and plugin versions.

The only differences from blkedn live in the "macOS overrides" block of `home.nix`:
Wayland/X11 clipboard providers are turned off (nvim uses `pbcopy`), `wl-clipboard` is stubbed out,
and the fish aliases (`build`, `update`, ...) run `home-manager` instead of `nh os switch`.

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
nix run home-manager/master -- switch --flake .#mac -b backup
```

- `git` comes with the Xcode command line tools; macOS offers to install them on first use.
- The username defaults to `daschinmoy` (see `home.nix`). On another Mac, change it there, or add `--impure` to read `$USER`.
- `-b backup` renames any existing conflicting dotfile (e.g. `~/.config/nvim`) to `*.backup` instead of failing.
- The first run downloads and builds a lot; later runs are fast.
- If it warns about untrusted substituters, add your user to `trusted-users` in `/etc/nix/nix.conf` (or ignore it; it just builds more locally).

**4. Use it.** Open a new terminal and run `nvim`. Run `fish` to try the shell. From now on `home-manager` is on your PATH:

```sh
home-manager switch --flake ~/blkedn-mac#mac
```

### Making fish your shell (optional)

The Mac keeps zsh as the login shell. Either just type `fish`, or make it the default:

```sh
echo ~/.nix-profile/bin/fish | sudo tee -a /etc/shells
chsh -s ~/.nix-profile/bin/fish
```

Nix is already on fish's PATH: `home.nix` sources the Nix installer's fish profile
(`/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish`), because the installer only sets up zsh and bash.
So `nix` and `home-manager` work after `chsh` with no manual step. Check with `fish -c 'which nix home-manager'`.
If you switch to fish before the next `home-manager switch`, run this once in fish to fix it by hand:

```fish
fish_add_path /nix/var/nix/profiles/default/bin ~/.nix-profile/bin
```

`eza` is configured with icons, so use a [Nerd Font](https://www.nerdfonts.com/) in your terminal
(`brew install --cask font-iosevka-nerd-font`, or any Nerd Font).

## Staying in sync with blkedn

```sh
cd ~/blkedn-mac
git pull
nix flake update blkedn
home-manager switch --flake .#mac
```

If you change blkedn's nvim config, push blkedn first, then run the above.

## Adding more later

Import more modules from `"${inputs.blkedn}/..."` in `home.nix`. Anything that pulls in Linux-only packages
(e.g. `ghostty`, `zen-browser`) needs a mac override or a `lib.optionals
stdenv.isLinux` guard upstream in blkedn.
