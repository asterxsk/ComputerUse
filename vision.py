from pathlib import Path
from datetime import datetime
import mss
from mss.exception import ScreenShotError

def ensure_computer_use_dir() -> Path:
    """Ensure Computer-Use directory exists."""
    dir_path = Path("./Computer-Use")
    dir_path.mkdir(exist_ok=True)
    return dir_path

def get_screenshot_files(max_images: int = 5) -> list[Path]:
    """Get list of screenshot files, sorted by name (oldest first)."""
    dir_path = ensure_computer_use_dir()
    files = list(dir_path.glob("screen_*.png"))
    files.sort(key=lambda p: p.stat().st_mtime)
    return files[:max_images]

def capture_screen(max_images: int = 5, monitor: int = -1) -> str:
    """
    Capture screen, save to Computer-Use/ with circular buffer.
    monitor: -1 primary, 0 all monitors, 1..N specific monitor
    Returns path to latest screenshot.
    """
    dir_path = ensure_computer_use_dir()

    # Delete oldest if at max
    files = get_screenshot_files(max_images)
    if len(files) >= max_images:
        files[0].unlink()

    # Save with timestamp
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S_%f")[:-3]
    filename = f"screen_{timestamp}.png"
    output_path = str(dir_path / filename)

    with mss.mss() as sct:
        monitors = sct.monitors
        max_monitor_index = len(monitors) - 1  # because index 0 is "all monitors"

        # Valid values: -1 (primary), 0 (all), 1..max_monitor_index (specific)
        if monitor not in (-1, 0) and not (1 <= monitor <= max_monitor_index):
            raise ValueError(
                f"Invalid monitor index: {monitor}. "
                f"Available: -1 (primary), 0 (all), 1..{max_monitor_index}."
            )

        try:
            sct.shot(mon=monitor, output=output_path)
        except ScreenShotError as exc:
            raise ValueError(
                f"Failed to capture monitor {monitor}. "
                f"Available: -1 (primary), 0 (all), 1..{max_monitor_index}."
            ) from exc

    return output_path
