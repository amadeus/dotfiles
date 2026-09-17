"""Implementation for rex-save/rex-restore; snapshots contain no commands."""

import fcntl
import json
import math
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
from urllib.parse import quote


CONFIG = Path(__file__).resolve().parent.parent
SNAPSHOT = CONFIG / ".rex-sessions.tmp.json"
LOG = CONFIG / ".rex-restore.tmp.log"
# Ignore Rex's current target environment: these commands manage the local server.
SERVER = "unix://" + quote(str(Path.home() / "Library/Application Support/rex/server.sock"))
SHELL_FLAVOR = "com.superlogical.terminal.shell"


def require(condition, message):
    if not condition:
        raise ValueError(message)


def api(method, **args):
    result = subprocess.run(
        ["rex", "--server", SERVER, "--autostart=false", "api", "call", method, "-"],
        input=json.dumps(args), text=True, capture_output=True,
    )
    if result.returncode:
        raise RuntimeError(f"{method}: {result.stderr.strip()}")
    return json.loads(result.stdout)


def sessions():
    return api("session.list").get("sessions") or []


def save_layout(node, blocks, session_id):
    if node.get("split"):
        split = node["split"]
        return {"split": {
            "direction": split["direction"], "ratio": split["ratio"],
            "before": save_layout(split["before"], blocks, session_id),
            "after": save_layout(split["after"], blocks, session_id),
        }}
    block = blocks[node["block_id"]]
    require(block.get("creator_name") == "com.superlogical.terminal",
            f"Cannot read a directory for non-terminal pane {block['label']!r}")
    process = api("com.superlogical.terminal.process", session_id=session_id,
                  block_id=block["block_id"], args={})
    # macOS may report `login` as the child; the foreground process has the cwd.
    cwd = ((process.get("foreground") or {}).get("cwd")
           or (process.get("child") or {}).get("cwd"))
    require(cwd, f"Cannot read the current directory for pane {block['label']!r}")
    return {"pane": {"name": block["label"], "cwd": cwd}}


def save():
    initial_sessions = sessions()
    saved = []
    for session in initial_sessions:
        session_id = session["session_id"]
        view = api("session.view", session_id=session_id)
        windows = []
        for window in view.get("windows") or []:
            layers = []
            for layer in window["layers"] or []:
                require(layer["layout"] is not None, "Cannot save an empty layer")
                blocks = {b["block_id"]: b for b in layer["blocks"]}
                layers.append({
                    "kind": layer["kind"], "bounds": layer["bounds"],
                    "layout": save_layout(layer["layout"], blocks, session_id),
                })
            windows.append({"name": window["label"], "layers": layers})
        # Avoid publishing a partial layout when a tab/pane changed during save.
        require(api("session.view", session_id=session_id)["revision"] == view["revision"],
                "The Rex layout changed while saving; run rex-save again")
        saved.append({"name": view["label"], "windows": windows})
    require([s["session_id"] for s in sessions()] == [s["session_id"] for s in initial_sessions],
            "Rex sessions changed while saving; run rex-save again")
    snapshot = {"version": 1, "sessions": saved}
    validate(snapshot)
    fd, temporary = tempfile.mkstemp(prefix=".rex-sessions-", dir=CONFIG)
    try:
        with os.fdopen(fd, "w") as stream:
            json.dump(snapshot, stream, ensure_ascii=False, indent=2)
            stream.write("\n")
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, SNAPSHOT)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)
    print(f"Saved {len(saved)} sessions to {SNAPSHOT}")


def name(value):
    require(isinstance(value, str) and "\0" not in value, "Invalid saved name")


