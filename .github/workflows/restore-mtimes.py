#!/usr/bin/env python3
import os
import subprocess

tracked = set(subprocess.check_output(["git", "ls-files"], text=True).splitlines())
seen = set()
proc = subprocess.Popen(
    ["git", "log", "--pretty=format:%ct", "--name-only", "--no-renames"],
    stdout=subprocess.PIPE,
    text=True,
)

ts = None
for raw in proc.stdout:
    line = raw.rstrip("\n")
    if not line:
        continue
    if line.isdigit():
        ts = int(line)
        continue
    if ts is None or line in seen or line not in tracked:
        continue
    seen.add(line)
    os.utime(line, (ts, ts))

if proc.wait():
    raise SystemExit(proc.returncode)
