local snapshot = require "snapshot"

local S1 = snapshot()

local tmp = {}

local S2 = snapshot()

for k,v in pairs(S2) do
	if S1[k] == nil then
		log.Debug("old",k,v)
	end
end

