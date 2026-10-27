# markitdown setup notes

I followed the README's from-source path (`python -m venv .venv`, then `pip install -e 'packages/markitdown[all]'`) on Python 3.12.3, and it worked as written.
- Nothing broke. The CLI converted test.docx, test.xlsx, test.pptx and test.pdf to Markdown, both with `-o out.md` and through a stdout redirect.
- One cosmetic thing: onnxruntime (pulled in by magika) prints `GetPciBusId` warnings to stderr inside this VM. They are harmless and don't affect the Markdown output.
- setup.sh also upgrades pip inside the venv first. That is optional and only for convenience.
- env.sh sources `/work/markitdown/.venv/bin/activate`.
