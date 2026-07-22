# Implementation Plan

## Overview
This plan outlines the complete implementation of a Python CLI tool for AI agents to perform cross-platform remote desktop automation, featuring vision capture with circular buffering and input controls (mouse, keyboard, shortcuts) with safety checks for destructive actions.

The tool will be built as modular, flag-based CLI commands using the `click` library for rich argument handling. Core capabilities are separated into Read (screen capture) and Write (mouse/keyboard/shortcuts) tools to enable agent reasoning on state changes. A local `Computer-Use` directory manages screenshots. Destructive shortcuts trigger mandatory user confirmation. The project includes agent-ready tool documentation, README, and setup instructions. Cross-platform compatibility targets Windows, macOS, Linux using pyautogui (input), mss (capture), and PIL (image handling).

## Types
No complex type system changes; uses Python typing with dataclasses for config if needed.

- ScreenshotConfig: path=str, max_images=int=5
- ShortcutConfig: name=str, keys=list[str], is_destructive=bool
- Destructive list: Hardcoded enum-like list ["alt+f4", "ctrl+alt+del", "cmd+q", etc.]

CLI args use str/int/bool types with validation (e.g., coords as int pairs).

## Files
Create all files in current directory (d:/Apps/projects/cli).

New files:
- `cli.py`: Main CLI entrypoint with click commands for all tools.
- `vision.py`: Read tool - screen capture with circular buffer in `./Computer-Use/`.
- `input_mouse.py`: Write tool - mouse movements/clicks.
- `input_keyboard.py`: Write tool - text entry and shortcuts with safety.
- `shortcuts.py`: Config of safe/destructive shortcuts.
- `requirements.txt`: Dependencies.
- `README.md`: Onboarding, setup, usage, agent tool defs.
- `Computer-Use/`: Auto-created dir for screenshots (e.g., screen_001.png).

No deletions/moves.

## Functions
New functions, all standalone, invoked via CLI:

- `capture_screen(max_images: int = 5) -> str`: vision.py - Captures screen, saves to circular buffer, returns latest path. (Read)
- `move_mouse(x: int, y: int)`: input_mouse.py - Moves to coords. (Write)
- `click_mouse(button: str = 'left', x: int = None, y: int = None)`: input_mouse.py - Clicks at optional coords. (Write)
- `type_text(text: str)`: input_keyboard.py - Types string. (Write)
- `run_shortcut(shortcut: str)`: input_keyboard.py - Executes shortcut after destructive check. (Write)

CLI wrappers in cli.py: e.g., `click.command('vision')(capture_screen_cli)`

## Classes
No classes needed; pure functional modular design. Optional ClickGroup in cli.py for subcommands.

## Dependencies
Add to requirements.txt:
```
click==8.1.7
pyautogui==0.9.54
mss==9.0.1
pillow==10.4.0
```

Cross-platform; pyautogui/mss handle OS diffs.

## Testing
Manual verification via CLI runs:
- Capture 6+ screens, verify buffer=5, oldest deleted.
- Mouse moves/clicks at coords.
- Type text, run safe/destructive shortcuts (confirm prompt).
- Cross-OS via docs.

No unit tests initially; add pytest later if requested.

## Implementation Order
1. Create requirements.txt.
2. Create core modules: vision.py, input_mouse.py, input_keyboard.py, shortcuts.py.
3. Create cli.py integrating all.
4. Create README.md with agent tool docs, setup, usage.
5. Test sequence: pip install, run each command, verify Computer-Use dir/behavior.
