import pyautogui
import time

def move_mouse(x: int, y: int, duration: float = 0.5):
    """
    Move mouse to coordinates (x, y).
    duration: seconds for smooth move.
    """
    pyautogui.moveTo(x, y, duration=duration)
    time.sleep(0.1)  # Brief settle

def click_mouse(button: str = 'left', x: int = None, y: int = None, clicks: int = 1):
    """
    Click at optional (x,y) or current position.
    button: 'left', 'right', 'middle'.
    """
    if x is not None and y is not None:
        move_mouse(x, y)
    
    if button == 'left':
        pyautogui.click(clicks=clicks)
    elif button == 'right':
        pyautogui.rightClick(clicks=clicks)
    elif button == 'middle':
        pyautogui.middleClick()
    else:
        raise ValueError(f"Unknown button: {button}")
    
    time.sleep(0.1)
