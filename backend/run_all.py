from __future__ import annotations

import argparse
import json
import os
import re
import signal
import subprocess
import sys
import time
import urllib.request
from dataclasses import dataclass
from pathlib import Path

DEFAULT_PORTS: dict[str, int] = {
    "01_traceability_alerts": 8101,
    "02_photo_verification": 8102,
    "03_translation": 8103,
    "04_matching_recommendation": 8104,
    "05_forecasting_tool": 8105,
    "06_sheep_breed_classifier": 8106,
    "07_wool_on_skin_classifier": 8107,
    "08_wool_cv": 8108,
    "09_wool_ml": 8109,
}

DISPLAY_NAME_OVERRIDES: dict[str, str] = {
    "07_wool_on_skin_classifier": "07_wool_on_skin_classifier",
    "08_wool_cv": "08_wool_cv",
    "09_wool_ml": "09_wool_ml",
}
EXCLUDED_SERVICES = {
    "08_wool_booster_classifier",
}
MAX_SERVICE_RESTARTS = 2


@dataclass
class ServiceRuntime:
    name: str
    port: int
    proc: subprocess.Popen
    restarts: int = 0


def snapshot_python_files(base: Path) -> dict[str, int]:
    snapshot: dict[str, int] = {}
    for file_path in base.rglob("*.py"):
        parts = set(file_path.parts)
        if "__pycache__" in parts or ".venv" in parts or "venv" in parts:
            continue
        try:
            snapshot[str(file_path)] = file_path.stat().st_mtime_ns
        except FileNotFoundError:
            continue
    return snapshot


def diff_python_snapshots(
    old: dict[str, int],
    new: dict[str, int],
) -> list[str]:
    changes: list[str] = []
    all_paths = set(old) | set(new)
    for path in sorted(all_paths):
        if old.get(path) != new.get(path):
            changes.append(path)
    return changes


def discover_services(base: Path) -> tuple[list[tuple[str, int]], list[str]]:
    services: list[tuple[str, int]] = []
    skipped: list[str] = []
    used_ports = set(DEFAULT_PORTS.values())
    next_port = max(DEFAULT_PORTS.values()) + 1

    for folder in sorted(base.iterdir(), key=lambda p: p.name):
        if not folder.is_dir() or not re.match(r"^\d+_.+", folder.name):
            continue
        if folder.name in EXCLUDED_SERVICES:
            skipped.append(folder.name)
            continue
        if not (folder / "app" / "main.py").exists():
            skipped.append(folder.name)
            continue

        port = DEFAULT_PORTS.get(folder.name)
        if port is None:
            while next_port in used_ports:
                next_port += 1
            port = next_port
            used_ports.add(port)
            next_port += 1
        services.append((folder.name, port))

    return services, skipped


def start_service(base: Path, service: str, port: int) -> subprocess.Popen:
    cwd = base / service
    cmd = [sys.executable, "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", str(port)]
    return subprocess.Popen(cmd, cwd=cwd)


def start_services(services: list[tuple[str, int]]) -> list[ServiceRuntime]:
    base = Path(__file__).resolve().parent
    runtimes: list[ServiceRuntime] = []
    for service, port in services:
        display_name = DISPLAY_NAME_OVERRIDES.get(service, service)
        print(f"Starting {display_name} on port {port}")
        proc = start_service(base, service, port)
        runtimes.append(ServiceRuntime(name=service, port=port, proc=proc))
        time.sleep(0.4)
    return runtimes


def start_ngrok_mux(mux_port: int, target_ports: list[int], base_dir: Path) -> subprocess.Popen:
    targets_arg = ",".join(str(p) for p in sorted(set(target_ports)))
    cmd = [sys.executable, "ngrok_mux.py", "--port", str(mux_port), "--targets", targets_arg]
    print(f"Starting ngrok mux on port {mux_port} for targets: {targets_arg}")
    return subprocess.Popen(cmd, cwd=base_dir)


def wait_for_url(url: str, timeout_seconds: int = 15) -> bool:
    deadline = time.time() + timeout_seconds
    while time.time() < deadline:
        try:
            with urllib.request.urlopen(url, timeout=1.5):
                return True
        except Exception:
            time.sleep(0.4)
    return False


def stop_process(proc: subprocess.Popen | None) -> None:
    if proc is None or proc.poll() is not None:
        return
    proc.terminate()
    try:
        proc.wait(timeout=5)
    except subprocess.TimeoutExpired:
        proc.kill()


def stop_services(runtimes: list[ServiceRuntime]) -> None:
    for runtime in runtimes:
        stop_process(runtime.proc)


