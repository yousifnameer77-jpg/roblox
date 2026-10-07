#!/bin/bash
# تشغيل السكربت الرئيسي داخل محاكاة Roblox (يكشف أخطاء التنفيذ قبل Studio).
# المتطلبات: ملف api.lua (انظر gen_api.py) والمشغّل luau:  https://github.com/luau-lang/luau
# الاستخدام:  tools/sim/run.sh scenario_bosses.lua
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
LUAU="${LUAU:-luau}"
OUT="$HERE/_run.lua"
cat "$HERE/api.lua" "$HERE/mock.lua" > "$OUT"
echo "local ok, err = pcall(function()" >> "$OUT"
sed 's/os\.clock()/__clock()/g' "$HERE/../../src/SkyIslands.server.lua" >> "$OUT"
echo "end)" >> "$OUT"
cat "$HERE/$1" >> "$OUT"
"$LUAU" "$OUT"
