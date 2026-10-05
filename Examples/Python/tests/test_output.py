"""Unit tests for lbapi.output."""

from __future__ import annotations

import io
from lbapi.output import format_result, is_successful, print_result, RED, RESET


def test_is_successful() -> None:
    assert is_successful({"operationResult": {"successful": True}}) is True
    assert is_successful({"operationResult": {"successful": False}}) is False
    assert is_successful({"successful": True}) is True
    assert is_successful({"successful": False}) is False
    assert is_successful({}) is True


def test_format_result_primitives() -> None:
    assert format_result(None) == "null"
    assert format_result(True) == "true"
    assert format_result(False) == "false"
    assert format_result(42) == "42"
    assert format_result("hello") == '"hello"'


def test_format_result_compact_list() -> None:
    # Lists <= 5 items are multi-line indented
    short_list = [1, 2, 3]
    formatted_short = format_result(short_list)
    assert "\n" in formatted_short

    # Lists > 5 items print each item compact on one line
    long_list = [{"id": i, "name": f"item{i}"} for i in range(7)]
    formatted_long = format_result(long_list)
    lines = [line.strip() for line in formatted_long.splitlines() if line.strip() and line.strip() not in ("[", "]")]
    assert len(lines) == 7
    for line in lines:
        assert line.startswith("{")
        assert line.rstrip(",").endswith("}")


def test_print_result_success_and_failure() -> None:
    stream = io.StringIO()
    print_result({"operationResult": {"successful": True}}, stream=stream)
    out = stream.getvalue()
    assert RED not in out
    assert '"successful": true' in out

    stream_err = io.StringIO()
    print_result({"operationResult": {"successful": False}}, stream=stream_err)
    out_err = stream_err.getvalue()
    assert out_err.startswith(RED)
    assert out_err.rstrip().endswith(RESET)
