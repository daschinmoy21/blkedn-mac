# blkedn-mac

macOS (home-manager) mirror of my NixOS config, **[blkedn](https://github.com/daschinmoy21/blkedn)**.
blkedn is the source of truth. This repo copies nothing from it: `flake.nix` takes blkedn as an input and
`home.nix` imports its modules straight from the input.

Mirrored today:

- **Neovim (nvf)**: `rice/nvf.nix`, including the LSPs nvf installs for its enabled languages.
- **Fish + CLI tools**: `apps/fish.nix` and `apps/tui.nix` (fzf, zoxide, eza, fd, bat, bottom, numbat, lazygit).
- **claude-code**: from the `llm-agents` flake, pinned to the same version as blkedn.
- **Window manager**: niri can't run on macOS, so [OmniWM](https://github.com/OmniNull/OmniWM) (niri-style scrolling
  columns) stands in, with the keybinds from `rice/niri/keybinds.nix` translated in `omniwm.nix`.
  See [Window manager](#window-manager-omniwm).

Helix and the Linux desktop stuff are left out.
It also reuses blkedn's pinned nixpkgs, home-manager and nvf, so the Mac gets the same nvim and plugin versions.

The differences from blkedn live in the "macOS overrides" block of `home.nix`:
Wayland/X11 clipboard providers are turned off (nvim uses `pbcopy`), `wl-clipboard` is stubbed out,
and the fish aliases (`build`, `update`, ...) run `home-manager` instead of `nh os switch`.
`omniwm.nix` is the one module written here instead of imported.

## First time on the Mac

Starting from a new Mac? Do these in order (Apple Silicon, macOS 26 or later for the window manager).
Home-manager needs no separate install: step 4 runs it straight from GitHub, and it then manages itself.

Already set up and just want the latest? Skip to [Staying in sync with blkedn](#staying-in-sync-with-blkedn),
then do step 6 if OmniWM is new to that Mac.

**1. Install Nix** (skip if `nix --version` already works). The official installer, from <https://nixos.org/download/>:

```sh
sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install)
```

It asks for your password (it creates the `/nix` volume) and takes a few minutes.

**2. Check Nix works** (open a new terminal first so it's on your PATH):

```sh
nix --version
```

If `nix` is not found, run `. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh` or restart the terminal.

**3. Enable flakes** (not on by default with the official installer; the Determinate installer already has it):

```sh
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

**4. Clone and apply** (Apple Silicon only; nixpkgs 26.11 dropped Intel Macs):

```sh
git clone https://github.com/daschinmoy21/blkedn-mac ~/blkedn-mac && cd ~/blkedn-mac
nix run home-manager/master -- switch --flake .#mac -b backup
```

- `git` comes with the Xcode command line tools; macOS offers to install them on first use.
- The username defaults to `daschinmoy` (see `home.nix`). On another Mac, change it there, or add `--impure` to read `$USER`.
- `-b backup` renames any existing conflicting dotfile (e.g. `~/.config/nvim`) to `*.backup` instead of failing.
- The first run downloads and builds a lot; later runs are fast.
- If it warns about untrusted substituters, add your user to `trusted-users` in `/etc/nix/nix.conf` (or ignore it; it just builds more locally).
- OmniWM (the window manager) opens a permissions window at the end of this step. That is step 6; it can wait.

**5. Use it.** Open a new terminal and run `nvim`. Run `fish` to try the shell. From now on `home-manager` is on your PATH:

```sh
home-manager switch --flake ~/blkedn-mac#mac
```

Inside fish that command is just `build` (and `update` also bumps the flake inputs). Those are fish aliases, so they
don't exist in zsh.

**6. Set up the window manager.** In the window OmniWM opened, grant **Accessibility** and **Input Monitoring**,
click **Start OmniWM**, then apply the niri keybinds once:

```sh
omniwm-apply
```

`Option+1-9` now switches workspaces. Details, the full keybind table and troubleshooting are under
[Window manager](#window-manager-omniwm).

**7. Launcher (optional).** Raycast on `Cmd+Space` is not installed by this repo. Install it yourself, and free the
chord first in System Settings > Keyboard > Keyboard Shortcuts > Spotlight.

### Making fish your shell (optional)

The Mac keeps zsh as the login shell. Either just type `fish`, or make it the default:

```sh
echo ~/.nix-profile/bin/fish | sudo tee -a /etc/shells
chsh -s ~/.nix-profile/bin/fish
```

Nix is already on fish's PATH: `home.nix` sources the Nix installer's fish profile and adds your Nix profile
(`~/.nix-profile/bin`) to PATH, because the installer only sets up zsh and bash. Without this, a fish login shell
shows `fzf was not found in path` and `Unknown command: zoxide`.

If you see those errors, you switched to fish before this config was applied. From fish, one time:

```fish
fish_add_path ~/.nix-profile/bin /nix/var/nix/profiles/default/bin
cd ~/blkedn-mac; git pull; nix flake update blkedn; home-manager switch --flake .#mac
```

Then open a new terminal tab. Check with `fish -c 'which nix home-manager fzf zoxide'`.
To get back to zsh meanwhile: `chsh -s /bin/zsh`.

`eza` is configured with icons, so use a [Nerd Font](https://www.nerdfonts.com/) in your terminal
(`brew install --cask font-iosevka-nerd-font`, or any Nerd Font).

### Adding something to PATH (or other fish config)

Don't append to `~/.config/fish/config.fish`: Nix owns it (read-only link into the store), so `>>` and even
`sudo` fail with "permission denied", and fish doesn't understand bash's `export PATH=...` anyway.
Edit `home.sessionPath` in `home.nix` instead (it already has `~/.local/bin` and `~/.npm-global/bin`, same as blkedn),
then `home-manager switch --flake .#mac`. It also covers `~/.cargo/bin`, `~/.bun/bin` and `~/go/bin`, so installers
that drop binaries there just work (their attempt to edit `config.fish` fails harmlessly).

Anything machine-local: put it in `~/.config/fish/local.fish`. It's loaded if present, and it's a normal writable file.
One-off in the current session: `fish_add_path ~/some/dir`.

Installing tools: `nix run nixpkgs#<tool>` to try one, `nix shell nixpkgs#<tool>` for a throwaway shell, or add it to
`home.packages` in `home.nix` to keep it.

## Window manager (OmniWM)

`omniwm.nix` installs OmniWM, starts it at login (launchd) and applies the niri keybinds and layout settings.
Needs macOS 26+ on Apple Silicon.

niri's `Mod` (Super) is **Option** and niri's `Alt` is **Command**: the same physical keys on a Mac keyboard.
Both are one-line variables at the top of `omniwm.nix`.

### First run

1. `home-manager switch --flake ~/blkedn-mac#mac` (`build` in fish). OmniWM launches.
   If its window doesn't appear, restart the agent with
   `launchctl kickstart -k gui/$(id -u)/org.nix-community.home.omniwm` and check `/tmp/omniwm.err.log`.
2. Grant **Accessibility** and **Input Monitoring** in the window it opens, then click **Start OmniWM**.
   `Displays have separate Spaces` must be on (System Settings > Desktop & Dock > Mission Control; it is by default).
3. Run `omniwm-apply` once. OmniWM writes its settings file on first launch, so the first `build` had nothing
   to patch yet. Every later `build` applies the binds by itself.

If macOS asks about a background item from "org.nix-community.home.omniwm", allow it: that is the login agent.

### Keybinds

| niri | Mac | Action |
|------|-----|--------|
| `Mod+1-9` | `Option+1-9` | switch to workspace |
| `Mod+Ctrl+1-9` | `Ctrl+Option+1-9` | move column to workspace |
| `Mod+U` / `Mod+I` | `Option+U` / `Option+I` | workspace down / up |
| `Mod+Ctrl+Alt+Down/Up` | `Ctrl+Option+Cmd+Down/Up` | move column to workspace down / up |
| `Mod+H/J/K/L` | `Option+H/J/K/L` | focus column left / window down / window up / column right |
| `Mod+Shift+H/L` | `Option+Shift+H/L` | move column left / right |
| `Mod+Shift+J/K` | `Option+Shift+J/K` | move window down / up |
| `Mod+[` / `Mod+]` | `Option+[` / `Option+]` | consume or expel window left / right |
| `Mod+.` | `Option+.` | expel window from column |
| `Mod+Home/End` | `Option+Home/End` | focus first / last column |
| `Mod+Ctrl+Home/End` | `Ctrl+Option+Home/End` | move column to first / last |
| `Mod+Ctrl+H/L` | `Ctrl+Option+H/L` | focus previous / next monitor |
| `Mod+Shift+Ctrl+H/J/K/L` | `Ctrl+Option+Shift+H/J/K/L` | move window to monitor |
| `Mod+Q` | `Option+Q` | close window |
| `Mod+Alt+F` | `Option+Cmd+F` | maximize column |
| `Mod+Shift+F` | `Option+Shift+F` | fullscreen |
| `Mod+Ctrl+F` | `Ctrl+Option+F` | expand column to available width |
| `Mod+W` | `Option+W` | toggle floating |
| `Mod+V` | `Option+V` | toggle tabbed column |
| `Mod+R` / `Mod+Shift+R` | `Option+R` / `Option+Shift+R` | cycle preset column width / window height |
| `Mod+Ctrl+R` | `Ctrl+Option+R` | reset window height |
| `Mod+Ctrl+C` | `Ctrl+Option+C` | center column |
| `Mod+-` / `Mod+=` | `Option+-` / `Option+=` | column width -/+ 10% |
| `Mod+Shift+-` / `Mod+Shift+=` | `Option+Shift+-` / `Option+Shift+=` | window height -/+ 10% |
| `Mod+X` | `Option+X` | overview |
| `Mod+Space` | `Cmd+Space` | launcher (Raycast, set up outside this repo) |

What does not carry over:

- OmniWM allows one chord per action, so the arrow-key and `Mod+O` duplicates are dropped (HJKL and `Mod+X` kept).
  Overview is `Option+X`, not `Cmd+X`: a global hotkey on `Cmd+X` would take Cut away from every app.
  That also leaves `Option+Arrow` to macOS for word-by-word cursor movement.
- No equivalent for reordering workspaces (`Mod+Shift+U/I`) or directional monitor focus (it cycles instead).
- App launchers (`Mod+T`, `Mod+B`, ...) and screenshots: OmniWM hotkeys can't start apps. Use Raycast,
  and `Cmd+Shift+4` / `Cmd+Shift+5` for screenshots.
- `Option+<letter>` no longer types special characters (`Option+U` was the umlaut dead key, and so on).
- OmniWM's default workspaces 6 and 7 live on the second monitor and have emoji names. Change that in its Settings.

### Changing binds or settings

Edit `omniwm.nix`, then `build`. The action ids are OmniWM's own (Settings > Hotkeys shows every action; the ids are in
`~/.config/omniwm/settings.toml`). Any other action still holding a chord you assign gets unassigned, and the previous
file is kept as `settings.toml.bak`.

OmniWM's Settings window still works, since the file stays writable. Values set in `omniwm.nix` win again on the
next `build`; everything else you change in the GUI is kept.

Troubleshooting: `launchctl list | grep omniwm` shows the agent, logs are in `/tmp/omniwm.err.log`.
If a chord does nothing, look in Settings > Hotkeys for a registration warning, then for another app holding it.

## Staying in sync with blkedn

```sh
cd ~/blkedn-mac
git pull
nix flake update blkedn
home-manager switch --flake .#mac
```

If you change blkedn's nvim config, push blkedn first, then run the above.
The niri keybinds are the exception: change one in blkedn and mirror it by hand in `omniwm.nix`.

## Adding more later

Import more modules from `"${inputs.blkedn}/..."` in `home.nix`. Anything that pulls in Linux-only packages
(e.g. `ghostty`, `zen-browser`) needs a mac override or a `lib.optionals
stdenv.isLinux` guard upstream in blkedn.
