"""Tkinter desktop application for viewing LeegooBuilder projects."""

from __future__ import annotations

import argparse
from pathlib import Path
import queue
import sys
import threading
import tkinter as tk
from tkinter import ttk, messagebox
from typing import Any

# Bootstrap lbapi package from parent directory
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from lbapi import LbApiClient, load_config


class ProjectsViewerApp:
    """Tkinter UI application for browsing projects returned by the Web API."""

    def __init__(self, root: tk.Tk, client: LbApiClient | None = None) -> None:
        self.root = root
        self.root.title("LeegooBuilder Projects Viewer")
        self.root.geometry("880x480")
        self.root.minsize(640, 360)

        self.client = client or LbApiClient()
        self.queue: queue.Queue[tuple[dict[str, Any] | None, Exception | None]] = queue.Queue()
        self._setup_ui()

    def _setup_ui(self) -> None:
        # Top toolbar
        toolbar = ttk.Frame(self.root, padding=8)
        toolbar.pack(side=tk.TOP, fill=tk.X)

        self.load_btn = ttk.Button(toolbar, text="Load Projects", command=self.start_load_projects)
        self.load_btn.pack(side=tk.LEFT, padx=(0, 10))

        self.status_var = tk.StringVar(value="Ready. Click 'Load Projects' to retrieve projects.")
        self.status_label = ttk.Label(toolbar, textvariable=self.status_var)
        self.status_label.pack(side=tk.LEFT, fill=tk.X, expand=True)

        # Treeview frame
        tree_frame = ttk.Frame(self.root, padding=(8, 0, 8, 8))
        tree_frame.pack(side=tk.TOP, fill=tk.BOTH, expand=True)

        columns = ("project_id", "description", "internal_id", "is_favorite")
        self.tree = ttk.Treeview(tree_frame, columns=columns, show="headings", selectmode="browse")

        self.tree.heading("project_id", text="Project ID")
        self.tree.heading("description", text="Description")
        self.tree.heading("internal_id", text="Internal Project ID")
        self.tree.heading("is_favorite", text="Favorite")

        self.tree.column("project_id", width=160, minwidth=100, anchor=tk.W)
        self.tree.column("description", width=260, minwidth=150, anchor=tk.W)
        self.tree.column("internal_id", width=300, minwidth=200, anchor=tk.W)
        self.tree.column("is_favorite", width=80, minwidth=60, anchor=tk.CENTER)

        scrollbar = ttk.Scrollbar(tree_frame, orient=tk.VERTICAL, command=self.tree.yview)
        self.tree.configure(yscrollcommand=scrollbar.set)

        self.tree.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

    def start_load_projects(self) -> None:
        """Trigger loading of projects in a separate thread."""
        self.load_btn.config(state=tk.DISABLED)
        self.status_var.set("Loading projects from API...")

        thread = threading.Thread(target=self._fetch_projects_worker, daemon=True)
        thread.start()
        self.root.after(100, self._poll_queue)

    def _fetch_projects_worker(self) -> None:
        try:
            payload = {"ProjectsContent": [10]}
            data = self.client.post("Project/GetProjects", payload)
            self.queue.put((data, None))
        except Exception as exc:
            self.queue.put((None, exc))

    def _poll_queue(self) -> None:
        try:
            data, error = self.queue.get_nowait()
            self._on_projects_loaded(data, error)
        except queue.Empty:
            self.root.after(100, self._poll_queue)

    def _on_projects_loaded(self, data: dict[str, Any] | None, error: Exception | None) -> None:
        self.load_btn.config(state=tk.NORMAL)

        if error is not None:
            self.status_var.set(f"Error loading projects: {error}")
            messagebox.showerror("API Error", f"Failed to load projects:\n{error}")
            return

        if not isinstance(data, dict):
            self.status_var.set("Invalid response received from API.")
            messagebox.showerror("Error", "Invalid response received from API.")
            return

        op_result = data.get("operationResult") or {}
        if not op_result.get("successful", False):
            msg = op_result.get("detailedMessage") or op_result.get("shortMessage") or "Request failed"
            self.status_var.set(f"API Error: {msg}")
            messagebox.showerror("Operation Failed", f"API reported failure:\n{msg}")
            return

        # Clear existing items
        for item in self.tree.get_children():
            self.tree.delete(item)

        projects = data.get("projects") or []
        for p in projects:
            proj_id = p.get("projectID", "")
            desc = p.get("description", "")
            internal_id = p.get("internalProjectID", "")
            fav = "Yes" if p.get("isFavorite") else "No"
            self.tree.insert("", tk.END, values=(proj_id, desc, internal_id, fav))

        self.status_var.set(f"Loaded {len(projects)} project(s) successfully.")


def main() -> None:
    parser = argparse.ArgumentParser(description="Start the Tkinter Projects Viewer.")
    parser.add_argument("--api-url", help="Base URL of the Web API")
    args = parser.parse_args()

    config = load_config()
    if args.api_url:
        config.api_url = args.api_url

    client = LbApiClient(config)

    root = tk.Tk()
    app = ProjectsViewerApp(root, client)
    root.mainloop()


if __name__ == "__main__":
    main()
