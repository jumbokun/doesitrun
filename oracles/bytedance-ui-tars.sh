set -e
source /work/env.sh
cd /work/UI-TARS
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
cat > $OUT/t.py <<'P'
from ui_tars.action_parser import parse_action_to_structure_output, parsing_response_to_pyautogui_code
W,H=1920,1080
r="Thought: Click the button\nAction: click(start_box='(100,200)')"
d=parse_action_to_structure_output(r,factor=1000,origin_resized_height=H,origin_resized_width=W,model_type="qwen25vl")
print(d)
assert len(d)==1 and d[0]["action_type"]=="click"
assert "Click the button" in str(d[0].get("thought"))
sb=d[0]["action_inputs"]["start_box"]
print(sb)
import ast
v=ast.literal_eval(sb) if isinstance(sb,str) else sb
assert abs(v[0]-0.1)<1e-3 and abs(v[1]-0.2)<1e-3, v
code=parsing_response_to_pyautogui_code(responses=d,image_height=H,image_width=W)
print(code)
assert "pyautogui.click" in code and "192" in code and "216" in code
r2="Thought: type\nAction: type(content='hello')"
d2=parse_action_to_structure_output(r2,factor=1000,origin_resized_height=H,origin_resized_width=W,model_type="qwen25vl")
assert d2[0]["action_type"]=="type" and d2[0]["action_inputs"]["content"]=="hello"
c2=parsing_response_to_pyautogui_code(responses=d2,image_height=H,image_width=W)
assert "hello" in c2, c2
print("OK")
P
timeout 300 python $OUT/t.py | tee $OUT/log
grep -q '^OK$' $OUT/log
echo "ORACLE PASS"
