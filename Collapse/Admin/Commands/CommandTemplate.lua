--[[
    Command Template - Blueprint for all admin commands.
    
    All commands follow this pattern:
    - Server logic is guarded by RunService:IsServer()
    - Config connects to the internal admin module (all logic lives there)
    - The Run function is a thin wrapper that calls the admin module
    - Args define the command's parameters with types from AdminTypes
    
    For commands with custom argument types (dropdowns, fuzzy match), see AdminTypes.lua for the type definitions. If the list for the command isn't too large, like its only
    2-3 autofind matches, You can just hardcode it directly within the command.lua file for code bloat.
]]

local RunService = game:GetService("RunService")
local run
if RunService:IsServer() then
    local Config = require(script.Parent.Parent.Config)
    run = function(context, target, value)
        -- Route directly to the admin module, no logic here
        return Config.getAdmin().CommandName(target, value)
    end
end

return {
    Name = "commandname",       -- lowercase, no spaces
    Aliases = {},               -- alternative names e.g. {"cmd", "c"}
    Description = "Description of what the command does.",
    Group = "DefaultAdmin",     -- permission group
    Args = {
        {
            -- Basic argument using a built-in Cmdr type
            Type = "players",
            Name = "target",
            Description = "Player(s) to target."
        },
        {
            -- Custom argument using a type from AdminTypes.lua
            -- Supports fuzzy matching and autocomplete
            Type = "statname",  -- defined in AdminTypes.lua
            Name = "stat",
            Description = "Stat to modify."
        },
        {
            -- Simple number argument
            Type = "number",
            Name = "amount",
            Description = "Amount to apply."
        },
    },
    Run = run,
}
