set -e
source /work/env.sh
cd /work/python-fire
D=$(mktemp -d /tmp/oracle.XXXXXX)
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
cd $D
[ "$(timeout 60 python hello.py)" = "Hello World!" ]
[ "$(timeout 60 python hello.py --name=David)" = "Hello David!" ]
timeout 60 python hello.py --help 2>&1 | grep -qi "usage"
[ "$(timeout 60 python calculator.py double 10)" = "20" ]
[ "$(timeout 60 python calculator.py double --number=15)" = "30" ]
timeout 60 python calculator.py double --number=15 -- --trace 2>&1 | grep -qi "Fire trace"
python -c "import fire,os;print(fire.__file__)"
echo ORACLE PASS
