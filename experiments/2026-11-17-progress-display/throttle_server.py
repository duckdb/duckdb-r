# Serves one directory over HTTP with Range support, throttled to a fixed
# number of bytes per second per response, so that httpfs reads a "remote"
# file slowly.
#
# Usage: python3 -I throttle_server.py <dir> <port> <bytes_per_second>
#
# Part of experiments/2026-11-17-progress-display/, see README.md there.

import http.server
import os
import re
import sys
import time

root, port, rate = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])


class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def _resolve(self):
        path = os.path.join(root, os.path.basename(self.path.split("?")[0]))
        return path if os.path.isfile(path) else None

    def do_HEAD(self):
        path = self._resolve()
        if path is None:
            self.send_error(404)
            return
        self.send_response(200)
        self.send_header("Content-Length", str(os.path.getsize(path)))
        self.send_header("Accept-Ranges", "bytes")
        self.end_headers()

    def do_GET(self):
        path = self._resolve()
        if path is None:
            self.send_error(404)
            return
        size = os.path.getsize(path)
        start, end = 0, size - 1
        m = re.match(r"bytes=(\d+)-(\d*)", self.headers.get("Range", ""))
        if m:
            start = int(m.group(1))
            if m.group(2):
                end = min(int(m.group(2)), size - 1)
            self.send_response(206)
            self.send_header("Content-Range", f"bytes {start}-{end}/{size}")
        else:
            self.send_response(200)
        length = end - start + 1
        self.send_header("Content-Length", str(length))
        self.send_header("Accept-Ranges", "bytes")
        self.end_headers()
        chunk = max(rate // 20, 1)
        with open(path, "rb") as f:
            f.seek(start)
            left = length
            while left > 0:
                data = f.read(min(chunk, left))
                if not data:
                    break
                self.wfile.write(data)
                left -= len(data)
                time.sleep(len(data) / rate)


http.server.ThreadingHTTPServer(("127.0.0.1", port), Handler).serve_forever()
