import os
import subprocess
from pathlib import Path
from typing import Optional
import typer
from rich.console import Console
from rich.table import Table
from rich import box
import winreg

VERSION = "0.2.0"

app = typer.Typer()
console = Console()
JAVA_DIR = Path("C:/Program Files/Java")

def get_current_jdk() -> Optional[Path]:
    """Get the current JDK from Registry."""
    try:
        key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, r"Environment")
        java_home, _ = winreg.QueryValueEx(key, "JAVA_HOME")
        winreg.CloseKey(key)
        return Path(java_home) if java_home else None
    except FileNotFoundError:
        return None
    except OSError:
        return None

def list_jdks():
    return [p for p in JAVA_DIR.iterdir() if p.is_dir() and p.name.startswith("jdk")]

@app.command("list")
def list_command():
    """List all installed Java versions on JAVA_DIR."""
    jdks = list_jdks()
    current_jdk = get_current_jdk()
    
    table = Table(box=box.SIMPLE_HEAD)
    table.add_column("ID", style="bold white", no_wrap=True, justify="center")
    table.add_column("Version", style="cyan", no_wrap=True, justify="left")
    table.add_column("Path", style="magenta", justify="left")

    for i, jdk in enumerate(jdks, start=1):
        marker = " [green]✓[/green]" if current_jdk and jdk == current_jdk else ""
        table.add_row(str(i), f"{jdk.name}{marker}", str(jdk))
    
    console.print(table)

@app.command("set")
def set_command():
    """Set java version by updating JAVA_HOME environment variable."""
    jdks = list_jdks()

    if not jdks:
        console.print("[bold red]No JDKs found in the specified JAVA_DIR.[/bold red]")
        raise typer.Exit(1)
    
    # Show available JDKs
    list_command()

    # Interactive selection with validation
    try:
        choice = typer.prompt(
            "\nEnter the option number of the Java version to set",
            type=int,
            #default=1
        )
        
        if choice < 1 or choice > len(jdks):
            console.print(f"[bold red]Invalid choice. Please enter a number between 1 and {len(jdks)}.[/bold red]")
            raise typer.Exit(1)
        
        selected_jdk = jdks[choice - 1]

        # Update JAVA_HOME environment variable
        console.print(f"\n[bold green]Selected:[/bold green] [bold cyan]{selected_jdk.name}[/bold cyan]")

        update_java(selected_jdk)
        
    except ValueError:
        console.print("[bold red]Invalid input. Please enter a number.[/bold red]")
        raise typer.Exit(1)

@app.command("current")
def current_command():
    """Show the JAVA_HOME configured in the Registry (effective in new terminals)."""
    current_jdk = get_current_jdk()
    if current_jdk:
        console.print(f"[bold green]Current JAVA_HOME:[/bold green] [bold cyan]{current_jdk}[/bold cyan]")

        result = subprocess.run("java -version", shell=True, capture_output=True, text=True)
        version = result.stderr.strip() if result.stderr else result.stdout.strip()
        version = version.splitlines()[0] if version else "Unknown"
        version_line = version.split(" ")[2] if version else "Unknown"
        version_line = version_line.strip('"')
        console.print(f"[bold green]Current session Java Version:[/bold green] {version_line}")
        console.print("[yellow]If the version is not displayed correctly, you must open a new terminal.[/yellow]")
    else:
        console.print("[bold red]JAVA_HOME is not set in Registry.[/bold red]")
        console.print("[bold yellow]⚠ Use 'java-manager set' to configure it.[/bold yellow]")

def update_path_registry(java_bin: str):
    """Update the PATH in the Windows Registry to include Java bin directory."""
    try:
        # Open the Environment key in registry (User environment variables)
        key = winreg.OpenKey(
            winreg.HKEY_CURRENT_USER,
            r"Environment",
            0,
            winreg.KEY_ALL_ACCESS
        )
        
        # Get current PATH
        try:
            current_path, _ = winreg.QueryValueEx(key, "Path")
        except FileNotFoundError:
            current_path = ""
        
        # Remove any existing Java bin paths
        path_entries = [p.strip() for p in current_path.split(";") if p.strip()]
        path_entries = [p for p in path_entries if not (p.lower().endswith("\\bin") and "java" in p.lower())]
        
        # Add new Java bin path at the beginning
        path_entries.insert(0, java_bin)
        
        # Set the new PATH
        new_path = ";".join(path_entries)
        winreg.SetValueEx(key, "Path", 0, winreg.REG_EXPAND_SZ, new_path)
        winreg.CloseKey(key)
        
        return True
    except Exception as e:
        console.print(f"[bold red]Failed to update PATH in registry: {e}[/bold red]")
        return False

def update_java(jdk_path: Path):
    """
    Update the JAVA_HOME environment variable and PATH (Registry only).
    """
    str_jdk = str(jdk_path)
    java_bin = "%JAVA_HOME%\\bin"
    
    # Prompt to save permanently
    if typer.confirm("\nAre you sure you want to change JAVA_HOME and update PATH?", default=True):
        try:
            # Set JAVA_HOME using registry
            key = winreg.OpenKey(
                winreg.HKEY_CURRENT_USER,
                r"Environment",
                0,
                winreg.KEY_ALL_ACCESS
            )
            winreg.SetValueEx(key, "JAVA_HOME", 0, winreg.REG_SZ, str_jdk)
            winreg.CloseKey(key)

            console.print("\n[bold green]✓ JAVA_HOME changed successfully![/bold green]")

            # Update PATH (with %JAVA_HOME%\bin)
            if update_path_registry(java_bin):
                console.print("[bold green]✓ PATH changed successfully![/bold green]")
            
            console.print("\n[yellow]Open a NEW terminal to see the changes.[/yellow]")
        except Exception as e:
            console.print(f"\n[bold red]✗ Failed to change JAVA_HOME: {e}[/bold red]")
            console.print("[yellow]Try running as administrator or check your permissions.[/yellow]")

@app.command("version")
def version_command():
    """Show the version of jver."""
    console.print(f"[bold green]jver {VERSION}[/bold green]")

if __name__ == "__main__":
    app()