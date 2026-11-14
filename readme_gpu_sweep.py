"""Grep every tested exam's README(s) for GPU wording, so the exclusion rule is applied by script, not by memory.

Rule: a repo is left out of the CPU track only when its README says in words that the demo needs a GPU, a GPU
memory minimum or GPU machines. A device="cuda" default in sample code or a "tested on <GPU>" line is not a
requirement. This prints every line that matches the requirement wording; each hit must be read in context and
either lead to an exclusion or be noted as not a requirement (e.g. training-only, optional, a speed table).

Usage: python readme_gpu_sweep.py > hits.tsv   (needs gh; reads root README.md plus any .md / */README the demo names)
"""
import glob, json, re, subprocess, sys

WORDS = re.compile(r'\b(gpus?|cuda|vram|apple silicon|tpu)\b', re.I)
NEEDS = re.compile(r'requir|need|must|only|minimum|at least|gpu machine|on gpus?\b', re.I)


def readme_paths(exam):
    demo, top = exam.get("demo") or "", exam["repo"].split("/")[1]
    paths = {"README.md", *re.findall(r'([\w./-]+\.md)', demo)}
    for m in re.findall(r'([\w.-]+(?:/[\w.-]+)*)/README', demo):
        head, _, rest = m.partition("/")
        paths.add((rest if head == top and rest else m) + "/README.md")
    return sorted(paths)


def main():
    for f in sorted(glob.glob("data/exams/*.json")):
        e = json.load(open(f, encoding="utf-8"))
        if not e.get("eligible"):
            continue
        for p in readme_paths(e):
            r = subprocess.run(["gh", "api", f"repos/{e['repo']}/contents/{p}", "-H", "Accept: application/vnd.github.raw"],
                               capture_output=True, text=True, encoding="utf-8", errors="replace")
            if r.returncode:
                print(f"{e['slug']}\t{p}\tMISSING")
                continue
            for i, line in enumerate(r.stdout.splitlines(), 1):
                if WORDS.search(line) and NEEDS.search(line):
                    print(f"{e['slug']}\t{p}:{i}\t{line.strip()[:200]}")


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8", newline="\n")
    main()