def layout_request(node):
    require(isinstance(node, dict), "Invalid saved layout")
    if set(node) == {"pane"}:
        pane = node["pane"]
        name(pane["name"])
        cwd = pane["cwd"]
        require(isinstance(cwd, str) and os.path.isabs(cwd) and os.path.isdir(cwd),
                f"Saved directory does not exist: {cwd!r}")
        # Construct an allowlist of options: never replay application commands.
        return {"block": {"flavor": SHELL_FLAVOR, "label": pane["name"],
                          "options": {"cwd": cwd}}}
    require(set(node) == {"split"}, "Invalid saved layout node")
    split = node["split"]
    require(split["direction"] in ("horizontal", "vertical"), "Invalid split direction")
    ratio = split["ratio"]
    require(type(ratio) in (float, int) and math.isfinite(ratio) and 0 < ratio < 1,
            "Invalid split ratio")
    return {"split": {
        "direction": split["direction"], "ratio": ratio,
        "before": layout_request(split["before"]),
        "after": layout_request(split["after"]),
    }}


def validate(snapshot):
    require(snapshot["version"] == 1 and isinstance(snapshot["sessions"], list),
            "Invalid Rex snapshot version or sessions")
    for session in snapshot["sessions"]:
        name(session["name"])
        require(isinstance(session["windows"], list), "Invalid saved windows")
        for window in session["windows"]:
            name(window["name"])
            layers = window["layers"]
            require(isinstance(layers, list) and layers and layers[0]["kind"] == "tiled",
                    "Expected a tiled layer in each tab")
            for index, layer in enumerate(layers):
                require(layer["kind"] == ("tiled" if index == 0 else "floating"),
                        "Unsupported Rex layer kind")
                bounds = layer["bounds"]
                require(set(bounds) == {"x", "y", "w", "h"}
                        and all(type(v) in (float, int) and math.isfinite(v)
                                for v in bounds.values()), "Invalid layer bounds")
                x, y, w, h = (bounds[k] for k in ("x", "y", "w", "h"))
                require(x >= 0 and y >= 0 and w > 0 and h > 0
                        and x + w <= 1.000001 and y + h <= 1.000001,
                        "Layer bounds fall outside the window")
                layout_request(layer["layout"])


def restore(snapshot):
    validate(snapshot)
    old = sessions()
    created = []
    try:
        for session in snapshot["sessions"]:
            windows = [{"window_label": w["name"],
                        "layout": layout_request(w["layers"][0]["layout"])}
                       for w in session["windows"]]
            result = api("session.create", label=session["name"], initial_windows=windows)
            session_id = result["session_id"]
            created.append(session_id)
            for window, new in zip(session["windows"], result.get("initial_windows") or []):
                for layer in window["layers"][1:]:
                    api("session.new_layer", session_id=session_id, window_id=new["window_id"],
                        bounds=layer["bounds"], layout=layout_request(layer["layout"]), focus=False)
    except Exception:
        # Creation failed: retain the originals and remove only our replacements.
        for session_id in created:
            try:
                api("session.destroy", session_id=session_id)
            except Exception as error:
                print(f"Could not clean up replacement {session_id}: {error}", file=sys.stderr)
        raise
    for session in old:
        api("session.destroy", session_id=session["session_id"])
    print(f"Restored {len(created)} sessions with fresh shells.", flush=True)


def main():
    require(shutil.which("rex"), "rex is not available in PATH")
    action = sys.argv[1]
    if action == "restore":
        with SNAPSHOT.open() as stream:
            snapshot = json.load(stream)
        validate(snapshot)
        api("server.status")
        # Independent process and stdio survive closing the invoking Rex pane.
        fd = os.open(LOG, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
        with os.fdopen(fd, "w") as log:
            worker = subprocess.Popen(
                [sys.executable, str(Path(__file__).resolve()), "restore-worker"],
                stdin=subprocess.PIPE, stdout=log, stderr=log, text=True,
                start_new_session=True,
            )
            worker.stdin.write(json.dumps(snapshot))
            worker.stdin.close()
        print(f"Restore started (PID {worker.pid}). Status: {LOG}")
        return
    with open(CONFIG / ".rex-snapshot.tmp.lock", "a") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise RuntimeError("Another Rex save/restore is running") from None
        if action == "save":
            save()
        elif action == "restore-worker":
            restore(json.load(sys.stdin))
        else:
            raise ValueError("usage: rex-snapshot.py save|restore")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, KeyError, TypeError, RuntimeError, RecursionError) as error:
        print(f"rex-snapshot: {error}", file=sys.stderr, flush=True)
        sys.exit(1)
