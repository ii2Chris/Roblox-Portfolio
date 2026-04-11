--[[
    AdminTypes - Custom Cmdr type definitions for game-specific argument types.
    
    Extends Cmdr's type system so admin commands can accept game-specific
    arguments with autocomplete, validation, and fuzzy matching.
    
    All types are built using a shared makeStaticType helper that handles
    the Transform/Validate/Autocomplete/Parse pattern Cmdr expects..
    
    Types defined:
    - toolname    : Live-reads ServerTools folder at runtime so new tools are automatically available without editing this file .. (or else, every items would need to be manually updated).
                    Uses a StringValue bridge to share the list from server to client since ServerStorage isn't accessible client-side.
    - abilityname : Valid ability names (maps to ability enum in Server.lua)
    - familyname  : Valid family names (maps to family enum in Server.lua)
    - traitname   : Valid trait names (maps to trait enum in Server.lua)
    - stylename   : Valid style names (maps to style enum in Server.lua)
    - statname    : Valid stat names for stat modification commands
]]

return function(registry)
	local RunService = game:GetService("RunService")

	local function makeStaticType(list, notFoundMsg)
		return {
			Transform = function(text)
				local lower = text:lower()
				local matches = {}
				for _, name in ipairs(list) do
					if name:lower():find(lower, 1, true) then
						matches[#matches + 1] = name
					end
				end
				return #matches > 0 and matches or nil
			end,
			Validate = function(results)
				if results == nil then return false, notFoundMsg end
				return #results > 0, notFoundMsg
			end,
			Autocomplete = function(results)
				return results or {}
			end,
			Parse = function(results)
				return results[1]
			end,
		}
	end

	-- ============================================================
	-- TYPE: toolname
	-- Reads live from ServerTools folder.
	-- ============================================================
	do
		local seperator = string.char(10)
		local names = {} -- table to contain all the names from servertools

		if RunService:IsServer() then
			local ServerStorage = game:GetService("ServerStorage")
			local pkg = ServerStorage:FindFirstChild("ServerStorage_ACH_Package")
			local tools = pkg and pkg:FindFirstChild("ServerTools")
			if tools then
				for _, child in ipairs(tools:GetChildren()) do
					-- if the tood is a "model" (since that's what they are stored as) append them to the names list
					if child:IsA("Model") then
						names[#names + 1] = child.Name
					end
				end
				table.sort(names)
			end
			local sv       = Instance.new("StringValue")
			sv.Name        = "_toolnames_"
			sv.Value       = table.concat(names, seperator)
			sv.Parent      = script.Parent
		else
			local sv = script.Parent:FindFirstChild("_toolnames_")
			names = (sv and sv.Value ~= "") and sv.Value:split(seperator) or {}
		end

		registry:RegisterType("toolname", makeStaticType(names, "No tool with that name found."))
	end

	-- ============================================================
	-- abilityname
	-- Ability enum member names in Server.lua (lines 426-437).
	-- ============================================================
	do
		local ABILITIES = {
			"Universal",
			"Devil",
			"Blood",
			"Steel",
			"Gravity",
			"Ice",
			"Electricity",
			"Shadow",
			"ChaosFire",
			"Fairy",
		}
		registry:RegisterType("abilityname", makeStaticType(ABILITIES, "No ability with that name."))
	end

	-- ============================================================
	-- familyname
	-- Family enum member names in Server.lua (lines 459-474).
	-- ============================================================
	do
		local FAMILIES = {
			"Khun",
			"Chaos",
			"Ishida",
			"Norris",
			"Kong",
			"Starrk",
			"Aoi",
			"Brando",
			"Saiki",
			"Morow",
			"Arataka",
			"Emiya",
			"Mustang",
			"Wraithraiser",
		}
		registry:RegisterType("familyname", makeStaticType(FAMILIES, "No family with that name."))
	end

	-- ============================================================
	-- traitname
	-- Trait enum member names in Server.lua (lines 449-457).
	-- ============================================================
	do
		local TRAITS = {
			"Reckless",
			"Unwavering",
			"Adaptability",
			"ShockAbsorb",
			"LivingArmour",
			"Timorous",
			"FinalStand",
		}
		registry:RegisterType("traitname", makeStaticType(TRAITS, "No trait with that name."))
	end

	-- ============================================================
	-- stylename
	-- Styles enum member names in Server.lua (lines 439-447).
	-- ============================================================
	do
		local STYLES = {
			"VergilsTraining",
			"CursedTechnique",
			"PhantomThief",
			"PotemkinsTeaching",
			"Kuro",
			"GodOfControl",
			"BlackTrigger",
		}
		registry:RegisterType("stylename", makeStaticType(STYLES, "No style with that name."))
	end


	-- ============================================================
	-- stat commands
	--
	-- ============================================================
	do
		local STATS = { 
			"ap", 
			"ip", 
			"sp", 
			"tp", 
			"exp", 
			"yen", 
			"perk" 
		}
		registry:RegisterType("statname", makeStaticType(STATS, "Unknown stat. Use: ap, ip, sp, tp, exp, yen, perk."))
	end
end
