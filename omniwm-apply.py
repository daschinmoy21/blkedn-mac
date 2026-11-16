"""Apply declarative overrides to OmniWM's settings.toml.

OmniWM only accepts a *complete* settings file (every section, every hotkey
id), and it writes that file itself on first launch. So instead of generating
the file from Nix, this patches the one OmniWM wrote:

  * `settings` in the overrides JSON is deep-merged into the file;
  * `hotkeys` (action id -> binding) replaces the binding of those actions;
  * any *other* action still holding one of those chords is set to Unassigned.

Ids the running OmniWM version doesn't know are skipped with a warning (an
unknown id would make OmniWM reject the whole file). The file stays a normal
writable file, so OmniWM's own Settings window keeps working.

Usage: omniwm-apply-settings OVERRIDES.json [SETTINGS.toml]
"""

import json
import os
import shutil
import sys
import tempfile

import tomlkit
from tomlkit.exceptions import TOMLKitError

UNASSIGNED = "Unassigned"
MODIFIERS = ("control", "option", "shift", "command")
# OmniWM accepts both spellings of these keys; compare them as one.
KEY_ALIASES = {
    "=": "equal",
    "-": "minus",
    "[": "leftbracket",
    "]": "rightbracket",
    ";": "semicolon",
    "'": "quote",
    ",": "comma",
    ".": "period",
    "/": "slash",
    "\\": "backslash",
    "`": "grave",
}


def squash(name):
    return name.replace(" ", "").replace("-", "").lower()


def chord_key(binding, hyper):
    """Canonical (modifiers, key) for a binding string, None if unassigned."""
    parts = [p.strip() for p in binding.split("+")]
    if squash(binding) == "unassigned" or not parts[-1]:
        return None
    mods = set()
    for part in parts[:-1]:
        token = squash(part)
        mods |= hyper if token == "hyper" else {token}
    key = parts[-1].lower() if len(parts[-1]) == 1 else squash(parts[-1])
    return (frozenset(mods), KEY_ALIASES.get(key, key))


def coerce(new, old):
    """Keep the TOML type OmniWM wrote (it decodes 9 and 9.0 differently)."""
    if isinstance(old, float) and isinstance(new, int) and not isinstance(new, bool):
        return float(new)
    if isinstance(old, int) and not isinstance(old, bool) and isinstance(new, float):
        return int(new) if new.is_integer() else new
    if isinstance(old, list) and isinstance(new, list) and old:
        return [coerce(item, old[0]) for item in new]
    return new


def merge(target, overrides, path=""):
    for key, value in overrides.items():
        where = f"{path}{key}"
        if isinstance(value, dict):
            if not isinstance(target.get(key), dict):
                target[key] = {}
            merge(target[key], value, where + ".")
        else:
            target[key] = coerce(value, target.get(key))


def apply_hotkeys(doc, wanted):
    general = doc.get("general", {})
    hyper_spec = general.get("hyperKeyModifiers", "Control+Option+Shift+Command")
    hyper = {squash(p) for p in hyper_spec.split("+")} & set(MODIFIERS)

    entries = doc.get("hotkeys", [])
    by_id = {entry.get("id"): entry for entry in entries}
    notes = []
    claimed = {}
    for action, binding in wanted.items():
        entry = by_id.get(action)
        if entry is None:
            notes.append(f"skipped {action}: this OmniWM version has no such action")
            continue
        entry["binding"] = binding
        chord = chord_key(binding, hyper)
        if chord is not None:
            if chord in claimed:
                notes.append(f"{action} and {claimed[chord]} both want {binding}")
            claimed[chord] = action
    for entry in entries:
        action = entry.get("id")
        if action in wanted:
            continue
        chord = chord_key(str(entry.get("binding", UNASSIGNED)), hyper)
        if chord in claimed:
            notes.append(f"unassigned {action} ({entry['binding']} now runs {claimed[chord]})")
            entry["binding"] = UNASSIGNED
    return notes


def default_settings_path():
    base = os.environ.get("XDG_CONFIG_HOME", "")
    if not os.path.isabs(base):
        base = os.path.expanduser("~/.config")
    return os.path.join(base, "omniwm", "settings.toml")


def main(argv):
    if len(argv) not in (2, 3):
        print(__doc__.strip().splitlines()[-1], file=sys.stderr)
        return 2
    with open(argv[1], encoding="utf-8") as handle:
        overrides = json.load(handle)
    path = os.path.realpath(argv[2] if len(argv) == 3 else default_settings_path())

    if not os.path.exists(path):
        print(f"omniwm-apply: {path} does not exist yet.")
        print("  Launch OmniWM once (it writes its defaults), then run `omniwm-apply`.")
        return 0
    try:
        with open(path, encoding="utf-8") as handle:
            original = handle.read()
        # tomlkit keeps OmniWM's own layout, so only the touched lines change.
        doc = tomlkit.parse(original)
    except (TOMLKitError, UnicodeDecodeError) as error:
        print(f"omniwm-apply: {path} is not valid TOML, leaving it alone: {error}", file=sys.stderr)
        return 1

    merge(doc, overrides.get("settings", {}))
    notes = apply_hotkeys(doc, overrides.get("hotkeys", {}))
    updated = tomlkit.dumps(doc)
    if updated == original:
        print("omniwm-apply: settings already up to date.")
        return 0

    if not os.access(path, os.W_OK):
        print(f"omniwm-apply: {path} is read-only, cannot apply.", file=sys.stderr)
        return 1
    shutil.copy2(path, path + ".bak")
    directory = os.path.dirname(path)
    fd, temp = tempfile.mkstemp(dir=directory, prefix=".settings.", suffix=".toml")
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            handle.write(updated)
        os.replace(temp, path)
    except BaseException:
        if os.path.exists(temp):
            os.unlink(temp)
        raise
    for note in notes:
        print(f"omniwm-apply: {note}")
    print(f"omniwm-apply: updated {path} (previous version in settings.toml.bak).")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
