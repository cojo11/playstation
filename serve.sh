#!/bin/sh
set -eu
cd "$(dirname "$0")"
PORT="${AFTERGLOW_PORT:-8000}"

exec python3 - "$PORT" <<'PY'
import sys
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

class Handler(SimpleHTTPRequestHandler):
    extensions_map = {
        **SimpleHTTPRequestHandler.extensions_map,
        ".js": "text/javascript",
        ".css": "text/css",
        ".bin": "application/octet-stream",
        ".appcache": "text/cache-manifest",
    }
    CACHEABLE = (".png", ".jpg", ".jpeg", ".gif", ".webp", ".ico")
    def end_headers(self):
        p = self.path.split("?")[0].lower()
        if p.endswith(self.CACHEABLE):
            self.send_header("Cache-Control", "public, max-age=604800")
        else:
            self.send_header("Cache-Control", "no-cache, must-revalidate")
        super().end_headers()
    def log_message(self, fmt, *args):
        sys.stderr.write("%s %s\n" % (self.address_string(), fmt % args))

port = int(sys.argv[1])
server = ThreadingHTTPServer(("0.0.0.0", port), partial(Handler, directory="."))
print("afterglow on http://0.0.0:%d/  (ctrl-c to stop)" % port, flush=True)
try:
    server.serve_forever()
except KeyboardInterrupt:
    pass
PY
