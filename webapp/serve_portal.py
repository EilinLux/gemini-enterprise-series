#!/usr/bin/env python3
"""
DoubleClick Enterprise — Local Intranet Web Portal Server (`serve_portal.py`)
=============================================================================
📌 Introduced in: Article 5 (Part 5 — 🛡️ Integration & Security)

Serves `webapp/` on http://localhost:8080 (which we allowlisted in Part 3 via
`google_discovery_engine_widget_config.double_click_widget_config`) so you can
interact with the live `<gen-search-widget>` alongside the Workforce Identity
ACL and Per-User OAuth 2.0 Action Simulator.
"""

import argparse
import functools
import http.server
import os
import socketserver
from pathlib import Path

WEBAPP_DIR = Path(__file__).resolve().parent


def main() -> None:
    parser = argparse.ArgumentParser(description="Serve DoubleClick Enterprise Intranet Portal")
    parser.add_argument(
        "--port",
        type=int,
        default=int(os.environ.get("PORTAL_PORT", "8080")),
        help="Port to serve on (default: 8080)",
    )
    args = parser.parse_args()

    handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(WEBAPP_DIR))
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("", args.port), handler) as httpd:
        print("============================================================================")
        print(f"🌐 DoubleClick Enterprise Intranet Portal running at: http://localhost:{args.port}")
        print("   Press Ctrl+C to stop the server.")
        print("============================================================================")
        httpd.serve_forever()


if __name__ == "__main__":
    main()
