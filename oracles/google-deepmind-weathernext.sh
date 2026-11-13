set -e
source /work/env.sh
cd /work/weathernext
OUT=$(mktemp -d /tmp/oracle_out.XXXXXX)
B=https://storage.googleapis.com/dm_graphcast/weathernext2
curl -fL -o "$OUT/data.nc" "$B/dataset/source-hres_forecast_init-2024-10-07%2000%3A00%3A00_res-1.0_levels-13_steps-01.nc"
curl -fL -o "$OUT/w.npz" "$B/params/WeatherNextCyclones_Mini_%3C2024.npz"
[ "$(stat -c %s "$OUT/w.npz")" -gt 200000000 ]
timeout 3000 python -I /work/oracle_py/run_wn.py "$OUT/data.nc" "$OUT/w.npz" "$OUT/pred.nc" 2>&1 | tee "$OUT/log.txt"
grep -q "^WROTE" "$OUT/log.txt"
[ "$(stat -c %s "$OUT/pred.nc")" -gt 100000 ]
echo ORACLE PASS
