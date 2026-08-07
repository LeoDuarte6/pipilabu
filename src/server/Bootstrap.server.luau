local ReplicatedStorage = game:GetService("ReplicatedStorage")

local projectRoot = ReplicatedStorage:WaitForChild("JonAndLeoDevelopment")
local Config = require(projectRoot:WaitForChild("Config"))
local GameService = require(script.Parent:WaitForChild("GameService"))

print(string.format("[JonAndLeo] server online - %s v%s", Config.ProjectName, Config.DevelopmentVersion))

GameService.Start(Config)
