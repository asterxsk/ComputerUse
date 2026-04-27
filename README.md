# AI Agent Desktop Automation CLI

Cross-platform Python CLI for AI agents to automate desktop via screen capture (Read) and input (Write). Modular functions invoked via flags.

## Quick Start

### Install as a global CLI on Windows (one-liner)

Open **PowerShell** and run:

```powershell
irm https://raw.githubusercontent.com/asterxsk/ComputerUse/main/install.ps1 | iex
```

The installer will:

1. Verify Python 3.9+ (offers winget install if missing).
2. Download the repo to `%LOCALAPPDATA%\ComputerUse`.
3. Create an isolated virtualenv and install dependencies.
4. Register a `computer-use` launcher on your user PATH.

Then **open a new terminal** and use the CLI from anywhere:

```powershell
computer-use --help
computer-use vision --monitor -1
computer-use mouse-move 500 400
computer-use keyboard-type "hello"
computer-use keyboard-shortcut alt_tab
```

To force a full reinstall:

```powershell
$tmp = "$env:TEMP\computer-use-install.ps1"
irm https://raw.githubusercontent.com/asterxsk/ComputerUse/main/install.ps1 -OutFile $tmp
powershell -ExecutionPolicy Bypass -File $tmp -Force
```

### Manual / development install

```bash
pip install -r requirements.txt
python cli.py --help
```

**Permissions Guide for Agents:**
- **Read Tools** (safe, view-only): `vision` - Capture screen state.
- **Write Tools** (mutate system): `mouse_move`, `mouse_click`, `keyboard_type`, `keyboard_shortcut` - Always reason about impact.

## Commands

### Read: Vision (Screen Capture)
```bash
python cli.py vision --max-images 5 --monitor -1
```
- Circular buffer: Max 5 PNGs in `./Computer-Use/`, auto-deletes oldest.
- Monitor support:
  - `--monitor -1` = primary monitor
  - `--monitor 0` = all monitors combined
  - `--monitor 1..N` = specific monitor index
- Invalid monitor indexes return a clear error showing valid range.
- Returns: Path to latest screenshot.
- Use: Get current UI state before Write actions.

### Write: Mouse Control
```bash
# Move
python cli.py mouse-move 400 300 --duration 0.5

# Click
python cli.py mouse-click --button left --x 450 --y 350 --clicks 1
python cli.py mouse-click --button right  # Current position
```

### Write: Keyboard Type
```bash
python cli.py keyboard-type "Hello World" --interval 0.05
```

### Write: Shortcuts (Safety-Gated)
```bash
python cli.py keyboard-shortcut alt_tab     # Safe
python cli.py keyboard-shortcut alt_f4      # PROMPTS: "WARNING: destructive. y/N?"
```
- Destructive (always prompts): alt_f4, ctrl_alt_del, cmd_q, etc.
- Safe: alt_tab, cmd_space, win_r, ctrl_w.
- Extend `shortcuts.py`.

## System Skill / Tool Definitions (for LLM Agents)

```
TOOLS:
1. vision --max-images INT (default=5) --monitor INT (default=-1)
   Purpose: Read screen state. Returns PNG path. Circular buffer auto-manages.
   Monitor flags: -1 primary, 0 all monitors, 1..N specific monitor.
   Invalid monitor index => explicit error with available range.
   Permission: READ (safe)
   Example: "Capture monitor 2 UI for dual-display workflow"

2. mouse-move X:int Y:int --duration FLOAT (default=0.5)
   Purpose: Smooth move mouse to coords (0-1920x1080 typical).
   Permission: WRITE (moves cursor)
   Example: "Move to button center"

3. mouse-click [--button left/right/middle] [--x INT] [--y INT] [--clicks INT=1]
   Purpose: Click at coords or current pos.
   Permission: WRITE (interacts)
   Example: "Click submit button"

4. keyboard-type TEXT [--interval FLOAT=0.05]
   Purpose: Type arbitrary text.
   Permission: WRITE (inputs text)
   Example: "Enter search query"

5. keyboard-shortcut SHORTCUT:str
   Purpose: Run predefined shortcut. Destructive ALWAYS prompts user.
   Permission: WRITE (system action)
   Examples: "alt_tab" (switch), "alt_f4" (prompts close)
   List in shortcuts.py
```

## Architecture
- `cli.py`: Click-based entrypoint.
- `vision.py`: mss-based capture, circular buffer logic, multi-monitor validation.
- `input_*.py`: pyautogui wrappers.
- `shortcuts.py`: Config + safety.

## Troubleshooting
- Grant accessibility/automation permissions (macOS System Prefs > Security).
- Windows: Run as admin if needed.
- Coords: Use vision first, analyze screenshot for targets.

## Extend
Add shortcuts in `shortcuts.py`. New tools as click commands.
