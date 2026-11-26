import base64, glob, json, os, sys
here = sys.argv[1]
clips = {os.path.basename(p)[:-4]: base64.b64encode(open(p, "rb").read()).decode() for p in sorted(glob.glob(f"{here}/page/audio/*.mp3"))}
t = open(f"{here}/page/template.html").read()
assert "/*CLIPS*/{}/*END*/" in t
out = t.replace("/*CLIPS*/{}/*END*/", json.dumps(clips))
open(f"{here}/page/halfway-sound-options.html", "w").write(out)
print(len(clips), "clips,", round(len(out) / 1e6, 2), "MB page")
for bad in ("—", "–"):
    assert bad not in t, "dash in copy"
