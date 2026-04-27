# Pre-defined shortcuts with destructive flags
# Agent specifies shortcut name, tool checks if destructive and prompts user

SHORTCUTS = {
    "alt_tab": {"keys": ["alt", "tab"], "destructive": False},
    "cmd_space": {"keys": ["command", "space"], "destructive": False},  # macOS spotlight
    "win_r": {"keys": ["win", "r"], "destructive": False},  # Windows run
    "alt_f4": {"keys": ["alt", "f4"], "destructive": True},
    "ctrl_alt_del": {"keys": ["ctrl", "alt", "del"], "destructive": True},
    "cmd_q": {"keys": ["command", "q"], "destructive": True},  # macOS quit
    "ctrl_w": {"keys": ["ctrl", "w"], "destructive": False},  # close tab safe-ish
    # Add more as needed
}

DESTRUCTIVE_SHORTCUTS = [name for name, config in SHORTCUTS.items() if config["destructive"]]

def is_destructive(shortcut_name: str) -> bool:
    """Check if shortcut is destructive."""
    return shortcut_name.lower() in [s.lower() for s in DESTRUCTIVE_SHORTCUTS]

def get_shortcut_keys(shortcut_name: str) -> list:
    """Get keys for shortcut."""
    name_lower = shortcut_name.lower()
    for name, config in SHORTCUTS.items():
        if name_lower == name.lower():
            return config["keys"]
    raise ValueError(f"Unknown shortcut: {shortcut_name}")
