#!/usr/bin/env python3
"""
CLI tool for AI agent desktop automation.
Categories: Read (vision), Write (mouse/keyboard/shortcuts).
Run: pip install -r requirements.txt; python cli.py --help
"""

import click
from vision import capture_screen
from input_mouse import move_mouse, click_mouse
from input_keyboard import type_text, run_shortcut

@click.group()
def cli():
    """AI Agent Desktop Automation CLI."""
    pass

@cli.command()
@click.option('--max-images', default=5, type=int, help='Max screenshots in buffer.')
@click.option('--monitor', default=-1, type=int, help='Monitor index: -1 primary, 0 all, 1+ specific monitor.')
def vision(max_images, monitor):
    """Read: Capture screen (circular buffer in Computer-Use/)."""
    path = capture_screen(max_images=max_images, monitor=monitor)
    click.echo(f"Screenshot saved: {path}")

@cli.command()
@click.argument('x', type=int)
@click.argument('y', type=int)
@click.option('--duration', default=0.5, type=float, help='Move duration (s).')
def mouse_move(x, y, duration):
    """Write: Move mouse to (x,y)."""
    move_mouse(x, y, duration)
    click.echo(f"Mouse moved to ({x}, {y})")

@cli.command()
@click.option('--button', default='left', type=click.Choice(['left', 'right', 'middle']), help='Click button.')
@click.option('--x', type=int, help='X coord (optional, else current pos).')
@click.option('--y', type=int, help='Y coord (optional, else current pos).')
@click.option('--clicks', default=1, type=int, help='Number of clicks.')
def mouse_click(button, x, y, clicks):
    """Write: Click mouse."""
    click_mouse(button, x, y, clicks)
    click.echo(f"Clicked {button} ({clicks}x) at ({x or 'current'}, {y or 'current'})")

@cli.command()
@click.argument('text')
@click.option('--interval', default=0.05, type=float, help='Delay between keys.')
def keyboard_type(text, interval):
    """Write: Type text."""
    type_text(text, interval)
    click.echo(f"Typed: {text}")

@cli.command()
@click.argument('shortcut')
def keyboard_shortcut(shortcut):
    """Write: Run shortcut (destructive prompts user)."""
    run_shortcut(shortcut)
    click.echo(f"Executed shortcut: {shortcut}")

if __name__ == '__main__':
    cli()
