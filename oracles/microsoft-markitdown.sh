set -e
source /work/env.sh
cd /work/markitdown
T=packages/markitdown/tests/test_files
O=$(mktemp -d /tmp/oracle.XXXXXX)
timeout 300 markitdown $T/test.docx -o $O/docx.md
timeout 300 markitdown $T/test.xlsx > $O/xlsx.md
timeout 300 bash -c "cat $T/test.pptx | markitdown -x .pptx > $O/pptx.md" || timeout 300 markitdown $T/test.pptx -o $O/pptx.md
timeout 300 markitdown $T/test.pdf -o $O/pdf.md
for f in docx xlsx pptx pdf; do test "$(wc -c < $O/$f.md)" -gt 200 || { echo "$f too small"; exit 1; }; done
grep -q "314b0a30-5b04-470b-b9f7-eed2c2bec74a" $O/docx.md
grep -q "^# Abstract" $O/docx.md
grep -q "AutoGen: Enabling Next-Gen LLM Applications via Multi-Agent Conversation" $O/docx.md
grep -q "6ff4173b-42a5-4784-9b19-f49caff4d93d" $O/xlsx.md
grep -q "^## " $O/xlsx.md
grep -q "2cdda5c8-e50e-4db4-b5f0-9722a649f455" $O/pptx.md
grep -q "While there is contemporaneous exploration of multi-agent approaches" $O/pdf.md
echo "ORACLE PASS"
