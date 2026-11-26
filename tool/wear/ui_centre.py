# ui_centre.py <text>: reads a `uiautomator dump` on stdin and prints "x y", the centre of
# the first node whose text is exactly <text>. Used by release_smoke.sh to tap a control by
# the words on it. (The dump is ONE line of XML: do not try to split it with tr or sed on
# macOS, parse it.)
import re
import sys
import xml.etree.ElementTree as ET

want = sys.argv[1]
try:
    root = ET.fromstring(sys.stdin.read())
except ET.ParseError:
    sys.exit(0)
for node in root.iter("node"):
    if node.get("text") == want:
        m = re.match(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", node.get("bounds", ""))
        if m:
            x1, y1, x2, y2 = map(int, m.groups())
            print((x1 + x2) // 2, (y1 + y2) // 2)
            break
