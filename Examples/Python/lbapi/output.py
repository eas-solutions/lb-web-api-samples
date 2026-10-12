"""Result formatter and printer mirroring Write-LbApiResult.ps1."""

from __future__ import annotations

import json
import sys
from typing import Any, TextIO


RED = "\033[91m"
RESET = "\033[0m"


def is_successful(data: Any) -> bool:
    """Check if the API result represents a success."""
    if isinstance(data, dict):
        op = data.get("operationResult")
        if isinstance(op, dict) and "successful" in op:
            return bool(op.get("successful", False))
        if "successful" in data:
            return bool(data.get("successful", False))
    return True


def format_result(value: Any, indent: int = 0) -> str:
    """Format API result JSON with compressed formatting for large lists (>5 items)."""
    pad = "  " * indent
    child_pad = "  " * (indent + 1)

    if value is None:
        return "null"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False)

    if isinstance(value, list):
        if not value:
            return "[]"
        if len(value) > 5:
            lines = [f"{child_pad}{json.dumps(item, ensure_ascii=False)}" for item in value]
            return "[\n" + ",\n".join(lines) + f"\n{pad}]"
        lines = [f"{child_pad}{format_result(item, indent + 1)}" for item in value]
        return "[\n" + ",\n".join(lines) + f"\n{pad}]"

    if isinstance(value, dict):
        if not value:
            return "{}"
        lines = []
        for k, v in value.items():
            formatted_v = format_result(v, indent + 1)
            lines.append(f'{child_pad}"{k}": {formatted_v}')
        return "{\n" + ",\n".join(lines) + f"\n{pad}" + "}"

    return json.dumps(str(value), ensure_ascii=False)


def print_result(data: Any, stream: TextIO | None = None) -> None:
    """Pretty-print API result; failures are printed in red."""
    out = stream if stream is not None else sys.stdout
    success = is_successful(data)
    text = format_result(data)
    if not success:
        text = f"{RED}{text}{RESET}"
    try:
        print(text, file=out)
    except UnicodeEncodeError:
        encoding = getattr(out, "encoding", None) or "utf-8"
        encoded = text.encode(encoding, errors="replace").decode(encoding)
        print(encoded, file=out)
