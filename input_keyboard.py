import pyautogui
import time
from shortcuts import is_destructive, get_shortcut_keys

def type_text(text: str, interval: float = 0.05):
    """
    Type the given text.
    interval: delay between keystrokes.
    """
    pyautogui.write(text, interval=interval)
    time.sleep(0.1)

def run_shortcut(shortcut_name: str):
    """
    Run a pre-defined shortcut after checking if destructive.
    Prompts user confirmation for destructive ones EVERY TIME.
    """
    if is_destructive(shortcut_name):
        confirm = input(f"WARNING: '{shortcut_name}' is destructive. Execute? (y/N): ").strip().lower()
        if confirm != 'y':
            print("Shortcut cancelled by user.")
            return
    
    keys = get_shortcut_keys(shortcut_name)
    pyautogui.hotkey(*keys)
    time.sleep(0.2)  # Allow action to take effect
