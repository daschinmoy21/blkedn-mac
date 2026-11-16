# OmniWM: niri-style scrolling tiling for macOS, carrying the keybinds from
# blkedn's rice/niri/keybinds.nix. niri itself is Wayland-only, so unlike the
# rest of this repo the binds are translated here, not imported.
#
# OmniWM only loads a *complete* settings.toml and writes that file itself on
# first launch, so nothing is generated from Nix. `omniwm-apply` (run on every
# switch, or by hand) patches the binds and settings below into the file OmniWM
# wrote. The file stays writable, so OmniWM's Settings window still works;
# anything set here wins again on the next switch.
{
  lib,
  pkgs,
  ...
}: let
  # niri's Mod (Super) -> Option, niri's Alt -> Command: the same physical keys
  # on a Mac keyboard. Command as Mod would steal Cmd+1-9, Cmd+Q, Cmd+H, ...
  # from every app.
  mod = "Option";
  alt = "Command";

  workspaces = lib.range 1 9;

  # OmniWM action id -> chord. One chord per action: where niri binds both
  # arrows and HJKL (or two keys) to one action, the HJKL / letter one is kept.
  hotkeys =
    # === Numbered Workspaces === (OmniWM numbers them from 0)
    # Mod+N  focus-workspace N
    lib.listToAttrs (map (n: lib.nameValuePair "switchWorkspace.${toString (n - 1)}" "${mod}+${toString n}") workspaces)
    # Mod+Ctrl+N  move-column-to-workspace N
    // lib.listToAttrs (map (n: lib.nameValuePair "moveColumnToWorkspace.${toString (n - 1)}" "Control+${mod}+${toString n}") workspaces)
    // {
      # === Workspace Navigation ===
      "switchWorkspace.next" = "${mod}+U"; # Mod+U  focus-workspace-down
      "switchWorkspace.previous" = "${mod}+I"; # Mod+I  focus-workspace-up
      moveColumnToWorkspaceDown = "Control+${mod}+${alt}+Down Arrow"; # Mod+Ctrl+Alt+Down
      moveColumnToWorkspaceUp = "Control+${mod}+${alt}+Up Arrow"; # Mod+Ctrl+Alt+Up

      # === Focus Navigation ===  Mod+H/J/K/L
      "focus.left" = "${mod}+H";
      "focus.down" = "${mod}+J";
      "focus.up" = "${mod}+K";
      "focus.right" = "${mod}+L";

      # === Window Movement ===  Mod+Shift+H/J/K/L
      "moveColumn.left" = "${mod}+Shift+H"; # move-column-left
      "move.down" = "${mod}+Shift+J"; # move-window-down
      "move.up" = "${mod}+Shift+K"; # move-window-up
      "moveColumn.right" = "${mod}+Shift+L"; # move-column-right

      # === Column Management ===
      "move.left" = "${mod}+Left Bracket"; # Mod+[  consume-or-expel-window-left
      "move.right" = "${mod}+Right Bracket"; # Mod+]  consume-or-expel-window-right
      expelWindowFromColumn = "${mod}+Period"; # Mod+.  expel-window-from-column

      # === Monitor Navigation ===  (OmniWM cycles monitors, it has no left/right)
      focusMonitorPrevious = "Control+${mod}+H"; # Mod+Ctrl+H  focus-monitor-left
      focusMonitorNext = "Control+${mod}+L"; # Mod+Ctrl+L  focus-monitor-right

      # === Move to Monitor ===  Mod+Shift+Ctrl+H/J/K/L (moves the window, not the column)
      "moveWindowToMonitor.left" = "Control+${mod}+Shift+H";
      "moveWindowToMonitor.down" = "Control+${mod}+Shift+J";
      "moveWindowToMonitor.up" = "Control+${mod}+Shift+K";
      "moveWindowToMonitor.right" = "Control+${mod}+Shift+L";

      # === Window Management ===
      closeFocusedWindow = "${mod}+Q"; # Mod+Q  close-window
      toggleContainerFullPrimarySpan = "${mod}+${alt}+F"; # Mod+Alt+F  maximize-column
      toggleFullscreen = "${mod}+Shift+F"; # Mod+Shift+F  fullscreen-window
      toggleFocusedWindowFloating = "${mod}+W"; # Mod+W  toggle-window-floating
      raiseAllFloatingWindows = "Control+${mod}+W"; # Mod+Ctrl+W  (closest to switch-focus-between-floating-and-tiling)
      toggleColumnTabbed = "${mod}+V"; # Mod+V  toggle-column-tabbed-display

      # === Sizing & Layout ===
      cycleSizeForward = "${mod}+R"; # Mod+R  switch-preset-column-width
      cycleWindowSecondarySpanForward = "${mod}+Shift+R"; # Mod+Shift+R  switch-preset-window-height
      centerColumn = "Control+${mod}+C"; # Mod+Ctrl+C  center-column

      # === System & Overview ===
      # Not Command+X: a global hotkey there would take Cut away from every app.
      toggleOverview = "${mod}+X"; # Mod+X  toggle-overview (niri also has Mod+O)
    };
  # Already the same out of the box, so not listed above:
  #   Mod+Home/End, Mod+Ctrl+Home/End, Mod+Ctrl+F, Mod+Ctrl+R,
  #   Mod+Minus/Equal, Mod+Shift+Minus/Equal.
  # No OmniWM equivalent: move-workspace-up/down (Mod+Shift+U/I), the app
  # launchers (Mod+T, Mod+B, ...) and screenshots (macOS has Cmd+Shift+4/5).
  # Mod+Space (launcher) is Raycast on Cmd+Space, so OmniWM's command palette
  # stays on its default Control+Option+Space.

  # Mirrors rice/niri/layout.nix.
  settings = {
    general = {
      defaultLayoutType = "niri";
      updateChecksEnabled = false; # Nix owns the version
    };
    gaps.size = 9;
    borders = {
      enabled = true;
      width = 2;
      # active.color = "#cba6f7"
      color = {
        red = 203 / 255.0;
        green = 166 / 255.0;
        blue = 247 / 255.0;
        alpha = 1.0;
      };
    };
    niri = {
      centerFocusedColumn = "never";
      containerPrimarySpanPresets = [0.5 0.66667 1.0];
      defaultContainerPrimarySpan = 0.5;
      resizeStepPercent = 10; # Mod+Minus/Equal step 10% in niri
    };
  };

  overrides = pkgs.writeText "omniwm-overrides.json" (builtins.toJSON {inherit hotkeys settings;});

  applySettings =
    pkgs.writers.writePython3Bin "omniwm-apply-settings" {
      libraries = [pkgs.python3Packages.tomlkit];
      flakeIgnore = ["E501"];
    }
    (builtins.readFile ./omniwm-apply.py);

  # `omniwm-apply` with no arguments patches ~/.config/omniwm/settings.toml.
  omniwmApply = pkgs.writeShellScriptBin "omniwm-apply" ''
    exec ${applySettings}/bin/omniwm-apply-settings ${overrides} "$@"
  '';
in {
  programs.omniwm.enable = true;

  home.packages = [omniwmApply];

  # OmniWM reloads settings.toml when it changes, so this takes effect live.
  # Never fails the switch: a bad patch is reported and the file left alone.
  home.activation.omniwmApply = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run ${omniwmApply}/bin/omniwm-apply || echo "omniwm-apply failed; settings.toml left unchanged" >&2
  '';
}
