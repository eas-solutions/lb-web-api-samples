"""Live API end-to-end integration tests for all sample scripts against localhost."""

from __future__ import annotations

import json
import os
from pathlib import Path
import subprocess
import sys
import time
import tkinter as tk
import pytest
import requests

from lbapi import TokenManager, load_config
from UI.projects_viewer import ProjectsViewerApp


PYTHON_ROOT = Path(__file__).resolve().parents[1]
PYTHON_EXE = sys.executable


def is_api_running() -> bool:
    try:
        r = requests.get("http://localhost:56540/api/Authentication/Validate", timeout=2)
        return r.status_code in (200, 401)
    except Exception:
        return False


pytestmark = pytest.mark.skipif(not is_api_running(), reason="Live Web API is not reachable at localhost:56540")


def run_script(rel_path: str, *args: str) -> dict:
    script_path = PYTHON_ROOT / rel_path
    cmd = [PYTHON_EXE, str(script_path)] + list(args)
    env = os.environ.copy()
    env["PYTHONIOENCODING"] = "utf-8"
    res = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", env=env, check=True)
    # Filter ANSI escape codes if present
    cleaned = res.stdout.replace("\033[91m", "").replace("\033[0m", "")
    return json.loads(cleaned)


def test_live_authentication_flow() -> None:
    # 100.login.py
    data_login = run_script("Authentication/100.login.py")
    assert data_login["operationResult"]["successful"] is True
    assert "token" in data_login["user"]
    assert data_login["user"]["tokenExpiration"] is not None

    # 110.load_login_infos.py
    data_infos = run_script("Authentication/110.load_login_infos.py")
    assert data_infos["operationResult"]["successful"] is True
    assert len(data_infos.get("availableCultures", [])) > 0
    assert len(data_infos.get("availableLanguages", [])) > 0


def test_live_projects_flow() -> None:
    # 200.get_projects.py unfiltered
    data_projects = run_script("Project/200.get_projects.py")
    assert data_projects["operationResult"]["successful"] is True
    projects = data_projects.get("projects") or []
    assert len(projects) > 0
    first_id = projects[0]["internalProjectID"]

    # 200.get_projects.py with --name filter
    data_filtered = run_script("Project/200.get_projects.py", "--name", "Demo")
    assert data_filtered["operationResult"]["successful"] is True
    for p in data_filtered.get("projects") or []:
        assert "demo" in (p.get("description") or "").lower() or "demo" in (p.get("projectID") or "").lower()

    # 220.get_project.py default (first project)
    data_proj_default = run_script("Project/220.get_project.py")
    assert data_proj_default["operationResult"]["successful"] is True
    assert data_proj_default["project"]["internalProjectID"] == first_id

    # 220.get_project.py with explicit --project-id
    data_proj_explicit = run_script("Project/220.get_project.py", "--project-id", first_id)
    assert data_proj_explicit["operationResult"]["successful"] is True
    assert data_proj_explicit["project"]["internalProjectID"] == first_id


def test_live_proposals_flow() -> None:
    # 210.get_proposals.py
    data_proposals = run_script("Proposal/210.get_proposals.py")
    assert data_proposals["operationResult"]["successful"] is True
    proposals = data_proposals.get("proposals") or []
    assert len(proposals) > 0
    first_prop_id = proposals[0]["internalProposalID"]

    # 230.get_proposal.py default
    data_prop_default = run_script("Proposal/230.get_proposal.py")
    assert data_prop_default["operationResult"]["successful"] is True
    assert data_prop_default["proposal"]["internalProposalID"] == first_prop_id

    # 230.get_proposal.py explicit
    data_prop_explicit = run_script("Proposal/230.get_proposal.py", "--proposal-id", first_prop_id)
    assert data_prop_explicit["operationResult"]["successful"] is True
    assert data_prop_explicit["proposal"]["internalProposalID"] == first_prop_id


def test_live_companies_and_persons_flow() -> None:
    # 310.load_companies.py
    data_companies = run_script("CompaniesAndPersons/310.load_companies.py")
    assert data_companies["operationResult"]["successful"] is True

    # 350.create_company.py
    data_created_co = run_script("CompaniesAndPersons/350.create_company.py", "--name", "Test Co Live", "--company-id", "LiveCoTest")
    assert data_created_co["operationResult"]["successful"] is True
    company_id = data_created_co["company"]["internalCompanyID"]
    assert company_id is not None

    # 300.load_company.py
    data_loaded_co = run_script("CompaniesAndPersons/300.load_company.py", "--id", company_id)
    assert data_loaded_co["operationResult"]["successful"] is True
    assert data_loaded_co["company"]["name1"] == "Test Co Live"

    # 360.modify_company.py
    data_mod_co = run_script("CompaniesAndPersons/360.modify_company.py", "--id", company_id, "--name", "Test Co Live Modified")
    assert data_mod_co["operationResult"]["successful"] is True
    assert data_mod_co["company"]["name1"] == "Test Co Live Modified"

    # 450.create_person.py
    data_created_person = run_script("CompaniesAndPersons/450.create_person.py", "--company-id", company_id, "--name", "Alice Tester", "--person-id", "Alice1")
    assert data_created_person["operationResult"]["successful"] is True
    person_id = data_created_person["person"]["internalPersonID"]
    assert person_id is not None

    # 400.load_person.py
    data_loaded_person = run_script("CompaniesAndPersons/400.load_person.py", "--id", person_id)
    assert data_loaded_person["operationResult"]["successful"] is True
    assert data_loaded_person["person"]["name"] == "Alice Tester"

    # 410.load_persons.py
    data_persons = run_script("CompaniesAndPersons/410.load_persons.py", "--company-id", company_id)
    assert data_persons["operationResult"]["successful"] is True
    person_list = data_persons.get("persons", {}).get("value") or []
    assert any(p.get("internalPersonID") == person_id for p in person_list)

    # 460.modify_person.py
    data_mod_person = run_script("CompaniesAndPersons/460.modify_person.py", "--id", person_id, "--name", "Alice Tester Modified")
    assert data_mod_person["operationResult"]["successful"] is True
    assert data_mod_person["person"]["name"] == "Alice Tester Modified"


def test_live_token_manager_behavior() -> None:
    cfg = load_config()
    tm = TokenManager(cfg)

    # 1. Fresh login gets token and saves cache
    token1 = tm.get_token(force_refresh=True)
    assert token1 is not None

    cache = tm.load_cache()
    assert cache is not None
    assert cache["token"] == token1

    # 2. Second get_token reuses cached token without login call
    token2 = tm.get_token()
    assert token2 == token1

    # 3. Corrupt cached token forces renewal/re-login
    tm.save_cache("corrupt.fake.token", "corrupt_renewal")
    token3 = tm.get_token()
    assert token3 != "corrupt.fake.token"
    assert tm.validate_token(token3) is True


def test_live_ui_loading() -> None:
    root = tk.Tk()
    root.withdraw()
    try:
        app = ProjectsViewerApp(root)
        app.start_load_projects()
        # Wait for background thread to post result via queue
        for _ in range(50):
            root.update()
            if len(app.tree.get_children()) > 0:
                break
            time.sleep(0.1)
        assert len(app.tree.get_children()) > 0
        assert "Loaded" in app.status_var.get()
    finally:
        root.destroy()
