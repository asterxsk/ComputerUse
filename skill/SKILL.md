# SKILL: Desktop Automation CLI

A structured skill definition for LLM agents operating the cross-platform Python CLI located at `d:/Apps/projects/cli` (invoked via `python cli.py <command> [flags]`).

This skill enables an agent to observe and control a human user's desktop. It is split into **Read** tools (safe, view-only) and **Write** tools (mutate user state). Every action must be reasoned about before execution. Destructive shortcuts always require explicit user confirmation at runtime.

---

## 1. Permission Model (Agent MUST Respect)

| Tool              | Category | State Impact                                          |
|-------------------|----------|-------------------------------------------------------|
| `vision`          | READ     | None — only reads pixels, writes PNG to local buffer. |
| `mouse-move`      | WRITE    | Moves hardware cursor.                                |
| `mouse-click`     | WRITE    | Triggers UI actions in foreground app.                |
| `keyboard-type`   | WRITE    | Injects arbitrary text into focused field.            |
| `keyboard-shortcut` | WRITE  | Executes key combos; **destructive ones prompt user every time**. |

**Rule for the agent:**
- Prefer READ before WRITE. Capture the screen, analyze it, decide, then act.
- Never chain WRITE actions blindly — re-capture to verify state when uncertain.
- Never attempt to bypass the destructive shortcut prompt. The prompt is intentional.

---

## 2. Tool Definitions

### 2.1 `vision` — READ
**Purpose:** Capture current screen state into a PNG and return its path. Uses a circular buffer (max 5 files) in `./Computer-Use/`, auto-deleting the oldest.

**Syntax:**
```
python cli.py vision [--max-images INT] [--monitor INT]
```

**Flags:**
| Flag            | Type | Default | Meaning |
|-----------------|------|---------|---------|
| `--max-images`  | int  | `5`     | Max PNGs retained in `./Computer-Use/`. |
| `--monitor`     | int  | `-1`    | `-1` = primary monitor, `0` = all monitors combined, `1..N` = specific monitor index. |

**Returns (stdout):** `Screenshot saved: Computer-Use\screen_YYYYMMDD_HHMMSS_mmm.png`

**Errors:**
- Invalid monitor index → `ValueError: Invalid monitor index: X. Available: -1 (primary), 0 (all), 1..N.`

**Examples:**
```bash
python cli.py vision                      # primary, default buffer
python cli.py vision --monitor 2          # secondary display only
python cli.py vision --monitor 0          # combined all displays
python cli.py vision --max-images 3       # tighter buffer
```

---

### 2.2 `mouse-move` — WRITE
**Purpose:** Smoothly move cursor to absolute screen coordinates.

**Syntax:**
```
python cli.py mouse-move X Y [--duration FLOAT]
```

**Args / Flags:**
| Name         | Type  | Default | Meaning |
|--------------|-------|---------|---------|
| `X` (pos)    | int   | —       | Target X (pixels from left). |
| `Y` (pos)    | int   | —       | Target Y (pixels from top).  |
| `--duration` | float | `0.5`   | Seconds for smooth move.     |

**Example:**
```bash
python cli.py mouse-move 640 400 --duration 0.3
```

---

### 2.3 `mouse-click` — WRITE
**Purpose:** Click mouse button at optional coords (or current position).

**Syntax:**
```
python cli.py mouse-click [--button left|right|middle] [--x INT] [--y INT] [--clicks INT]
```

**Flags:**
| Flag       | Type | Default | Meaning |
|------------|------|---------|---------|
| `--button` | enum | `left`  | `left` / `right` / `middle`. |
| `--x`      | int  | —       | Optional target X (moves first). |
| `--y`      | int  | —       | Optional target Y (moves first). |
| `--clicks` | int  | `1`     | Number of clicks (e.g. 2 for double). |

**Examples:**
```bash
python cli.py mouse-click --button left --x 450 --y 350
python cli.py mouse-click --button right                # at current pos
python cli.py mouse-click --clicks 2                    # double-click current pos
```

---

### 2.4 `keyboard-type` — WRITE
**Purpose:** Type arbitrary text into the currently focused input.

**Syntax:**
```
python cli.py keyboard-type "TEXT" [--interval FLOAT]
```

**Args / Flags:**
| Name         | Type  | Default | Meaning |
|--------------|-------|---------|---------|
| `TEXT`       | str   | —       | String to type. Quote if it contains spaces. |
| `--interval` | float | `0.05`  | Seconds between keystrokes. |

