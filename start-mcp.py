#!/usr/bin/env python3
"""Serve Skyvern remote MCP on loopback port 8003.

`skyvern run mcp` checks `x-api-key` against the local database, and that
check uses `app.AGENT_FUNCTION`. The CLI does not initialize Forge itself.
Building the full forge graph is unnecessary and, without DATABASE_STRING,
tries to create a SQLite directory on the read-only root filesystem.

Settings read the process environment at import, so DATABASE_STRING must be
present before the Skyvern imports below.
"""

import os
import sys

os.chdir("/opt/skyvern")

if not os.environ.get("DATABASE_STRING"):
    print("DATABASE_STRING is not set", file=sys.stderr)
    raise SystemExit(1)

from skyvern.forge import set_force_app_instance
from skyvern.forge.agent_functions import AgentFunction
from skyvern.forge.forge_app import ForgeApp
from skyvern.__main__ import main as cli_main

forge_app = ForgeApp()
forge_app.AGENT_FUNCTION = AgentFunction()
set_force_app_instance(forge_app)

sys.argv = [
    "skyvern",
    "run",
    "mcp",
    "--transport",
    "streamable-http",
    "--host",
    "127.0.0.1",
    "--port",
    "8003",
    "--path",
    "/mcp",
]
cli_main()
