"""Smoke and invocation tests for endpoint scripts."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path
import pytest


PYTHON_ROOT = Path(__file__).resolve().parents[1]
PYTHON_EXE = sys.executable


@pytest.mark.parametrize(
    "script_rel_path,extra_args",
    [
        ("Authentication/100.login.py", ["--help"]),
        ("Authentication/110.load_login_infos.py", ["--help"]),
        ("Project/200.get_projects.py", ["--help"]),
        ("Project/220.get_project.py", ["--help"]),
        ("Proposal/210.get_proposals.py", ["--help"]),
        ("Proposal/230.get_proposal.py", ["--help"]),
        ("CompaniesAndPersons/300.load_company.py", ["--help"]),
        ("CompaniesAndPersons/310.load_companies.py", ["--help"]),
        ("CompaniesAndPersons/350.create_company.py", ["--help"]),
        ("CompaniesAndPersons/360.modify_company.py", ["--help"]),
        ("CompaniesAndPersons/400.load_person.py", ["--help"]),
        ("CompaniesAndPersons/410.load_persons.py", ["--help"]),
        ("CompaniesAndPersons/450.create_person.py", ["--help"]),
        ("CompaniesAndPersons/460.modify_person.py", ["--help"]),
        ("UI/projects_viewer.py", ["--help"]),
    ],
)
def test_script_help_flag(script_rel_path: str, extra_args: list[str]) -> None:
    script_path = PYTHON_ROOT / script_rel_path
    cmd = [PYTHON_EXE, str(script_path)] + extra_args
    res = subprocess.run(cmd, capture_output=True, text=True)
    assert res.returncode == 0, f"Error running {script_rel_path} --help: {res.stderr}"
    assert "usage:" in res.stdout.lower()