**Example:**
```bash
python cli.py keyboard-type "hello world" --interval 0.02
```

**Note:** The agent must ensure a text field is focused before calling this (use vision + click first).

---

### 2.5 `keyboard-shortcut` — WRITE (safety-gated)
**Purpose:** Execute a predefined keyboard shortcut. Destructive shortcuts **always** prompt the user for `y/N` confirmation, every single time. Non-destructive ones run immediately.

**Syntax:**
```
python cli.py keyboard-shortcut SHORTCUT_NAME
```

**Behavior:**
- Looks up `SHORTCUT_NAME` in `shortcuts.py`.
- If `destructive=True`: prints `WARNING: '<name>' is destructive. Execute? (y/N):` and waits.
- If `destructive=False`: executes immediately.
- Unknown name → `ValueError: Unknown shortcut: <name>`.

**Current shortcut registry:**
| Name           | Keys                | Destructive | Typical use |
|----------------|---------------------|-------------|-------------|
| `alt_tab`      | alt + tab           | No          | Switch windows |
| `cmd_space`    | command + space     | No          | macOS Spotlight |
| `win_r`        | win + r             | No          | Windows Run dialog |
| `ctrl_w`       | ctrl + w            | No          | Close tab (app-dependent) |
| `alt_f4`       | alt + f4            | **Yes**     | Close app (Windows) |
| `ctrl_alt_del` | ctrl + alt + del    | **Yes**     | Security screen |
| `cmd_q`        | command + q         | **Yes**     | Quit app (macOS) |

**Examples:**
```bash
python cli.py keyboard-shortcut alt_tab      # runs immediately
python cli.py keyboard-shortcut alt_f4       # will prompt user (y/N)
```

**Agent rule:** If you *want* a destructive shortcut, state the reason in your turn before calling it. Do not retry after a user declines.

---

## 3. Recommended Agent Workflow

1. **Observe** → `python cli.py vision` (pick correct `--monitor`).
2. **Analyze** the returned PNG for target element coordinates.
3. **Act** (Write) → `mouse-move` / `mouse-click` / `keyboard-type`.
4. **Verify** → call `vision` again to confirm the UI changed as intended.
5. **Escalate carefully** → only invoke destructive shortcuts with explicit intent.

---

## 4. Environment & Filesystem Contract

- **Project root:** `d:/Apps/projects/cli` (adjust if relocated).
- **Screenshot directory:** `./Computer-Use/` — auto-created. Filenames `screen_YYYYMMDD_HHMMSS_mmm.png`.
- **Buffer policy:** Strict LRU by mtime; oldest removed when `max_images` reached.
- **OS support:** Windows / macOS / Linux via `mss` and `pyautogui`.
- **Python deps (requirements.txt):** `click`, `pyautogui`, `mss`.

---

## 5. Error Handling Summary

| Error class         | Cause                                              | Agent response |
|---------------------|----------------------------------------------------|----------------|
| `ValueError` (monitor) | `--monitor` out of range.                       | Re-read message; choose valid index in `-1/0/1..N`. |
| `ValueError` (shortcut) | Unknown shortcut name.                         | Pick from registry or ask user to extend `shortcuts.py`. |
| `ScreenShotError`   | Display/driver failure.                            | Report to user; do not retry blindly. |
| User-declined prompt | User typed anything other than `y`.               | Abort path; choose non-destructive alternative. |

---

## 6. Extensibility Pointers (for the agent, not to execute automatically)

- **Add shortcut:** edit `shortcuts.py`, append entry to `SHORTCUTS` dict with `destructive` flag.
- **Add new tool:** add function module, register as `@cli.command()` in `cli.py`, document here in this SKILL.md under a new section, keeping the Read/Write categorization explicit.

---

## 7. Quick Reference Card

```
READ:
  vision [--max-images N=5] [--monitor -1|0|1..N]

WRITE (safe):
  mouse-move X Y [--duration 0.5]
  mouse-click [--button left|right|middle] [--x INT] [--y INT] [--clicks 1]
  keyboard-type "text" [--interval 0.05]
  keyboard-shortcut <safe_name>         # e.g. alt_tab, cmd_space, win_r, ctrl_w

WRITE (gated, prompts user every time):
  keyboard-shortcut <destructive_name>  # e.g. alt_f4, ctrl_alt_del, cmd_q
