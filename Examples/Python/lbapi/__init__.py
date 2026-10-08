"""LeegooBuilder Web API client package."""

import sys

# Ensure UTF-8 console output across all platforms
if hasattr(sys.stdout, "reconfigure"):
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass
if hasattr(sys.stderr, "reconfigure"):
    try:
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

from .config import Config, load_config
from .token_manager import TokenManager
from .client import LbApiClient
from .output import print_result, format_result, is_successful

__all__ = [
    "Config",
    "load_config",
    "TokenManager",
    "LbApiClient",
    "print_result",
    "format_result",
    "is_successful",
]
