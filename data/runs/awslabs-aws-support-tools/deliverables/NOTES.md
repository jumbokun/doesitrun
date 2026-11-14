# EBS VolumeLimitCalculator

Tested at upstream commit 6e0b264.

- I installed `bc` with `apt-get install bc`, as the README says. The sandbox runs as root, so no sudo was needed. I added `apt-get update` first because the fresh image has no package lists.
- Doc error: the README tells you to run `volume_Limit_Calculator.sh` (capital C), but the file is actually named `volume_Limit_calculator.sh`. I used the real filename.
- The script was not executable after cloning, so `setup.sh` runs `chmod +x` on it (the README also lists this step).
- `env.sh` puts the script's directory on PATH. There is no Python environment because the project is pure bash.
- I made no code patches. gp3, io2, st1 (and gp2) all give results when the answers are piped in on stdin, e.g. `printf 'gp3\n100\n6000\n500\n' | volume_Limit_calculator.sh`.
