set -e
source /work/env.sh
cd /work/langextract
timeout 1500 bash /work/run.sh
OUT=$(mktemp -d /tmp/oracle_out.XXXXXX)
cat > $OUT/t.py <<'P'
import sys, os, textwrap
import langextract as lx
out = sys.argv[1]
prompt = textwrap.dedent("""\
    Extract characters, emotions, and relationships in order of appearance.
    Use exact text for extractions. Do not paraphrase or overlap entities.
    Provide meaningful attributes for each entity to add context.""")
examples = [lx.data.ExampleData(
    text="ROMEO. But soft! What light through yonder window breaks? It is the east, and Juliet is the sun.",
    extractions=[
        lx.data.Extraction(extraction_class="character", extraction_text="ROMEO", attributes={"emotional_state": "wonder"}),
        lx.data.Extraction(extraction_class="emotion", extraction_text="But soft!", attributes={"feeling": "gentle awe"}),
        lx.data.Extraction(extraction_class="relationship", extraction_text="Juliet is the sun", attributes={"type": "metaphor"}),
    ])]
text = "Lady Juliet gazed longingly at the stars, her heart aching for Romeo"
result = lx.extract(text_or_documents=text, prompt_description=prompt, examples=examples,
                    model_id="gemma2:2b", model_url="http://localhost:11434")
print("EXTRACTIONS:", [(e.extraction_class, e.extraction_text) for e in result.extractions])
assert len(result.extractions) >= 1, "no extractions"
grounded = [e for e in result.extractions if e.char_interval]
assert grounded, "no grounded extractions"
assert any(e.extraction_text.lower() in text.lower() for e in grounded)
lx.io.save_annotated_documents([result], output_name="extraction_results.jsonl", output_dir=out)
p = os.path.join(out, "extraction_results.jsonl")
assert os.path.getsize(p) > 50
html = lx.visualize(p)
html = html.data if hasattr(html, "data") else html
open(os.path.join(out, "visualization.html"), "w", encoding="utf-8").write(html)
assert os.path.getsize(os.path.join(out, "visualization.html")) > 500
P
timeout 1800 python $OUT/t.py $OUT
grep -qi "juliet\|romeo" $OUT/extraction_results.jsonl
echo ORACLE PASS