def upsert_env_var(path: Path, key: str, value: str) -> None:
    lines: list[str] = []
    if path.exists():
        lines = path.read_text(encoding="utf-8").splitlines()

    replaced = False
    for idx, line in enumerate(lines):
        if line.strip().startswith(f"{key}="):
            lines[idx] = f"{key}={value}"
            replaced = True
            break

    if not replaced:
        lines.append(f"{key}={value}")

    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def start_ngrok(port: int, domain: str = "", authtoken: str = "") -> subprocess.Popen:
    if authtoken:
        subprocess.run(["ngrok", "config", "add-authtoken", authtoken], check=False)

    cmd = ["ngrok", "http", str(port)]
    if domain:
        cmd.extend(["--domain", domain])
    print(f"Starting ngrok tunnel on port {port}")
    return subprocess.Popen(cmd)


def get_ngrok_tunnel_info(expected_addr: str = "") -> tuple[str, str]:
    try:
        with urllib.request.urlopen("http://127.0.0.1:4040/api/tunnels", timeout=1.5) as resp:
            payload = json.loads(resp.read().decode("utf-8"))
        tunnels = payload.get("tunnels", [])
        if expected_addr:
            for tunnel in tunnels:
                url = tunnel.get("public_url", "")
                addr = tunnel.get("config", {}).get("addr", "")
                if url.startswith("https://") and addr in {expected_addr, expected_addr.replace("localhost", "127.0.0.1")}:
                    return url, addr
        for tunnel in tunnels:
            url = tunnel.get("public_url", "")
            if url.startswith("https://"):
                addr = tunnel.get("config", {}).get("addr", "")
                return url, addr
    except Exception:
        pass
    return "", ""


