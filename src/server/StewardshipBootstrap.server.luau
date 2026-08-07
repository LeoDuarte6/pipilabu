--!strict

-- Separate startup seam: the optional prototype service never needs to modify
-- the canonical gameplay bootstrap or its future timed-shift implementation.
local StewardshipService = require(script.Parent:WaitForChild("StewardshipService"))

StewardshipService.Start()
