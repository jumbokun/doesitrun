set -e
source /work/env.sh
cd /work/UI-TARS
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
# Run from a fresh dir so only the installed ui_tars package is importable (source lives in codes/ui_tars).
cd "$OUT"
# We test THIS repo's parser: PyPI ui-tars 0.5.x is a different, newer code line (its
# parsing_response_to_pyautogui_code divides pixels by scale_factor=1000), so require that the
# installed module is the clone's codes/ui_tars/action_parser.py (codes/pyproject.toml, version 0.1.4).
MOD=$(python -c "import ui_tars.action_parser as m; print(m.__file__)")
echo "installed parser: $MOD"
cmp "$MOD" /work/UI-TARS/codes/ui_tars/action_parser.py
cat > "$OUT/t.py" <<'P'
import ast
from ui_tars.action_parser import parse_action_to_structure_output, parsing_response_to_pyautogui_code
W, H = 1920, 1080

def boxes(d, key="start_box"):
    v = d["action_inputs"][key]
    return ast.literal_eval(v) if isinstance(v, str) else v

def close(a, b):
    assert len(a) == len(b) and all(abs(x - y) < 1e-6 for x, y in zip(a, b)), (a, b)

# 1. The README snippet verbatim (README.md:63-81).
r = "Thought: Click the button\nAction: click(start_box='(100,200)')"
d = parse_action_to_structure_output(r, factor=1000, origin_resized_height=H,
                                     origin_resized_width=W, model_type="qwen25vl")
print(d)
assert len(d) == 1 and d[0]["action_type"] == "click", d
assert d[0]["thought"] == "Click the button", d[0]["thought"]
# qwen25vl coords are absolute pixels on the smart_resize'd image (action_parser.py:164-169,248-258):
# smart_resize(1080,1920) -> (round(1080/28)*28, round(1920/28)*28) = (1092, 1932) (action_parser.py:115-147).
# A 2-number box is duplicated to 4 numbers (action_parser.py:261-265).
close(boxes(d[0]), [100 / 1932, 200 / 1092, 100 / 1932, 200 / 1092])
code = parsing_response_to_pyautogui_code(responses=d, image_height=H, image_width=W)
print(code)
# x = round(((x1+x2)/2)*W, 3) (action_parser.py:482-483) -> 99.379, 197.802
assert "pyautogui.click(99.379, 197.802, button='left')" in code, code

# 2. Relative-coordinate path (any other model_type divides by factor, action_parser.py:259).
d = parse_action_to_structure_output(r, factor=1000, origin_resized_height=H,
                                     origin_resized_width=W, model_type="qwen2vl")
close(boxes(d[0]), [0.1, 0.2, 0.1, 0.2])
code = parsing_response_to_pyautogui_code(responses=d, image_height=H, image_width=W)
assert "pyautogui.click(192.0, 216.0, button='left')" in code, code

# 3. type -> clipboard paste (action_parser.py:403-415).
d = parse_action_to_structure_output("Thought: type\nAction: type(content='hello')", factor=1000,
                                     origin_resized_height=H, origin_resized_width=W, model_type="qwen25vl")
assert d[0]["action_type"] == "type" and d[0]["action_inputs"]["content"] == "hello", d
code = parsing_response_to_pyautogui_code(responses=d, image_height=H, image_width=W)
assert "pyperclip.copy('hello')" in code and "pyautogui.hotkey('ctrl', 'v')" in code, code

# 4. hotkey (action_parser.py:322-350).
d = parse_action_to_structure_output("Thought: copy\nAction: hotkey(key='ctrl c')", factor=1000,
                                     origin_resized_height=H, origin_resized_width=W, model_type="qwen25vl")
assert d[0]["action_type"] == "hotkey", d
code = parsing_response_to_pyautogui_code(responses=d, image_height=H, image_width=W)
assert "pyautogui.hotkey('ctrl', 'c')" in code, code

# 5. drag with start/end boxes (action_parser.py:424-439).
d = parse_action_to_structure_output("Thought: drag\nAction: drag(start_box='(100,200)', end_box='(300,400)')",
                                     factor=1000, origin_resized_height=H, origin_resized_width=W,
                                     model_type="qwen25vl")
assert d[0]["action_type"] == "drag", d
close(boxes(d[0], "end_box"), [300 / 1932, 400 / 1092, 300 / 1932, 400 / 1092])
code = parsing_response_to_pyautogui_code(responses=d, image_height=H, image_width=W)
assert "pyautogui.moveTo(99.379, 197.802)" in code and "pyautogui.dragTo(298.137, 395.604" in code, code

# 6. finished -> DONE (action_parser.py:493-494).
d = parse_action_to_structure_output("Thought: done\nAction: finished()", factor=1000,
                                     origin_resized_height=H, origin_resized_width=W, model_type="qwen25vl")
assert parsing_response_to_pyautogui_code(responses=d, image_height=H, image_width=W) == "DONE"
print("OK")
P
timeout 300 python "$OUT/t.py" | tee "$OUT/log"
grep -q '^OK$' "$OUT/log"
echo "ORACLE PASS"
