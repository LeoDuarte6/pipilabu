local ReplicatedStorage = game:GetService("ReplicatedStorage")

local projectRoot = ReplicatedStorage:WaitForChild("JonAndLeoDevelopment")
local Config = require(projectRoot:WaitForChild("Config"))

print(string.format("[JonAndLeo] server online - %s v%s", Config.ProjectName, Config.DevelopmentVersion))
