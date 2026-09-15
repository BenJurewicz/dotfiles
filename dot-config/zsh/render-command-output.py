#!/usr/bin/env python3

import re
import sys

raw_bytes = open(sys.argv[1], "rb").read()
capture_limit = int(sys.argv[2])
truncated = len(raw_bytes) >= capture_limit
raw = raw_bytes.decode("utf-8", "replace")

# Operating-system commands (titles, hyperlinks), device-control strings, and
# control-sequence introducers such as colors and cursor movement.
raw = re.sub(r"\x1b\].*?(?:\x07|\x1b\\)", "", raw, flags=re.S)
raw = re.sub(r"\x1b[PX^_].*?\x1b\\", "", raw, flags=re.S)
raw = re.sub(r"\x1b\[[0-?]*[ -/]*[@-~]", "", raw)
raw = re.sub(r"\x1b[ -/]*[@-~]", "", raw)

lines = []
line = []
cursor = 0

for char in raw:
    if char == "\n":
        lines.append("".join(line).rstrip())
        line = []
        cursor = 0
    elif char == "\r":
        cursor = 0
    elif char == "\b":
        cursor = max(0, cursor - 1)
    elif char == "\t" or ord(char) >= 32:
        if cursor < len(line):
            line[cursor] = char
        else:
            line.extend(" " for _ in range(cursor - len(line)))
            line.append(char)
        cursor += 1

if line:
    lines.append("".join(line).rstrip())

while lines and not lines[-1]:
    lines.pop()

if truncated:
    lines.extend(
        ["", f"[output truncated after {capture_limit // (1024 * 1024)} MiB]"]
    )

sys.stdout.write("\n".join(lines))
