"""Verify literal/<slug>/{setup,env,run}.sh against the README they claim to copy (rules: literal/RULES.md).

    python literal_check.py [slug ...]     # default: every literal/<slug>/

Every command line must carry one tag; cited lines are fetched from GitHub at the pinned commit and the
command must appear there verbatim (whitespace and a shell prompt aside). Prints one line per problem and
exits 1 if there are any.
"""
import functools
import pathlib
import re
import sys
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parent
LIT = ROOT / "literal"
HEADER = re.compile(r"^# literal: (\S+/\S+) @ ([0-9a-f]{40})$", re.M)
TAG = re.compile(r"\s+#\s*(glue\b.*|prereq\b.*|placeholder\b.*|[\w./-]+:L\d+(?:-L\d+)?)\s*$")
CITE = re.compile(r"^([\w./-]+):L(\d+)(?:-L(\d+))?$")
GLUE_OK = [
    r"set -e", r"cd \S+", r"mkdir -p \S+", r"source /work/\.venv/bin/activate",
    r"nohup .+ > /work/server\.log 2>&1 &",
    r"for i in \$\(seq 1 \d+\); do curl -s\S* .+ && break; sleep \d+; done",
]
PREREQ_OK = [
    r"apt-get update", r"apt-get install -y [\w.+\- ]+", r"(DEBIAN_FRONTEND=noninteractive )?apt-get install -y [\w.+\- ]+",
    r"uv venv --python [\d.]+ /work/\.venv", r"source /work/\.venv/bin/activate",
    r"curl -[\w]+ \S+ (-o|>) \S+", r"bash \S+\.sh -b -p \S+", r"source \S+/(etc/profile\.d/conda\.sh|bin/activate)",
    r"curl -[\w]+ https://deb\.nodesource\.com/\S+ \| (sudo -E )?bash -?", r"curl -[\w]+ \S+ \| (sudo )?(ba)?sh(\s.*)?",
    r"(\S+/)?conda (init|config) .+", r"export PATH=\S+",
]


def norm(s):
    s = s.replace("\\\n", " ")
    s = re.sub(r"`{1,3}", " ", s)
    s = re.sub(r"(^|\n)\s*(\$|>|%|#\s*\$)\s+", r"\1", s)
    return re.sub(r"\s+", " ", s).strip()


@functools.lru_cache(maxsize=None)
def fetch(repo, sha, path):
    url = f"https://raw.githubusercontent.com/{repo}/{sha}/{path}"
    with urllib.request.urlopen(url, timeout=60) as r:
        return r.read().decode("utf-8", "replace").split("\n")


def cited_text(repo, sha, cite):
    m = CITE.match(cite)
    if not m:
        raise ValueError(f"bad citation {cite!r}")
    path, a = m.group(1), int(m.group(2))
    b = int(m.group(3) or a)
    lines = fetch(repo, sha, path)
    if not (1 <= a <= b <= len(lines)) or b - a > 12:
        raise ValueError(f"{cite}: outside the file or more than 12 lines")
    return norm("\n".join(lines[a - 1:b]))


def check_file(slug, f, repo, sha):
    probs = []
    lines = f.read_text(encoding="utf-8").split("\n")
    for no, line in enumerate(lines, 1):
        s = line.strip()
        where = f"{slug}/{f.name}:{no}"
        if not s or s.startswith("#!"):
            continue
        if s.startswith("#"):
            m = re.match(r"#\s*(skip|=)\s+([\w./-]+:L\d+(?:-L\d+)?)", s)
            if m:
                try:
                    cited_text(repo, sha, m.group(2))
                except Exception as e:  # noqa: BLE001
                    probs.append(f"{where}: {e}")
            continue
        m = TAG.search(line)
        if not m:
            probs.append(f"{where}: command without a tag: {s[:80]}")
            continue
        cmd, tag = norm(line[:m.start()]), m.group(1).strip()
        try:
            if tag.startswith("glue"):
                if not any(re.fullmatch(p, cmd) for p in GLUE_OK):
                    probs.append(f"{where}: glue not on the allowed list: {cmd[:80]}")
                if cmd.startswith("nohup"):
                    prev = lines[no - 2].strip() if no >= 2 else ""
                    pm = re.match(r"#=\s*([\w./-]+:L\d+(?:-L\d+)?)", prev)
                    inner = re.sub(r"^nohup (.+) > /work/server\.log 2>&1 &$", r"\1", cmd)
                    if not pm or norm(inner) not in cited_text(repo, sha, pm.group(1)):
                        probs.append(f"{where}: nohup command not found at its #= citation")
            elif tag.startswith("prereq"):
                pm = re.match(r'prereq\s+([\w./-]+:L\d+(?:-L\d+)?)\s+"(.+)"$', tag)
                if not pm:
                    probs.append(f"{where}: prereq tag needs <file>:L<n> \"quoted words\"")
                    continue
                if pm.group(2).lower() not in cited_text(repo, sha, pm.group(1)).lower():
                    probs.append(f"{where}: quoted words not on {pm.group(1)}")
                if not any(re.fullmatch(p, cmd) for p in PREREQ_OK):
                    probs.append(f"{where}: prereq is not a standard installer: {cmd[:80]}")
            elif tag.startswith("placeholder"):
                pm = re.match(r"placeholder\s+([\w./-]+:L\d+(?:-L\d+)?)\s+(.+)$", tag)
                if not pm:
                    probs.append(f"{where}: placeholder tag needs <file>:L<n> <orig> => <value>")
                    continue
                text, restored = cited_text(repo, sha, pm.group(1)), cmd
                for pair in pm.group(2).split(";"):
                    orig, _, val = (x.strip() for x in pair.partition("=>"))
                    if not orig or not val or orig not in text:
                        probs.append(f"{where}: placeholder {orig!r} not on the cited line")
                    restored = restored.replace(norm(val), norm(orig))
                if restored not in text:
                    probs.append(f"{where}: command (placeholders restored) not on {pm.group(1)}")
            else:
                if cmd not in cited_text(repo, sha, tag):
                    probs.append(f"{where}: not verbatim at {tag}: {cmd[:80]}")
        except Exception as e:  # noqa: BLE001
            probs.append(f"{where}: {e}")
    return probs


def check(slug):
    d = LIT / slug
    setup = d / "setup.sh"
    if not setup.exists():
        return [f"{slug}: no setup.sh"]
    m = HEADER.search(setup.read_text(encoding="utf-8"))
    if not m:
        return [f"{slug}/setup.sh: header '# literal: <owner/repo> @ <40-char sha>' missing"]
    probs = []
    for name in ("setup.sh", "env.sh", "run.sh"):
        if (d / name).exists():
            probs += check_file(slug, d / name, m.group(1), m.group(2))
    if not (d / "env.sh").exists():
        probs.append(f"{slug}: no env.sh")
    return probs


if __name__ == "__main__":
    slugs = sys.argv[1:] or sorted(p.name for p in LIT.iterdir() if p.is_dir())
    bad = 0
    for s in slugs:
        probs = check(s)
        bad += bool(probs)
        print(f"OK   {s}" if not probs else "\n".join(f"FAIL {p}" for p in probs))
    print(f"{len(slugs) - bad}/{len(slugs)} literal scripts verified")
    sys.exit(1 if bad else 0)
