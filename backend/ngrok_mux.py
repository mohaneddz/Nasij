from __future__ import annotations

import argparse
import http.client
import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlsplit


HOP_BY_HOP_HEADERS = {
    "connection",
    "keep-alive",
    "proxy-authenticate",
    "proxy-authorization",
    "te",
    "trailers",
    "transfer-encoding",
    "upgrade",
}


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Path-based HTTP multiplexer for ngrok. Route /<port>/... to localhost:<port>/..."
    )
    parser.add_argument("--port", type=int, default=8099, help="Mux listen port.")
    parser.add_argument(
        "--targets",
        required=True,
        help="Comma-separated list of allowed local ports, e.g. 8101,8102,8103",
    )
    return parser.parse_args()


def _build_handler(allowed_ports: set[int]):
    class MuxHandler(BaseHTTPRequestHandler):
        protocol_version = "HTTP/1.1"

        def _send_json(self, status_code: int, payload: dict) -> None:
            body = json.dumps(payload).encode("utf-8")
            self.send_response(status_code)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def _usage(self) -> None:
            sample_port = sorted(allowed_ports)[0] if allowed_ports else 8101
            self._send_json(
                200,
                {
                    "status": "ok",
                    "message": "Use /<port>/<path> to route to local backend ports.",
                    "example": f"/{sample_port}/health",
                    "allowed_ports": sorted(allowed_ports),
                },
            )

        def _forward(self) -> None:
            split = urlsplit(self.path)
            path = split.path or "/"
            if path == "/":
                self._usage()
                return

            parts = [p for p in path.split("/") if p]
            if not parts:
                self._usage()
                return

            if not parts[0].isdigit():
                self._send_json(
                    400,
                    {
                        "error": "First path segment must be a target port.",
                        "example": "/8101/health",
                    },
                )
                return

            target_port = int(parts[0])
            if target_port not in allowed_ports:
                self._send_json(
                    404,
                    {
                        "error": f"Port {target_port} is not exposed by this mux.",
                        "allowed_ports": sorted(allowed_ports),
                    },
                )
                return

            upstream_path = "/" + "/".join(parts[1:]) if len(parts) > 1 else "/"
            if split.query:
                upstream_path = f"{upstream_path}?{split.query}"

            content_length = int(self.headers.get("Content-Length", "0") or "0")
            body = self.rfile.read(content_length) if content_length > 0 else None

            req_headers = {}
            for key, value in self.headers.items():
                lk = key.lower()
                if lk in HOP_BY_HOP_HEADERS or lk == "host":
                    continue
                req_headers[key] = value
            req_headers["Host"] = f"127.0.0.1:{target_port}"

            try:
                conn = http.client.HTTPConnection("127.0.0.1", target_port, timeout=30)
                conn.request(self.command, upstream_path, body=body, headers=req_headers)
                resp = conn.getresponse()
                payload = resp.read()

                self.send_response(resp.status, resp.reason)
                for key, value in resp.getheaders():
                    lk = key.lower()
                    if lk in HOP_BY_HOP_HEADERS or lk == "content-length":
                        continue
                    self.send_header(key, value)
                self.send_header("Content-Length", str(len(payload)))
                self.end_headers()
                self.wfile.write(payload)
            except Exception as exc:
                self._send_json(
                    502,
                    {
                        "error": "Failed to reach upstream service.",
                        "target_port": target_port,
                        "details": str(exc),
                    },
                )

        def do_GET(self) -> None:
            self._forward()

        def do_POST(self) -> None:
            self._forward()

        def do_PUT(self) -> None:
            self._forward()

        def do_PATCH(self) -> None:
            self._forward()

        def do_DELETE(self) -> None:
            self._forward()

        def do_OPTIONS(self) -> None:
            self._forward()

        def log_message(self, _format: str, *_args) -> None:
            return

    return MuxHandler


def main() -> None:
    args = _parse_args()
    targets = {int(p.strip()) for p in args.targets.split(",") if p.strip()}
    if not targets:
        raise RuntimeError("No target ports provided for ngrok mux.")

    handler = _build_handler(targets)
    server = ThreadingHTTPServer(("127.0.0.1", args.port), handler)
    print(
        f"[ngrok-mux] listening on http://127.0.0.1:{args.port} "
        f"for targets: {sorted(targets)}",
        flush=True,
    )
    server.serve_forever()


if __name__ == "__main__":
    main()
