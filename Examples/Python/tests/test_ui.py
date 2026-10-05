"""Unit tests for the Tkinter Projects Viewer UI."""

from __future__ import annotations

import tkinter as tk
from unittest.mock import MagicMock, patch
import pytest

from UI.projects_viewer import ProjectsViewerApp


@pytest.fixture
def tk_root():
    root = tk.Tk()
    root.withdraw()  # Don't show during tests
    yield root
    try:
        root.destroy()
    except Exception:
        pass


def test_ui_initialization(tk_root: tk.Tk) -> None:
    mock_client = MagicMock()
    app = ProjectsViewerApp(tk_root, mock_client)

    assert app.root.title() == "LeegooBuilder Projects Viewer"
    assert len(app.tree["columns"]) == 4
    assert app.tree.get_children() == ()
    assert "Ready" in app.status_var.get()


def test_ui_on_projects_loaded_success(tk_root: tk.Tk) -> None:
    mock_client = MagicMock()
    app = ProjectsViewerApp(tk_root, mock_client)

    test_data = {
        "operationResult": {"successful": True},
        "projects": [
            {
                "projectID": "PRJ-001",
                "description": "First Project",
                "internalProjectID": "uuid-1",
                "isFavorite": True,
            },
            {
                "projectID": "PRJ-002",
                "description": "Second Project",
                "internalProjectID": "uuid-2",
                "isFavorite": False,
            },
        ],
    }

    app._on_projects_loaded(test_data, None)

    children = app.tree.get_children()
    assert len(children) == 2

    first_item = app.tree.item(children[0])["values"]
    assert first_item[0] == "PRJ-001"
    assert first_item[1] == "First Project"
    assert first_item[2] == "uuid-1"
    assert first_item[3] == "Yes"

    second_item = app.tree.item(children[1])["values"]
    assert second_item[0] == "PRJ-002"
    assert second_item[3] == "No"

    assert "Loaded 2 project(s) successfully." in app.status_var.get()


@patch("tkinter.messagebox.showerror")
def test_ui_on_projects_loaded_error(mock_showerror: MagicMock, tk_root: tk.Tk) -> None:
    mock_client = MagicMock()
    app = ProjectsViewerApp(tk_root, mock_client)

    app._on_projects_loaded(None, RuntimeError("Connection timeout"))

    mock_showerror.assert_called_once()
    assert "Connection timeout" in app.status_var.get()
    assert len(app.tree.get_children()) == 0


@patch("tkinter.messagebox.showerror")
def test_ui_on_projects_loaded_api_failure(mock_showerror: MagicMock, tk_root: tk.Tk) -> None:
    mock_client = MagicMock()
    app = ProjectsViewerApp(tk_root, mock_client)

    failed_data = {
        "operationResult": {
            "successful": False,
            "shortMessage": "Access denied",
        }
    }
    app._on_projects_loaded(failed_data, None)

    mock_showerror.assert_called_once()
    assert "Access denied" in app.status_var.get()
