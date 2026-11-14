# VolumeLimitCalculator notes
- Installed `bc` via apt (README documents this; it isn't in the base image).
- README refers to `volume_Limit_Calculator.sh` (capital C), but the file is `volume_Limit_calculator.sh`, so the README's commands fail as written. I used the real filename.
- The file is checked out without the executable bit, so I ran `chmod +x` (the README covers this step).
- No code changes were needed. Tested gp3/io2/st1 (plus gp2/io1/sc1) with stdin input, e.g. `printf 'io2\n64000\n' | volume_Limit_calculator.sh`.
- setup.sh pins the commit that was tested.
