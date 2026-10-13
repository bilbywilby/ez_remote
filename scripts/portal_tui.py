#!/data/data/com.termux/files/usr/bin/python3
"""
Portal TUI for ez_remote
Interactive IR code lookup with clipboard export functionality.
"""

from __future__ import annotations

import json
import logging
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional

from rich.console import Console
from rich.table import Table
from rich.prompt import Prompt, Confirm
from rich.layout import Layout
from rich.panel import Panel
from rich.text import Text
from pydantic import BaseModel, Field

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("portal_tui")

PROJECT_ROOT = Path(__file__).parent.parent
DATA_DIR = PROJECT_ROOT / "remote_intelligence" / "data"

class CodeEntry(BaseModel):
    """Single IR code entry from codes_map.json."""
    brand: str
    model: str
    codes: List[int]
    protocol: str = "NEC"
    revision: Optional[str] = None


class TUIState(BaseModel):
    """Application state for persistence."""
    last_search: Optional[str] = None
    search_history: List[str] = []
    result_count: int = 0
    loaded_at: Optional[str] = None


class PortalTUI:
    """Terminal User Interface for IR code lookup."""
    
    def __init__(self) -> None:
        self.console = Console()
        self.data_dir = DATA_DIR
        self.codes_map_path = self.data_dir / "codes_map.json"
        self.state_path = PROJECT_ROOT / ".tui_state.json"
        
        self.entries: List[CodeEntry] = []
        self.state = TUIState()
        self._load_state()
        
        if not self._load_codes_map():
            logger.error("No codes_map.json found - cannot start TUI")
            sys.exit(1)
    
    def _load_state(self) -> None:
        """Load persisted TUI state if available."""
        if self.state_path.exists():
            try:
                data = json.loads(self.state_path.read_text(encoding="utf-8"))
                self.state = TUIState(**data)
            except Exception:
                self.state = TUIState()
    
    def _save_state(self) -> None:
        """Persist current TUI state."""
        try:
            self.state_path.write_text(
                json.dumps(self.state.model_dump(exclude_none=True), indent=2, default=str),
                encoding="utf-8"
            )
        except Exception as e:
            logger.warning(f"Failed to save state: {e}")
    
    def _load_codes_map(self) -> bool:
        """Load and validate codes_map.json."""
        if not self.codes_map_path.exists():
            return False
        
        try:
            content = self.codes_map_path.read_text(encoding="utf-8")
            data = json.loads(content)
            
            # Validate schema
            if "mappings" not in data:
                logger.error("Invalid codes_map.json: missing 'mappings' key")
                return False
            
            self.entries = [CodeEntry(**item) for item in data["mappings"]]
            self.state.loaded_at = datetime.now(timezone.utc).isoformat()
            self.state.result_count = len(self.entries)
            
            logger.info(f"Loaded {len(self.entries)} code entries")
            return True
        except Exception as e:
            logger.error(f"Failed to load codes_map.json: {e}")
            return False
    
    def search(self, query: str) -> List[CodeEntry]:
        """Search entries by brand or model."""
        query_lower = query.lower()
        
        matches = [
            entry for entry in self.entries
            if query_lower in entry.brand.lower() or query_lower in entry.model.lower()
        ]
        
        # Track search history (deduplicated)
        if query not in self.state.search_history[-10:]:
            self.state.search_history.append(query)
            self.state.search_history = self.state.search_history[-20:]  # Keep last 20
        
        return matches
    
    def render_table(self, entries: List[CodeEntry], title: str = "Search Results") -> Table:
        """Render Rich table display."""
        table = Table(title=title, expand=True)
        table.add_column("Brand", style="cyan", no_wrap=True)
        table.add_column("Model", style="magenta", no_wrap=True)
        table.add_column("Protocol", style="green")
        table.add_column("Codes", justify="right", style="yellow")
        table.add_column("Revision", style="dim")
        
        for entry in entries[:50]:  # Limit display to prevent overflow
            codes_str = ", ".join(str(c) for c in entry.codes[:5])
            if len(entry.codes) > 5:
                codes_str += f"... (+{len(entry.codes) - 5})"
            
            table.add_row(
                entry.brand,
                entry.model,
                entry.protocol,
                codes_str,
                entry.revision or "",
            )
        
        if len(entries) > 50:
            table.caption = f"Showing 50 of {len(entries)} results"
        
        return table
    
    def export_to_clipboard(self, entries: List[CodeEntry]) -> bool:
        """Export results to system clipboard using xclip/termux-clipboard-set."""
        if not entries:
            self.console.print("[red]No entries to export[/red]")
            return False
        
        try:
            # Try Termux clipboard utility first
            import subprocess
            output_lines = []
            for entry in entries:
                for code in entry.codes:
                    output_lines.append(f"{entry.brand}|{entry.model}|{entry.protocol}|{code}")
            
            output_text = "\n".join(output_lines)
            
            # Try Termux clipboard API
            subprocess.run(
                ["termux-clipboard-set"],
                input=output_text.encode("utf-8"),
                capture_output=True,
                timeout=5
            )
            
            self.console.print(f"[green]✅ Copied {len(entries) * sum(len(e.codes) for e in entries)} codes to clipboard![/green]")
            return True
        except Exception as e:
            self.console.print(f"[yellow]⚠️  Clipboard failed: {e}. Use Ctrl+C to copy manually.[/yellow]")
            self.console.print(output_text[:1000])  # Show truncated output
            return False
    
    def export_to_file(self, entries: List[CodeEntry], filepath: Optional[Path] = None) -> Path:
        """Export results to CSV/JSON file."""
        if not filepath:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filepath = PROJECT_ROOT / f"export_{timestamp}.csv"
        
        try:
            lines = ["brand,model,protocol,code"]
            for entry in entries:
                for code in entry.codes:
                    lines.append(f"{entry.brand},{entry.model},{entry.protocol},{code}")
            
            filepath.write_text("\n".join(lines), encoding="utf-8")
            self.console.print(f"[green]✅ Exported to {filepath}[/green]")
            return filepath
        except Exception as e:
            self.console.print(f"[red]❌ Export failed: {e}[/red]")
            raise
    
    def run_main_menu(self) -> None:
        """Main application loop."""
        while True:
            self.console.clear()
            self.console.print(Panel(
                f"[bold blue]EZ_REMOTE PORTAL TUI[/bold blue]\n"
                f"Loaded: {self.state.result_count} entries | Last search: {self.state.last_search or 'None'}",
                border_style="blue"
            ))
            
            self.console.print("\n[bold]Menu:[/bold]")
            self.console.print("  [1] Search codes")
            self.console.print("  [2] Browse all brands")
            self.console.print("  [3] Export results")
            self.console.print("  [4] Statistics")
            self.console.print("  [5] Exit")
            
            choice = Prompt.ask("\nSelect option", choices=["1", "2", "3", "4", "5"], default="1")
            
            if choice == "1":
                self._handle_search()
            elif choice == "2":
                self._handle_browse()
            elif choice == "3":
                self._handle_export()
            elif choice == "4":
                self._handle_stats()
            elif choice == "5":
                self.console.print("[yellow]Exiting...[/yellow]")
                self._save_state()
                break
            
            if not Confirm.ask("\nContinue?", default=True):
                self._save_state()
                break
    
    def _handle_search(self) -> None:
        """Handle search flow."""
        query = Prompt.ask("Enter brand or model search term")
        if not query:
            return
        
        results = self.search(query)
        self.state.last_search = query
        
        if not results:
            self.console.print(f"[yellow]No matches for '{query}'[/yellow]")
            return
        
        self.console.print(self.render_table(results, f"Results for '{query}'"))
        
        if Confirm.ask("Export to clipboard?", default=False):
            self.export_to_clipboard(results)
    
    def _handle_browse(self) -> None:
        """Browse all brands alphabetically."""
        brands = sorted(set(entry.brand for entry in self.entries))
        
        table = Table(title="Available Brands")
        table.add_column("Brand", style="cyan")
        table.add_column("Models", justify="right")
        table.add_column("Total Codes", justify="right")
        
        for brand in brands:
            brand_entries = [e for e in self.entries if e.brand == brand]
            total_codes = sum(len(e.codes) for e in brand_entries)
            table.add_row(brand, str(len(brand_entries)), str(total_codes))
        
        self.console.print(table)
    
    def _handle_export(self) -> None:
        """Handle export flow."""
        self.console.print("[bold]Export Options:[/bold]")
        self.console.print("  [1] All entries (CSV)")
        self.console.print("  [2] Last search results")
        
        choice = Prompt.ask("Select export option", choices=["1", "2"], default="1")
        
        if choice == "1":
            self.export_to_file(self.entries)
        else:
            if not self.state.last_search:
                self.console.print("[yellow]No previous search to export[/yellow]")
                return
            results = self.search(self.state.last_search)
            self.export_to_file(results)
    
    def _handle_stats(self) -> None:
        """Show statistics overview."""
        stats = {
            "total_entries": len(self.entries),
            "unique_brands": len(set(e.brand for e in self.entries)),
            "unique_protocols": len(set(e.protocol for e in self.entries)),
            "total_codes": sum(len(e.codes) for e in self.entries),
            "average_codes_per_entry": round(sum(len(e.codes) for e in self.entries) / max(len(self.entries), 1), 1),
        }
        
        self.console.print(Panel.fit(
            f"[bold]Statistics[/bold]\n\n"
            f"• Total entries: [green]{stats['total_entries']}[/green]\n"
            f"• Unique brands: [blue]{stats['unique_brands']}[/blue]\n"
            f"• Unique protocols: [purple]{stats['unique_protocols']}[/purple]\n"
            f"• Total IR codes: [yellow]{stats['total_codes']}[/yellow]\n"
            f"• Average codes/entry: [cyan]{stats['average_codes_per_entry']}[/cyan]",
            border_style="green"
        ))


def main() -> None:
    """Entry point for TUI."""
    logger.info("Starting ez_remote Portal TUI")
    
    try:
        tui = PortalTUI()
        tui.run_main_menu()
    except KeyboardInterrupt:
        logger.info("TUI interrupted by user")
        sys.exit(0)
    except Exception as exc:
        logger.critical(f"TUI crashed: {exc}")
        sys.exit(1)


if __name__ == "__main__":
    main()
