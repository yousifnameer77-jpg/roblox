#!/usr/bin/env python3
"""Generate api.lua (class -> member names) from Roblox's API-Dump.json.

curl -o API-Dump.json https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/API-Dump.json
python3 gen_api.py API-Dump.json > api.lua
"""
import json, sys

d = json.load(open(sys.argv[1], encoding="utf8"))
out = ["local API = {"]
for c in d["Classes"]:
    names = [m["Name"] for m in c["Members"]
             if m.get("MemberType") in ("Property", "Function", "Event", "Callback") and '"' not in m["Name"] and " " not in m["Name"]]
    sup = c.get("Superclass", "")
    out.append('["%s"]={s="%s",m={%s}},' % (c["Name"], sup if sup != "<<<ROOT>>>" else "", ",".join('["%s"]=1' % n for n in names)))
out.append("}")
out.append('''
local memberCache = {}
local function hasMember(class, name)
	local set = memberCache[class]
	if not set then
		set = {}
		local c = class
		while c and c ~= "" do
			local e = API[c]
			if not e then break end
			for n in pairs(e.m) do set[n] = true end
			c = e.s
		end
		memberCache[class] = set
	end
	return set[name] == true
end
''')
print("\n".join(out))
