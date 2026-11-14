set -e
source /work/env.sh
cd /work/python-fire
D=$(mktemp -d /tmp/oracle.XXXXXX)
# README "Basic Usage" scripts, verbatim (README.md:35-43, 55-66).
cat > $D/hello.py <<'P'
import fire

def hello(name="World"):
  return "Hello %s!" % name

if __name__ == '__main__':
  fire.Fire(hello)
P
cat > $D/calculator.py <<'P'
import fire

class Calculator(object):
  """A simple calculator class."""

  def double(self, number):
    return 2 * number

if __name__ == '__main__':
  fire.Fire(Calculator)
P
# Run outside the clone so `import fire` must come from the installed package, not ./fire.
cd $D
[ "$(timeout 60 python hello.py)" = "Hello World!" ]
[ "$(timeout 60 python hello.py --name=David)" = "Hello David!" ]
# README.md:50 only says --help "Shows usage information". Fire's help page has NAME / SYNOPSIS / FLAGS
# sections (fire/helptext.py:115,139,281) and lists the --name flag; it never prints the word "usage".
timeout 60 python hello.py --help > $D/help.raw 2>&1
sed 's/\x1b\[[0-9;]*m//g' $D/help.raw > $D/help.txt
cat $D/help.txt
grep -q '^NAME' $D/help.txt
grep -q '^SYNOPSIS' $D/help.txt
grep -q -- '--name' $D/help.txt
[ "$(timeout 60 python calculator.py double 10)" = "20" ]
[ "$(timeout 60 python calculator.py double --number=15)" = "30" ]
# README.md:106 Trace flag: `command -- --trace` prints "Fire trace:" (fire/core.py:141-149).
timeout 60 python calculator.py double --number=15 -- --trace > $D/trace.txt 2>&1   # FireExit(0) (fire/core.py:148-151)
grep -q "Fire trace" $D/trace.txt
# The bundled cipher example (examples/cipher/cipher.py docstring): rot13 'Hello world!' -> 'Uryyb jbeyq!'.
# Run by path from $D: sys.path[0] is examples/cipher, so fire still comes from the installed package.
[ "$(timeout 60 python /work/python-fire/examples/cipher/cipher.py rot13 'Hello world!')" = "Uryyb jbeyq!" ]
[ "$(timeout 60 python /work/python-fire/examples/cipher/cipher.py caesar-decode 1 'Ifmmp xpsme!')" = "Hello world!" ]
python -c "import fire,os;print(fire.__file__)"
echo ORACLE PASS
