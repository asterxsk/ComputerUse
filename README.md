# ComputerUse

[![license: MIT](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](./LICENSE)

A Python CLI that gives AI agents safe, structured control of a user's desktop — **Read** tools to see the screen, **Write** tools to move the mouse, type text, and run keyboard shortcuts. Destructive shortcuts always ask the user for confirmation.

<!-- Demo

Insert gif or link to demo

-->

## Installation

### Windows — one-liner (recommended)

```powershell
irm https://raw.githubusercontent.com/asterxsk/ComputerUse/main/install.ps1 | iex
```

This will:

1. Verify Python 3.9+ (offers winget install if missing).
2. Resolve the **latest GitHub release** of `asterxsk/ComputerUse` and download that release's source zipball (falls back to the `main` branch if no release has been published yet).
3. Extract into `%LOCALAPPDATA%\ComputerUse`.
4. Create an isolated venv and install `click`, `pyautogui`, `mss`.
5. Write a `computer-use.cmd` launcher into `%LOCALAPPDATA%\ComputerUse\bin` and add that folder to your User PATH.
6. Deploy the agent skill to `%USERPROFILE%\.agents\skills\ComputerUse\SKILL.md`.
7. Verify with `computer-use --help`.

Reinstall / overwrite:

```powershell
$s = (irm https://raw.githubusercontent.com/asterxsk/ComputerUse/main/install.ps1); iex "& { $s } -Force"
```

Install a specific release tag or a dev branch:

```powershell
# Specific release tag
$s = (irm https://raw.githubusercontent.com/asterxsk/ComputerUse/main/install.ps1); iex "& { $s } -Tag v0.1.0"

# Dev branch (skips release lookup)
$s = (irm https://raw.githubusercontent.com/asterxsk/ComputerUse/main/install.ps1); iex "& { $s } -Branch main"
```

### Windows — uninstall

```powershell
irm https://raw.githubusercontent.com/asterxsk/ComputerUse/main/uninstall.ps1 | iex
```

Removes `%LOCALAPPDATA%\ComputerUse`, the agent skill at `%USERPROFILE%\.agents\skills\ComputerUse`, and drops the `bin` entry from your User PATH. Pass `-Force` to skip the confirmation prompt, or `-KeepSkill` to keep the skill file in place.

### Manual / development install (any OS)

Prerequisites

- Python 3.9+
- Git

```bash
git clone https://github.com/asterxsk/ComputerUse.git
cd ComputerUse
python -m venv .venv
# Windows
.\.venv\Scripts\activate
# macOS / Linux
source .venv/bin/activate
pip install -r requirements.txt
python cli.py --help
```

## Usage / Examples

After a one-liner install, open a **new** terminal and use the `computer-use` launcher. In a dev clone, use `python cli.py` instead.

```bash
# READ
computer-use vision                          # capture primary monitor
computer-use vision --monitor 0              # capture all monitors combined
computer-use vision --monitor 2              # capture monitor #2
computer-use vision --max-images 3           # shrink the circular buffer

# WRITE - mouse
computer-use mouse-move 640 400 --duration 0.3
computer-use mouse-click --button left --x 450 --y 350
computer-use mouse-click --button right
computer-use mouse-click --clicks 2

# WRITE - keyboard
computer-use keyboard-type "hello world" --interval 0.02

# WRITE - shortcuts (destructive ones prompt y/N every time)
computer-use keyboard-shortcut alt_tab       # runs
computer-use keyboard-shortcut alt_f4        # prompts for confirmation
```

Screenshots are written to `./Computer-Use/` (auto-created) with names like `screen_YYYYMMDD_HHMMSS_mmm.png`. Only the 5 most recent are kept.

## Features

- **Vision (Read)** — fast screen capture via `mss`, multi-monitor aware (`-1` primary, `0` all, `1..N` specific), circular buffer in `./Computer-Use/` (max 5 PNGs, oldest auto-deleted).
- **Mouse (Write)** — smooth absolute-coordinate moves, left / right / middle clicks, multi-click.
- **Keyboard (Write)** — arbitrary text entry with configurable keystroke interval.
- **Shortcut runner (Write, safety-gated)** — named shortcuts; destructive ones (`alt_f4`, `ctrl_alt_del`, `cmd_q`) always prompt the user `y/N` before firing, every call.
- **Agent skill file** — `skill/SKILL.md` is deployed by the installer to `%USERPROFILE%\.agents\skills\ComputerUse\SKILL.md` so LLM agents can load the tool definitions directly.
- **Clear Read/Write permission model** designed for agent reasoning.
- **Cross-platform core** — Windows / macOS / Linux (installer is Windows; manual install works anywhere).

## Configuration

### Shortcut registry

Edit `shortcuts.py` to add or change shortcuts:

```python
SHORTCUTS = {
    "alt_tab":      {"keys": ["alt", "tab"],       "destructive": False},
    "cmd_space":    {"keys": ["command", "space"], "destructive": False},
    "win_r":        {"keys": ["win", "r"],         "destructive": False},
    "ctrl_w":       {"keys": ["ctrl", "w"],        "destructive": False},
    "alt_f4":       {"keys": ["alt", "f4"],        "destructive": True},
    "ctrl_alt_del": {"keys": ["ctrl", "alt", "del"], "destructive": True},
    "cmd_q":        {"keys": ["command", "q"],     "destructive": True},
}
```

Any shortcut with `"destructive": True` will always prompt the user before executing.

### Install paths (installer overrides)

```powershell
# Custom locations
$params = @{ InstallDir = "D:\Tools\ComputerUse"; SkillDir = "D:\agents\skills\ComputerUse" }
irm https://raw.githubusercontent.com/asterxsk/ComputerUse/main/install.ps1 -OutFile $env:TEMP\cu.ps1
& $env:TEMP\cu.ps1 @params
```

Default layout:

| What       | Path                                                  |
|------------|-------------------------------------------------------|
| Source     | `%LOCALAPPDATA%\ComputerUse\`                         |
| Launcher   | `%LOCALAPPDATA%\ComputerUse\bin\computer-use.cmd`     |
| venv       | `%LOCALAPPDATA%\ComputerUse\.venv\`                   |
| Skill      | `%USERPROFILE%\.agents\skills\ComputerUse\SKILL.md`   |
| Screenshots| `./Computer-Use/` (in the CWD where you run it)       |
| Version info| `%LOCALAPPDATA%\ComputerUse\.install-info.json`     |

## Agent Skill

The repo ships a structured skill document at [`skill/SKILL.md`](./skill/SKILL.md) intended to be loaded directly into an LLM agent's context. It contains:

- Permission model (Read vs Write).
- Exact CLI syntax and flags per tool.
- Shortcut registry and destructive-prompt contract.
- Recommended agent workflow (observe → analyze → act → verify).
- Error classes and expected agent responses.

The Windows installer copies this file to `%USERPROFILE%\.agents\skills\ComputerUse\SKILL.md` so any local agent that scans `~/.agents/skills/` picks it up automatically.

## Development

```bash
git clone https://github.com/asterxsk/ComputerUse.git
cd ComputerUse
python -m venv .venv
.\.venv\Scripts\activate        # or: source .venv/bin/activate
pip install -r requirements.txt

# try each tool
python cli.py vision
python cli.py vision --monitor 0
python cli.py mouse-move 500 400
python cli.py mouse-click --button right
python cli.py keyboard-type "hello"
python cli.py keyboard-shortcut alt_tab
python cli.py keyboard-shortcut alt_f4       # prompts y/N
```

## Roadmap

- macOS and Linux installer scripts (brew / curl pipe).
- Drag / scroll primitives.
- OCR / element-detection helpers for agents to resolve coordinates from the screenshot.
- Per-app shortcut packs.

## Contributing

Contributions welcome — fork, create a branch (`blackboxai/<topic>` or `feat/<topic>`), and open a pull request. Please keep the Read/Write categorization explicit for any new tool, and update `skill/SKILL.md` when you add or change commands.

## Authors

- asterxsk ([@asterxsk](https://github.com/asterxsk))

## Acknowledgements

- [`click`](https://click.palletsprojects.com/) for the CLI framework.
- [`mss`](https://python-mss.readthedocs.io/) for fast cross-platform screen capture.
- [`pyautogui`](https://pyautogui.readthedocs.io/) for mouse and keyboard input.

## License

Distributed under the MIT License. See [LICENSE](./LICENSE) for details.
