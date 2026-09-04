#!/usr/bin/env python3
import os
import subprocess

files = set(subprocess.check_output(["git", "ls-files"], text=True).splitlines())
seen = set()
log = subprocess.Popen(
    ["git", "log", "--pretty=format:%ct", "--name-only", "--no-renames"],
    stdout=subprocess.PIPE,
    text=True,
)
ts = None
for line in log.stdout:
    line = line.rstrip("\n")
    if ts is None:
        if line:
            ts = int(line)
        continue
    if not line:
        ts = None
        continue
    if line in files and line not in seen:
        seen.add(line)
        os.utime(line, (ts, ts))
log.wait()
