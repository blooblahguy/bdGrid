local addonName, core = ...
local grid = bdCore.Grid

--------------------------------------
-- Configuration Main
--------------------------------------
local defaults = {}

---------------------------------
-- Frames Display
---------------------------------
defaults[#defaults+1] = {tab = {
	type = "tab",
	value = "Frames Display"
}}
defaults[#defaults+1] = {powerdisplay = {
	type = "dropdown",
	value = "None",
	options = {"None","Healers","All"},
	label = "Power Bar Display",
	tooltip = "Show mana/energy/rage bars on frames.",
	callback = function() bdCore:triggerEvent("bdGrid_update") end
}}
defaults[#defaults+1] = {powerheight = {
	type = "slider",
	value = 2,
	min = 2,
	max = 20,
	step = 1,
	label = "Power Bar Height",
	tooltip = "The height of mana/energy/rage",
	callback = function() bdCore.Grid:callback() end
}}
defaults[#defaults+1] = {width = {
	type = "slider",
	value = 60,
	min = 20,
	max = 100,
	step = 2,
	label = "Width",
	tooltip = "The width of each player in the raid frames",
	callback = function() bdCore.Grid:callback() end
}}
defaults[#defaults+1] = {height = {
	type = "slider",
	value = 50,
	min = 20,
	max = 100,
	step = 2,
	label = "Height",
	tooltip = "The height of each player in the raid frames",
	callback = function() bdCore.Grid:callback() end
}}
defaults[#defaults+1] = {hidetooltips = {
	type = "checkbox",
	value = true,
	label = "Hide Tooltips",
	tooltip = "Hide tooltips when mousing over each unit",
	callback = function() bdCore.Grid:refresh() end
}}
defaults[#defaults+1] = {showpartyleadericon = {
	type = "checkbox",
	value = true,
	label = "Show Party Leader Indicator",
	callback = function() bdCore.Grid:refresh() end
}}
defaults[#defaults+1] = {showGroupNumbers = {
	type = "checkbox",
	value = false,
	label = "Show group numbers in raid",
	callback = function() bdCore.Grid:refresh() end
}}
defaults[#defaults+1] = {invert = {
	type = "checkbox",
	value = false,
	label = "Invert Frame Colors",
	tooltip = "Make the main color of the frames a dark grey, and the backgrounds the class color.",
	callback = function() bdCore.Grid:refresh() end
}}
defaults[#defaults+1] = {roleicon = {
	type = "checkbox",
	value = false,
	label = "Show role icon for tanks and healers",
	tooltip = "Will only show icon for tanks/healers (only in groups)",
	callback = function() bdCore.Grid:callback() end
}}
defaults[#defaults+1] = {inrangealpha = {
	type = "slider",
	value = 1,
	min = 0.1,
	max = 1,
	step = 0.1,
	label = "In Range Alpha",
	tooltip = "The transparency of a player who's in range",
	callback = function() bdCore.Grid:callback() end
}}
defaults[#defaults+1] = {outofrangealpha = {
	type = "slider",
	value = 0.4,
	min = 0.0,
	max = 1.0,
	step = 0.1,
	label = "Out of Range Alpha",
	tooltip = "The transparency of a player who's out of range",
	callback = function() bdCore.Grid:callback() end
}}

---------------------------------
-- Aura Display
---------------------------------
defaults[#defaults+1] = {tab = {
	type = "tab",
	value = "Aura Display"
}}
defaults[#defaults+1] = {buffSize = {
	type = "slider",
	value = 14,
	min = 8,
	max = 40,
	step = 2,
	label = "Buff Size",
	tooltip = "Size of each buff icon.",
	callback = function() bdCore.Grid:callback() end
}}
defaults[#defaults+1] = {debuffSize = {
	type = "slider",
	value = 16,
	min = 8,
	max = 40,
	step = 2,
	label = "Debuff Size",
	tooltip = "Size of each debuff icon.",
	callback = function() bdCore.Grid:callback() end
}}
defaults[#defaults+1] = {showBuffTimers = {
	type = "checkbox",
	value = false,
	label = "Show buff cooldown timers",
	callback = function() bdCore.Grid:callback() end
}}
defaults[#defaults+1] = {showDebuffTimers = {
	type = "checkbox",
	value = false,
	label = "Show debuff cooldown timers",
	callback = function() bdCore.Grid:callback() end
}}

---------------------------------
-- Growth & Grouping
---------------------------------
defaults[#defaults+1] = {tab = {
	type = "tab",
	value = "Growth & Grouping"
}}
defaults[#defaults+1] = {showsolo = {
	type = "checkbox",
	value = true,
	label = "Show raid frames when solo",
	callback = function() bdCore.Grid:refresh() end
}}
defaults[#defaults+1] = {num_groups = {
	type = "slider",
	value = 4,
	min = 1,
	max = 8,
	step = 1,
	label = "Default number of Groups",
	tooltip = "How many groups should be shown at a time",
	callback = function() bdCore.Grid:refresh() end
}}
defaults[#defaults+1] = {intel_groups = {
	type = "checkbox",
	value = true,
	label = "Automatically set group size.",
	tooltip = "When in LFR, show 5 groups, mythic show 4, etc.",
	callback = function() bdCore.Grid:refresh() end
}}
defaults[#defaults+1] = {group_growth = {
	type = "dropdown",
	value = "Left",
	options = {"Left","Right","Upwards","Downwards"},
	label = "Group stack direction",
	tooltip = "Group stacking direction for when a new group is added.",
	callback = function() bdCore.Grid:refresh() end
}}
defaults[#defaults+1] = {new_player_reverse = {
	type = "checkbox",
	value = false,
	label = "Reverse new player growth.",
	tooltip = "When a new player is added the default growth direction is Downward or Right depending on your group growth.",
	callback = function() bdCore.Grid:refresh() end
}}
defaults[#defaults+1] = {group_sort = {
	type = "dropdown",
	value = "Group",
	options = {"Group","Role","Class","Name"},
	label = "Group By",
	tooltip = "Method by which the groups should be formed.",
	callback = function() bdCore.Grid:refresh() end
}}

defaults[#defaults+1] = {tab = {
	type = "tab",
	value = "Special Spells"
}}
defaults[#defaults+1] = {text = {
	type = "text",
	value = "Spells in the following list will create a 'Glow' animation around the frame when the unit has the bufff OR debuff.",
}}
defaults[#defaults+1] = {showspecialicons = {
	type = "checkbox",
	value = true,
	label = "Show Special Spell icons by default",
	callback = function() bdCore.Grid:refresh() end
}}

defaults[#defaults+1] = {specialalerts = {
	type = "list",
	value = specialspells,
	label = "Special Alerts",
}}

defaults[#defaults+1] = {tab = {
	type = "tab",
	value = "Names"
}}
defaults[#defaults+1] = {namewidth = {
	type = "slider",
	value = 4,
	min = 0,
	max = 12,
	step = 1,
	label = "Truncate names to: ",
	tooltip = "Longer names will be trucated to this size",
	callback = function() bdCore.Grid:callback() end
}}
defaults[#defaults+1] = {text = {
	type = "text",
	value = "You can add or remove a nickname to a player by right clicking their name and clicking 'Add player alias'",
}}

-- if another bdAddon hasn't added auras to config, add them here
if (not bdCore.modules["Auras"]) then
	bdCore:addModule("Auras", bdCore.auraconfig, true)
end

bdCore:addModule("Grid", defaults)