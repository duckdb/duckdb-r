#!/usr/bin/env python3
"""Accept TCP connections and never answer them.

Stands in for MotherDuck's auth endpoint: DuckDB's HTTP client connects,
sends its request, and then blocks in recv() waiting for a response that
never comes.
"""

import socket
import sys
import threading

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8998

held = []


def handle(conn, addr):
    # Read the request, then hold the socket open forever.
    try:
        conn.recv(65536)
    except OSError:
        pass
    held.append(conn)


srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
srv.bind(("127.0.0.1", PORT))
srv.listen(64)
print(f"hangserver listening on 127.0.0.1:{PORT}", flush=True)

while True:
    conn, addr = srv.accept()
    print(f"connection from {addr}", flush=True)
    threading.Thread(target=handle, args=(conn, addr), daemon=True).start()