def wait_for_ngrok_url(expected_addr: str = "", timeout_seconds: int = 20) -> tuple[str, str]:
    deadline = time.time() + timeout_seconds
    while time.time() < deadline:
        url, addr = get_ngrok_tunnel_info(expected_addr=expected_addr)
        if url:
            return url, addr
        time.sleep(0.6)
    return "", ""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run all AI microservices and expose them via one ngrok URL using /<port>/... routing."
    )
    parser.add_argument(
        "--with-ngrok",
        action="store_true",
        help="Deprecated. ngrok is enabled by default.",
    )
    parser.add_argument(
        "--no-ngrok",
        action="store_true",
        help="Disable ngrok startup.",
    )
    parser.add_argument(
        "--ngrok-port",
        type=int,
        default=8099,
        help="Local ngrok-mux port to expose through ngrok (default: 8099).",
    )
    parser.add_argument(
        "--ngrok-domain",
        default="",
        help="Optional reserved ngrok domain.",
    )
    parser.add_argument(
        "--ngrok-authtoken",
        default=os.getenv("NGROK_AUTHTOKEN", ""),
        help="Optional ngrok authtoken (defaults to NGROK_AUTHTOKEN env var).",
    )
    parser.add_argument(
        "--link-env",
        action="store_true",
        help="Deprecated. env linking is enabled by default when ngrok is enabled.",
    )
    parser.add_argument(
        "--no-link-env",
        action="store_true",
        help="Disable writing NGROK_URL/VITE_API_URL to project env files.",
    )
    parser.add_argument(
        "--show-skipped",
        action="store_true",
        help="Print non-runnable numbered modules (no app/main.py).",
    )
    parser.add_argument(
        "--watch",
        action="store_true",
        help="Watch backend Python files and restart services/mux when they change.",
    )
    parser.add_argument(
        "--watch-interval",
        type=float,
        default=1.0,
        help="Seconds between watch checks (default: 1.0).",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    enable_ngrok = not args.no_ngrok
    link_env = enable_ngrok and not args.no_link_env
    base = Path(__file__).resolve().parent
    services, skipped = discover_services(base)
    if skipped and args.show_skipped:
        print(f"Skipping non-runnable modules (no app/main.py): {', '.join(skipped)}")
    if not services:
        raise RuntimeError("No runnable services found under backend.")

    runtimes = start_services(services)
    ngrok_proc: subprocess.Popen | None = None
    ngrok_mux_proc: subprocess.Popen | None = None
    ngrok_url = ""

    def _handle_signal(_sig: int, _frame: object) -> None:
        stop_process(ngrok_proc)
        stop_process(ngrok_mux_proc)
        stop_services(runtimes)
        sys.exit(0)

    signal.signal(signal.SIGINT, _handle_signal)
    signal.signal(signal.SIGTERM, _handle_signal)

    if enable_ngrok:
        expected_addr = f"http://localhost:{args.ngrok_port}"
        target_ports = [port for _, port in services]
        ngrok_mux_proc = start_ngrok_mux(args.ngrok_port, target_ports, base)
        if not wait_for_url(f"http://127.0.0.1:{args.ngrok_port}/", timeout_seconds=15):
            raise RuntimeError(f"ngrok mux failed to start on port {args.ngrok_port}.")

        ngrok_url, ngrok_addr = get_ngrok_tunnel_info(expected_addr=expected_addr)
        if ngrok_url:
            print(f"Using existing ngrok tunnel: {ngrok_url} -> {ngrok_addr or 'unknown'}")
        else:
            ngrok_proc = start_ngrok(
                port=args.ngrok_port,
                domain=args.ngrok_domain,
                authtoken=args.ngrok_authtoken,
            )
            ngrok_url, ngrok_addr = wait_for_ngrok_url(expected_addr=expected_addr)

        if ngrok_url:
            print(f"ngrok public URL: {ngrok_url}")
            print(f"Routing format: {ngrok_url}/<port>/...")
            print(f"Example service health: {ngrok_url}/8101/health")
            if ngrok_addr and ngrok_addr not in {expected_addr, f"http://127.0.0.1:{args.ngrok_port}"}:
                print(
                    f"Warning: current ngrok tunnel points to {ngrok_addr}, expected {expected_addr}. "
                    "Use --no-ngrok or stop existing ngrok and rerun if needed."
                )
            if link_env:
                repo_root = Path(__file__).resolve().parents[1]
                targets = [
                    (repo_root / "nasij-web" / "nfn-backend" / ".env", "NGROK_URL"),
                    (repo_root / "nasij" / "backend" / ".env", "NGROK_URL"),
                    (repo_root / "nasij-web" / "nfn-dashboard" / ".env", "VITE_API_URL"),
                ]
                for env_path, key in targets:
                    value = ngrok_url if key != "VITE_API_URL" else f"{ngrok_url}/8101/api"
                    upsert_env_var(env_path, key, value)
                    print(f"Updated {env_path} -> {key}")
        else:
            print("Warning: could not fetch ngrok public URL from http://127.0.0.1:4040")

    if args.watch:
        print(f"Watch mode enabled (interval={args.watch_interval:.2f}s).")
    print("All services started. Press Ctrl+C to stop.")
    py_snapshot = snapshot_python_files(base)
    try:
        while True:
            for runtime in runtimes:
                code = runtime.proc.poll()
                if code is None:
                    continue
                display_name = DISPLAY_NAME_OVERRIDES.get(runtime.name, runtime.name)
                if runtime.restarts < MAX_SERVICE_RESTARTS:
                    runtime.restarts += 1
                    print(
                        f"Warning: {display_name} exited with code {code}. "
                        f"Restarting ({runtime.restarts}/{MAX_SERVICE_RESTARTS})..."
                    )
                    runtime.proc = start_service(base, runtime.name, runtime.port)
                    continue
                raise RuntimeError(
                    f"Service {display_name} crashed with code {code} after {MAX_SERVICE_RESTARTS} restart attempts."
                )
            if ngrok_mux_proc is not None and ngrok_mux_proc.poll() is not None:
                raise RuntimeError(f"ngrok mux exited unexpectedly with code {ngrok_mux_proc.returncode}.")
            if ngrok_proc is not None and ngrok_proc.poll() is not None:
                raise RuntimeError(f"ngrok exited unexpectedly with code {ngrok_proc.returncode}.")

            if args.watch:
                new_snapshot = snapshot_python_files(base)
                changed_paths = diff_python_snapshots(py_snapshot, new_snapshot)
                if changed_paths:
                    rel_changed = [str(Path(p).relative_to(base)) for p in changed_paths[:8]]
                    suffix = " ..." if len(changed_paths) > 8 else ""
                    print(f"Detected {len(changed_paths)} Python file change(s): {', '.join(rel_changed)}{suffix}")
                    print("Restarting backend services to apply changes...")

                    stop_services(runtimes)

                    services, skipped = discover_services(base)
                    if skipped and args.show_skipped:
                        print(f"Skipping non-runnable modules (no app/main.py): {', '.join(skipped)}")
                    if not services:
                        raise RuntimeError("No runnable services found under backend after reload.")
                    runtimes = start_services(services)

                    if enable_ngrok:
                        stop_process(ngrok_mux_proc)
                        target_ports = [port for _, port in services]
                        ngrok_mux_proc = start_ngrok_mux(args.ngrok_port, target_ports, base)
                        if not wait_for_url(f"http://127.0.0.1:{args.ngrok_port}/", timeout_seconds=15):
                            raise RuntimeError(f"ngrok mux failed to restart on port {args.ngrok_port}.")
                        if ngrok_url:
                            print(f"Public ngrok routing refreshed at {ngrok_url}/<port>/...")

                    py_snapshot = new_snapshot

            time.sleep(max(0.2, args.watch_interval))
    except KeyboardInterrupt:
        pass
    finally:
        stop_process(ngrok_proc)
        stop_process(ngrok_mux_proc)
        stop_services(runtimes)


if __name__ == "__main__":
    main()
