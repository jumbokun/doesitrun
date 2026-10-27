set -e
source /work/env.sh
cd /work/yapf
D=$(mktemp -d /tmp/yapf_oracle.XXXXXX)
cat > $D/bad.py <<'PY'
x = {  'a':37,'b':42,
'c':927}

def f ( a,b ):
  return a+b
class  Foo(object):
  def g(self,z = 1):
      return [ z,1,2 ]
PY
cp $D/bad.py $D/orig.py
Y="python -m yapf"
command -v yapf >/dev/null 2>&1 && Y=yapf
timeout 300 $Y --version
timeout 300 $Y $D/bad.py > $D/out.py
grep -q "^x = {'a': 37, 'b': 42, 'c': 927}$" $D/out.py
grep -q "^def f(a, b):$" $D/out.py
grep -q "^    return a + b$" $D/out.py
grep -q "def g(self, z=1):" $D/out.py
python -m py_compile $D/out.py
cmp -s $D/bad.py $D/orig.py
rc=0; timeout 300 $Y --diff $D/bad.py > $D/diff.txt || rc=$?
[ "$rc" -ne 0 ]
grep -q '^+def f(a, b):' $D/diff.txt
timeout 300 $Y -i $D/bad.py
cmp -s $D/bad.py $D/out.py
timeout 300 $Y --diff $D/bad.py
timeout 300 $Y --style google $D/orig.py | grep -q "^def f(a, b):$"
echo ORACLE PASS
