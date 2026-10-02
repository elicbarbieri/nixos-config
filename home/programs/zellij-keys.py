# zellij cheat sheet, parsed from the running config (Ctrl b ?)
import os
import re
import subprocess
import sys

import kdl


def words(name):
    return re.sub(r"(?<!^)(?=[A-Z])", " ", name).lower()


def value(arg):
    if isinstance(arg, float) and arg.is_integer():
        return str(int(arg))
    return os.path.basename(str(arg)).lower()


def is_noise(action, actions):
    # *Input = text-entry plumbing; trailing → Locked = every one-shot bind
    if action.name.endswith("Input"):
        return True
    return action.name == "SwitchToMode" and action.args == ["Locked"] and len(actions) > 1


def phrase(action):
    args = [value(a) for a in action.args]
    if action.name == "SwitchToMode":
        return "→ " + " ".join(args).upper()
    return " ".join([words(action.name), *args])


def describe(bind):
    return "; ".join(phrase(a) for a in bind.nodes if not is_noise(a, bind.nodes))


def title(block):
    if block.name.startswith("shared"):
        return block.name.replace("_", " ") + ": " + ", ".join(map(str, block.args))
    return block.name.upper()


def section(block):
    binds = [b for b in block.nodes if b.name == "bind"]
    rows = [f"  {' / '.join(map(str, b.args)):<24}{describe(b)}" for b in binds]
    return [title(block), *rows, ""]


def render(config):
    keybinds = kdl.parse(config).get("keybinds")
    if keybinds is None:
        raise ValueError("no keybinds block")
    lines = ["zellij keys · / search · q close", ""]
    for block in keybinds.nodes:
        lines += section(block)
    return "\n".join(lines)


def show(text):
    if sys.stdout.isatty():
        subprocess.run(["less"], input=text, text=True)
    else:
        print(text)


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else os.environ["ZELLIJ_CONFIG_FILE"]
    config = open(path).read()
    try:
        text = render(config)
    except Exception as error:  # any new config shape → raw config beats an empty popup
        show(f"zellij-keys: can't read keybinds ({error})\n\n{config}")
        sys.exit(1)
    show(text)


main()
