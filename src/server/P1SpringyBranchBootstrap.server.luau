--!strict

-- This script is intentionally present in the Rojo tree but silent when the
-- feature flag is false. It gives the later private-play integration a stable
-- startup seam without changing the v0.9.x default loop today.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local projectRoot = ReplicatedStorage:WaitForChild("JonAndLeoDevelopment")
local config = require(projectRoot:WaitForChild("P1SpringyBranchConfig"))

if not config.Enabled then
	return
end

local service = require(script.Parent:WaitForChild("P1SpringyBranchService"))
local status = service.Start(config)
print(string.format("[P1SpringyBranch] %s", status))
