local oUF = bdCore.oUF
bdCore.Grid = CreateFrame("frame", nil, UIParent)
local grid = bdCore.Grid
local lib_glow = bdButtonGlow

local InCombatLockdown, UnitDebuff, UnitBuff, UnitGroupRolesAssigned, UnitIsConnected, UnitIsDead, UnitIsGhost, UnitName, GetNumGroupMembers, GetRaidRosterInfo, UnitGroupRolesAssigned, GetInstanceInfo, UnitInRaid, UnitInParty, UnitIsUnit = InCombatLockdown, UnitDebuff, UnitBuff, UnitGroupRolesAssigned, UnitIsConnected, UnitIsDead, UnitIsGhost, UnitName, GetNumGroupMembers, GetRaidRosterInfo, UnitGroupRolesAssigned, GetInstanceInfo, UnitInRaid, UnitInParty, UnitIsUnit

-- upcoming features
-- fully custom sorting, custom player positions
-- bouqets / positioning
-- specific spell positioning
-- [buffs] [debuffs] [raid cooldowns] [my casts] [personals]
-- [name] [status] [raid target] [readycheck]

local config = bdConfigLib:GetSave("Grid")
local core_config = bdConfigLib:GetSave("bdAddons")
if (not core_config.GridAliases) then
	core_config.GridAliases = {}
end

-- make sizes outside of combat
function grid:frameSize(frame)
	if (InCombatLockdown()) then return end

	frame:SetSize(config.width, config.height)
	--frame.Health:SetSize(config.width, config.height)
	frame.RaidTargetIndicator:SetSize(12, 12)
	frame.ReadyCheckIndicator:SetSize(12, 12)
	frame.ResurrectIndicator:SetSize(16, 16)
	frame.SimpleThreat:SetSize(60, 50)
	frame.Dispel:SetSize(60, 50)
	
	frame.Short:SetWidth(config.width)

	frame.Buffs:SetPoint("TOPLEFT", frame.Health, "TOPLEFT")
	frame.Buffs:SetFrameLevel(27)
	frame.Buffs:SetSize(64, 16)

	frame.Debuffs:SetPoint("CENTER", frame.Health, "CENTER")
	frame.Debuffs:SetFrameLevel(27)
	frame.Debuffs:SetSize(44, 22)

	frame.Buffs.size = config.buffSize
	frame.Debuffs.size = config.debuffSize
	
	if (config.powerdisplay == "None") then
		frame.Power:Hide()
	elseif (config.powerdisplay == "Healers" and role == "HEALER") then
		frame.Power:Show()
	elseif (config.powerdisplay == "All") then
		frame.Power:Show()
	end

	frame.Power:SetPoint("TOPRIGHT", frame.Health, "BOTTOMRIGHT",0, config.powerheight)

	if (config.showGroupNumbers and IsInRaid()) then
		frame.Group:Show()
	else
		frame.Group:Hide()
	end

	frame.Range = {
		insideAlpha = config.inrangealpha,
		outsideAlpha = config.outofrangealpha,
	}

	if (not config.roleicon) then
		frame.GroupRoleIndicator:Hide()
	end

end

local dispelClass = {
	["PRIEST"] = { ["Disease"] = true, ["Magic"] = true, }, --Purify
	["SHAMAN"] = { ["Curse"] = true, ["Magic"] = true, }, --Purify Spirit
	["PALADIN"] = { ["Poison"] = true, ["Disease"] = true, ["Magic"] = true, }, --Cleanse
	["MAGE"] = { ["Curse"] = true, }, --Remove Curse
	["DRUID"] = { ["Curse"] = true, ["Poison"] = true, ["Magic"] = true, }, --Nature's Cure
	["MONK"] = { ["Poison"] = true, ["Disease"] = true, ["Magic"] = true, }, --Detox
}
local dispelColors = {
	['Magic'] = {.16, .5, .81, 1},
	['Poison'] = {.12, .76, .36, 1},
	['Disease'] = {.76, .46, .12, 1},
	['Curse'] = {.80, .33, .95, 1},
}

--===========================================
-- DISPEL / GLOWING
--===========================================
local function dispelAndGlow(self, event, unit)
	if (unit ~= self.unit) then return end

	local foundGlow = false
	local foundDispel = false
	local noMoreDebuffs = false -- let's us exit loop early if we run out of one or both aura types
	local noMoreBuffs = false -- let's us exit loop early if we run out of one or both aura types

	for i = 1, 40 do

		if (not noMoreDebuffs) then
			local debuff, icon, count, debuffType = UnitDebuff(unit, i)
			if (not debuff) then
				noMoreDebuffs = true
			else
				if (dispelColors[debuffType] and not bdCore:isBlacklisted(debuff)) then
					foundDispel = debuffType
					noMoreDebuffs = true
				end

				if (config.specialalerts[debuff] or bdCore:isGlow(debuff)) then
					foundGlow = true
					noMoreBuffs = true
					noMoreDebuffs = true
				end
			end
		end

		-- glow
		if (not noMoreBuffs) then
			local buff = UnitBuff(unit, i)
			if (not buff) then
				noMoreBuffs = true
			end

			if (config.specialalerts[buff] or bdCore:isGlow(buff)) then
				foundGlow = true
				noMoreBuffs = true
			end
		end
		
		-- breka if possible
		if ((foundGlow and foundDispel) or (noMoreBuffs and noMoreDebuffs)) then
			break
		end
	end

	if (foundDispel) then
		self.Dispel:Show()
		self.Dispel:SetBackdropBorderColor(unpack(dispelColors[foundDispel]))
	else
		self.Dispel:Hide()
	end

	if (foundGlow) then
		lib_glow.ShowOverlayGlow(self.Glow)
	else
		lib_glow.HideOverlayGlow(self.Glow)
	end
end

-- Load 
local index = 1;
function grid.layout(self, unit)
	self:RegisterForClicks('AnyDown')
	self.unit = unit
	
	if (unit == "raid" or unit == "party") then
		self.unit = "raid"..index
	else
		self.unit = unit
	end
	
	function self:configUpdate()
		local role = UnitGroupRolesAssigned(self.unit)
		self.Power:Hide()
		if (config.powerdisplay == "None") then
			self.Power:Hide()
		elseif (config.powerdisplay == "Healers" and role == "HEALER") then
			self.Power:Show()
		elseif (config.powerdisplay == "All") then
			self.Power:Show()
		end


		if (config.hideabsorbs) then
			self.TotalAbsorb:Hide()
			self.HealAbsorb:Hide()
		else
			self.TotalAbsorb:Show()
			self.HealAbsorb:Show()
		end
	end
	
	-- Health
	self.Health = CreateFrame("StatusBar", nil, self)
	self.Health:SetStatusBarTexture(bdCore.media.flat)
	self.Health:SetAllPoints(self)
	self.Health:SetFrameLevel(0)
	self.Health.frequentUpdates = true
	self.Health.colorTapping = true
	self.Health.colorDisconnected = true
	self.Health.colorClass = true
	self.Health.colorReaction = true
	self.Health.colorHealth = true
	bdCore:setBackdrop(self.Health)
	function self.Health.PostUpdate(s, unit, min, max)
		local r, g, b = self.Health:GetStatusBarColor()
		
		if (config.invert) then
			self.Health:SetStatusBarColor(unpack(bdCore.media.backdrop))
			self.Health.background:SetVertexColor(r/2, g/2, b/2)
			self.Short:SetTextColor(r*1.1, g*1.1, b*1.1)
			--self.TotalAbsorb:SetStatusBarColor(1,1,1,.07)
		else
			self.Health:SetStatusBarColor(r/2, g/2, b/2)
			self.Health.background:SetVertexColor(unpack(bdCore.media.backdrop))
			self.Short:SetTextColor(1,1,1)
			--self.TotalAbsorb:SetStatusBarColor(.1,.1,.1,.5)
		end
	end
	
	-- Tags
	-- Status (offline/dead)
	self.Status = self.Health:CreateFontString(nil)
	self.Status:SetFont(bdCore.media.font, 12, "OUTLINE")
	self.Status:SetPoint('BOTTOMLEFT', self, "BOTTOMLEFT", 0, 0)
	oUF.Tags.Events["status"] = "UNIT_HEALTH UNIT_CONNECTION"
	oUF.Tags.Methods["status"] = function(unit)
		if not UnitIsConnected(unit) then
			return "offline"		
		elseif UnitIsDead(unit) then
			return "dead"		
		elseif UnitIsGhost(unit) then
			return "ghost"
		end
	end
	self:Tag(self.Status, '[status]')
	
	-- Absorb
	self.TotalAbsorb = CreateFrame('StatusBar', nil, self.Health)
	self.TotalAbsorb:SetAllPoints(self.Health)
	self.TotalAbsorb:SetStatusBarTexture(bdCore.media.flat)
	self.TotalAbsorb:SetStatusBarColor(.1,.1,.1,.6)
	
	self.HealAbsorb = CreateFrame('StatusBar', nil, self.Health)
	self.HealAbsorb:SetAllPoints(self.Health)
	self.HealAbsorb:SetStatusBarTexture(bdCore.media.flat)
	self.HealAbsorb:SetStatusBarColor(.2,0,0,.5)
	if (config.hideabsorbs) then
		self.HealAbsorb:Hide()
		self.TotalAbsorb:Hide()
	end
	
	self.HealPredict = CreateFrame('StatusBar', nil, self.Health)
	self.HealPredict:SetAllPoints(self.Health)
	self.HealPredict:SetStatusBarTexture(bdCore.media.flat)
	self.HealPredict:SetStatusBarColor(0.6,1,0.6,.2)

	-- Resurrect
	self.ResurrectIndicator = self.Health:CreateTexture(nil, 'OVERLAY')
	self.ResurrectIndicator:SetSize(16, 16)
    self.ResurrectIndicator:SetPoint('TOPRIGHT', self)

	-- Summon
	self.SummonIndicator = self.Health:CreateTexture(nil, 'OVERLAY')
	self.SummonIndicator:SetSize(16, 16)
    self.SummonIndicator:SetPoint('TOPRIGHT', self)

	-- Phase
	self.PhaseIndicator = self.Health:CreateTexture(nil, 'OVERLAY')
	self.PhaseIndicator:SetSize(16, 16)
    self.PhaseIndicator:SetPoint('BOTTOMLEFT', self)

	-- Power
	self.Power = CreateFrame("StatusBar", nil, self.Health)
	self.Power:SetStatusBarTexture(bdCore.media.flat)
	self.Power:ClearAllPoints()
	self.Power:SetPoint("BOTTOMLEFT", self.Health, "BOTTOMLEFT", 0, 0)
	self.Power:SetPoint("TOPRIGHT", self.Health, "BOTTOMRIGHT",0, config.powerheight)
	self.Power:SetAlpha(0.8)
	self.Power.colorPower = true
	self.Power.border = self.Health:CreateTexture(nil)
	self.Power.border:SetPoint("TOPRIGHT", self.Power, "TOPRIGHT", 0, 2)
	self.Power.border:SetPoint("BOTTOMLEFT", self.Power, "TOPLEFT", 0, 0)
	
	-- shortname
	self.nameAnchor = CreateFrame("frame",nil, self.Health) -- because frame level is acting bizare as hell
	self.nameAnchor:SetPoint("BOTTOMRIGHT", self.Health, "BOTTOMRIGHT", -1, 1)
	self.nameAnchor:SetPoint("TOPLEFT", self.Health, "BOTTOMLEFT", 1, 20)
	self.nameAnchor:SetFrameLevel(6)
	self.Short = self.nameAnchor:CreateFontString(nil,"OVERLAY")
	self.Short:SetFont(bdCore.media.font, 13)
	self.Short:SetShadowOffset(1,-1)
	self.Short:SetPoint("BOTTOMRIGHT", self.nameAnchor, "BOTTOMRIGHT", 0,0)
	self.Short:SetJustifyH("RIGHT")
	
	oUF.Tags.Events["self.Short"] = "UNIT_NAME_UPDATE"
	oUF.Tags.Methods["self.Short"] = function(unit)
		local name = UnitName(unit)
		if (not name) then return end
		if (core_config.GridAliases[name]) then
			name = core_config.GridAliases[name];
		end
		return bdCore:utf8sub(name, 1, config.namewidth)
	end

	self:Tag(self.Short, '[self.Short]')
	self:Tag(self.Status, '[status]')

	self.Group = self.Health:CreateFontString(nil)
	self.Group:SetFont(bdCore.media.font, 12, "OUTLINE")
	self.Group:SetPoint('TOPRIGHT', self, "TOPRIGHT", -2, -2)
	oUF.Tags.Events["self.Group"] = "UNIT_NAME_UPDATE"
	oUF.Tags.Methods["self.Group"] = function(unit)
		local name, server = UnitName(unit)
		if(server and server ~= '') then
			name = string.format('%s-%s', name, server)
		end

		for i=1, GetNumGroupMembers() do
			local raidName, _, group = GetRaidRosterInfo(i)
			if( raidName == name ) then
				return "[" .. group .. "]"
			end
		end
	end
	self:Tag(self.Group, '[self.Group]')

	if (config.showGroupNumbers and IsInRaid()) then
		self.Group:Show()
	else
		self.Group:Hide()
	end
	
	-- Range
	self:SetScript("OnEnter", function()
		if (not config.hidetooltips) then
			UnitFrame_OnEnter(self)
		end
	end)
	
	-- Raid Icon
	self.RaidTargetIndicator = self.Health:CreateTexture(nil, "OVERLAY", nil, 1)
	self.RaidTargetIndicator:SetSize(12, 12)
	self.RaidTargetIndicator:SetPoint("TOP", self, "TOP", 0, -2)
	
	-- roll icon
	self.GroupRoleIndicator = self.Health:CreateTexture(nil, "OVERLAY")
	self.GroupRoleIndicator:SetSize(12, 12)
	self.GroupRoleIndicator:SetPoint("BOTTOMLEFT", self.Health, "BOTTOMLEFT",2,2)
	self.GroupRoleIndicator.Override = function(self,event)
		local role = UnitGroupRolesAssigned(self.unit)
		self.GroupRoleIndicator:Hide()
		if (config.roleicon) then
			if (role and (role == "HEALER" or role == "TANK")) then
				self.GroupRoleIndicator:SetTexCoord(GetTexCoordsForRoleSmallCircle(role))
				self.GroupRoleIndicator:Show()
			end
		end
		
		self.Power:Hide()
		if (config.powerdisplay == "None") then
			self.Power:Hide()
		elseif (config.powerdisplay == "Healers" and role == "HEALER") then
			self.Power:Show()
		elseif (config.powerdisplay == "All") then
			self.Power:Show()
		end
	end


	if(config.showpartyleadericon) then
		self.LeaderIndicator = self.Health:CreateTexture(nil, "OVERLAY")
		self.LeaderIndicator:SetSize(12, 12)
		self.LeaderIndicator:SetPoint("TOPLEFT", self.Health, "TOPLEFT",2,2)
		self.LeaderIndicator:Show()
	end
	
	self.Range = {
		insideAlpha = config.inrangealpha,
		outsideAlpha = config.outofrangealpha,
	}
	
	-- Readycheck
	self.ReadyCheckIndicator = self.Health:CreateTexture(nil, 'OVERLAY', nil, 7)
	self.ReadyCheckIndicator:SetPoint('BOTTOM', self, 'BOTTOM', 0, 2)
	
	-- ResurrectIcon
	self.ResurrectIndicator = self.Health:CreateTexture(nil, 'OVERLAY')
	self.ResurrectIndicator:SetPoint('CENTER', self, "CENTER", 0,0)
	
	-- Threat
	self.SimpleThreat = CreateFrame('frame', nil, self)
	self.SimpleThreat:SetFrameLevel(95)
	self.SimpleThreat:SetPoint('TOPRIGHT', self, "TOPRIGHT", 1, 1)
	self.SimpleThreat:SetPoint('BOTTOMLEFT', self, "BOTTOMLEFT", -1, -1)
	self.SimpleThreat:SetBackdrop({bgFile = bdCore.media.flat, edgeFile = bdCore.media.flat, edgeSize = 1})
	self.SimpleThreat:SetBackdropBorderColor(1, 0, 0,1)
	self.SimpleThreat:SetBackdropColor(0,0,0,0)
	self.SimpleThreat:Hide()
	self.SimpleThreat.Callback = function(self)
		local status = UnitThreatSituation("player")
		if (status and status >= 2) then
			self.SimpleThreat:Show()
		else
			self.SimpleThreat:Hide()
		end
	end
	self:RegisterEvent("UNIT_HEALTH", self.SimpleThreat.Callback)
	self:RegisterEvent("PLAYER_ALIVE", self.SimpleThreat.Callback, true)
	self:RegisterEvent("PLAYER_UNGHOST", self.SimpleThreat.Callback, true)
	self:RegisterEvent("PLAYER_TARGET_CHANGED", self.SimpleThreat.Callback, true)
	self:RegisterEvent("PLAYER_REGEN_ENABLED", self.SimpleThreat.Callback, true)
	self:RegisterEvent("PLAYER_REGEN_DISABLED", self.SimpleThreat.Callback, true)
	self:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE", self.SimpleThreat.Callback)
	
	-- Buffs
	self.Buffs = CreateFrame("Frame", nil, self.Health)
	self.Buffs:SetPoint("TOPLEFT", self.Health, "TOPLEFT")
	self.Buffs:SetFrameLevel(21)
	
	self.Buffs:EnableMouse(false)
	self.Buffs.disableMouse = true
	self.Buffs.initialAnchor  = "TOPLEFT"
	self.Buffs.size = config.buffSize
	self.Buffs.spacing = 1
	self.Buffs.num = 6
	self.Buffs['growth-y'] = "DOWN"
	self.Buffs['growth-x'] = "RIGHT"

	self.Buffs.CustomFilter = function(self, unit, button, name, texture, count, debuffType, duration, expiration, caster, isStealable, nameplateShowSelf, spellID, canApply, isBossDebuff, casterIsPlayer, nameplateShowAll,timeMod, effect1, effect2, effect3)
		isBossDebuff = isBossDebuff or false
		nameplateShowAll = nameplateShowAll or false
		local castByPlayer = caster and UnitIsUnit(caster, "player") or false
		return bdCore:filterAura(name, castByPlayer, isBossDebuff, nameplateShowAll, false)
	end
	self.Buffs.PostCreateIcon = function(self, button) 
		local region = button.cd:GetRegions()
		button:SetAlpha(0.8)
		region:SetAlpha(1)
		region:Show()
		if (config.showBuffTimers) then
			region:SetTextHeight(config.buffSize)
			region:SetJustifyH("CENTER")
			region:SetJustifyV("MIDDLE")
			region:SetPoint("TOPLEFT", button.cd, "TOPLEFT", -config.buffSize, 0)
			region:SetPoint("BOTTOMRIGHT", button.cd, "BOTTOMRIGHT", config.buffSize, 0)
		else
			region:SetAlpha(0)
			region:Hide()
		end

		button.cd:SetReverse(true)
		button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	end
	
	-- special spell alerts
	self.Glow = CreateFrame("frame", "glow", self.Health)
	self.Glow:SetAllPoints()
	self.Glow:SetFrameLevel(3)

	-- Dispels
	self.Dispel = CreateFrame('frame', nil, self.Health)
	self.Dispel:SetFrameLevel(100)
	self.Dispel:SetPoint('TOPRIGHT', self, "TOPRIGHT", 1, 1)
	self.Dispel:SetPoint('BOTTOMLEFT', self, "BOTTOMLEFT", -1, -1)
	self.Dispel:SetBackdrop({bgFile = bdCore.media.flat, edgeFile = bdCore.media.flat, edgeSize = 2})
	self.Dispel:SetBackdropBorderColor(1, 0, 0,1)
	self.Dispel:SetBackdropColor(0,0,0,0)
	self.Dispel:Hide()
	
	-- look / color / show dispels and glows
	self:RegisterEvent("UNIT_AURA", dispelAndGlow);
	
	-- Debuffs
	self.Debuffs = CreateFrame("Frame", nil, self.Health)
	self.Debuffs:SetFrameLevel(21)
	self.Debuffs:SetPoint("CENTER", self.Health, "CENTER")
	
	self.Debuffs.initialAnchor = "CENTER"
	self.Debuffs.size = config.debuffSize
	self.Debuffs:EnableMouse(false)
	self.Debuffs.disableMouse = true
	self.Debuffs.spacing = 1
	self.Debuffs.num = 4
	self.Debuffs['growth-y'] = "DOWN"
	self.Debuffs['growth-x'] = "RIGHT"

	self.Debuffs.CustomFilter = function(self, unit, button, name, texture, count, debuffType, duration, expiration, caster, isStealable, nameplateShowSelf, spellID, canApply, isBossDebuff, casterIsPlayer, nameplateShowAll, timeMod)
		isBossDebuff = isBossDebuff or false
		nameplateShowAll = nameplateShowAll or false
		local castByPlayer = caster and UnitIsUnit(caster, "player") or false
		return bdCore:filterAura(name, castByPlayer, isBossDebuff, nameplateShowAll, false)
	end

	self.Debuffs.PostCreateIcon = function(self, button)
		local region = button.cd:GetRegions()
		button:SetAlpha(0.8)
		
		if (config.showDebuffTimers) then
			region:SetAlpha(1)
			region:SetTextHeight(config.debuffSize)
			region:SetJustifyH("CENTER")
			region:SetJustifyV("MIDDLE")
			region:SetPoint("TOPLEFT", button.cd, "TOPLEFT", -config.debuffSize, 0)
			region:SetPoint("BOTTOMRIGHT", button.cd, "BOTTOMRIGHT", config.debuffSize, 0)
		else
			region:SetAlpha(0)
		end
		button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	end

	grid.frames[self] = self; 
	self.index = index
	self.unit = unit
	grid:frameSize(self)
	
	local main  = self
	bdCore:hookEvent("bdGrid_update",function()
		self.configUpdate(main)
	end)
	
	index = index + 1
end

local raidpartyholder = CreateFrame('frame', "bdGrid", UIParent)
raidpartyholder:SetSize(config['width']+2, config['height']*5+8)
raidpartyholder:SetPoint("TOPLEFT", UIParent, "CENTER", -250,200)
bdCore:makeMovable(raidpartyholder)

local frameHeader = false
local group_by
local group_sort
local sort_method
local yOffset
local xOffset
local new_group_anchor
local new_player_anchor
local hgrowth
local vgrowth
local num_groups

function grid:buildAttributes()

	config.spacing = 2
	
	-- sorting options
	if (config.group_sort == "Group") then
		group_by = "GROUP"
		group_sort = "1, 2, 3, 4, 5, 6, 7, 8"
		sort_method = "INDEX"
	elseif (config.group_sort == "Role") then
		group_by = "ROLE"
		group_sort = "TANK,DAMAGE,NONE,HEAL"
		sort_method = "NAME"
	elseif (config.group_sort == "Name") then
		group_by = nil
		group_sort = "1, 2, 3, 4, 5, 6, 7, 8"
		sort_method = "NAME"
	elseif (config.group_sort == "Class") then
		group_by = "CLASS"
		group_sort = "WARRIOR,DEATHKNIGHT,PALADIN,DRUID,MONK,ROGUE,DEMONHUNTER,HUNTER,PRIEST,WARLOCK,MAGE,SHAMAN"
		sort_method = "NAME"
	end
	
	-- group growth/spacing
	if (config.group_growth == "Upwards") then
		new_group_anchor = "BOTTOM"
		yOffset = config.spacing
	elseif (config.group_growth == "Downwards") then
		new_group_anchor = "TOP"
		xOffset = config.spacing
	elseif (config.group_growth == "Left") then
		new_group_anchor = "RIGHT"
		xOffset = -config.spacing
	elseif (config.group_growth == "Right") then
		new_group_anchor = "LEFT"
		xOffset = config.spacing
	end
	
	-- player growth/spacing
	if (not config.new_player_reverse) then
		if (config.group_growth == "Upwards" or config.group_growth == "Downwards") then
			new_player_anchor = "LEFT"
			xOffset = config.spacing
		elseif (config.group_growth == "Left" or config.group_growth == "Right") then
			new_player_anchor = "TOP"
			yOffset = -config.spacing
		end
	elseif (config.new_player_reverse) then
		if (config.group_growth == "Upwards" or config.group_growth == "Downwards") then
			new_player_anchor = "RIGHT"
			xOffset = -config.spacing
		elseif (config.group_growth == "Left" or config.group_growth == "Right") then
			new_player_anchor = "BOTTOM"
			yOffset = config.spacing
		end
	end
	
	-- group limit
	local difficultySize = {[3] = 1, [4] = 25, [5] = 10, [6] = 25, [7] = 25, [9] = 40, [14] = 30, [15] = 30, [16] = 20, [17] = 30, [18] = 40, [20] = 25}
	num_groups = config.num_groups
	if (config.intel_groups) then
		local difficulty = select(3, GetInstanceInfo()) -- maybe use maxPlayers instead?
		if (difficultySize[difficulty]) then
			num_groups = (difficultySize[difficulty] / 5)
		end
	end

end

function grid:resizeRaidHolder()
	-- move the container to the mover, set up for growth directions
	frameHeader:ClearAllPoints();
	if (config.group_growth == "Right") then
		raidpartyholder:SetSize(config.width, config.height*5+8)
		hgrowth = "LEFT"
		vgrowth = "TOP"
		if (config.new_player_reverse) then vgrowth = "BOTTOM" end
		
	elseif (config.group_growth == "Left") then
		raidpartyholder:SetSize(config.width, config.height*5+8)
		hgrowth = "RIGHT"
		vgrowth = "TOP"
		if (config.new_player_reverse) then vgrowth = "BOTTOM" end
		
	elseif (config.group_growth == "Upwards") then
		raidpartyholder:SetSize(config.width*5+8, config.height)
		hgrowth = "LEFT"
		vgrowth = "BOTTOM"
		if (config.new_player_reverse) then hgrowth = "RIGHT" end
		
	elseif (config.group_growth == "Downwards") then
		raidpartyholder:SetSize(config.width*5+8, config.height)
		hgrowth = "LEFT"
		vgrowth = "TOP"
		if (config.new_player_reverse) then hgrowth = "RIGHT" end
	end
	frameHeader:SetPoint(vgrowth..hgrowth, raidpartyholder, vgrowth..hgrowth, 0, 0)
end

function enable(self)
	self:SetActiveStyle("bdGrid")
	
	grid:buildAttributes()
	
	frameHeader = self:SpawnHeader(nil, nil, 'raid,party,solo',
		"showParty", true,
		"showPlayer", true,
		"showSolo", config.showsolo,
		"showRaid", true,
		"initial-scale", 1,
		"unitsPerColumn", 5,
		"columnSpacing", 2,
		"xOffset", xOffset,
		"maxColumns",config.num_groups,
		"groupingOrder",group_sort,
		"sortMethod",sort_method,
		"columnAnchorPoint",new_group_anchor,
		"initial-width",config.width,
		"initial-height",config.height,
		"point",new_player_anchor,
		"yOffset",yOffset,
		"groupBy",group_by
	);
	
	grid:resizeRaidHolder()
end

function grid:callback()
	for k, frame in pairs(grid.frames) do
		grid:frameSize(frame)
	end
end

grid.frames = {}
oUF:RegisterStyle("bdGrid", grid.layout)
oUF:Factory(enable)

function grid:refresh()
	if (InCombatLockdown()) then return end
	
	grid:buildAttributes()
	grid:resizeRaidHolder()
	
	for k, frame in pairs(grid.frames) do
		frame:ClearAllPoints()
	end
	
	-- growth/spacing
	frameHeader:SetAttribute("columnAnchorPoint",new_group_anchor)
	frameHeader:SetAttribute("point",new_player_anchor)
	frameHeader:SetAttribute("yOffset",yOffset)
	frameHeader:SetAttribute("xOffset",xOffset)

	-- what to show
	frameHeader:SetAttribute("showpartyleadericon", config.showpartyleadericon)
	
	-- when to show
	frameHeader:SetAttribute("showSolo",config.showsolo)
	frameHeader:SetAttribute("maxColumns", num_groups)
	
	-- width/height
	frameHeader:SetAttribute("initial-width",config.width)
	frameHeader:SetAttribute("initial-height",config.height)
	
	-- grouping/sorting
	frameHeader:SetAttribute("groupBy",group_by)
	frameHeader:SetAttribute("groupingOrder",group_sort)
	frameHeader:SetAttribute("sortMethod",sort_method)
end

grid:RegisterEvent("PLAYER_REGEN_ENABLED")
grid:RegisterEvent("PLAYER_ENTERING_WORLD")
bdCore:hookEvent("bd_reconfig",function() 
	grid:callback()
	grid:refresh()
end)
grid:SetScript("OnEvent", function(self, event, arg1)
	grid:callback()
	grid:refresh()
end)

-- player alias functionality

local function aliasPrompt(playerName)
	StaticPopupDialogs["BDGRID_ALIAS"] = {
		text = "Set alias for "..playerName,
		button1 = "Accept",
		button2 = "Cancel",
		timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
		OnCancel = function (self, data)
			self:Hide()
		end,
		OnShow = function (self, data)
			local parent = self
			if (bdCore.config.persistent.GridAliases[playerName]) then
				self.editBox:SetText(bdCore.config.persistent.GridAliases[playerName])
			else
				self.editBox:SetText("")
			end
			self.editBox:SetScript("OnEscapePressed", function(self) parent:Hide() end)
			self.editBox:SetScript("OnEnterPressed", function(self) parent.button1:Click() end)
		end,
		OnAccept = function (self, data, data2)
			local text = self.editBox:GetText()
			if (text == "") then
				bdCore.config.persistent.GridAliases[playerName] = nil
			else
				bdCore.config.persistent.GridAliases[playerName] = text
			end
			self:Hide()
		end,
		OnHide = function (self) 
			self.data = nil; 
			self:Hide() 
		end,
		hasEditBox = true,
		enterClicksFirstButton = true,
		preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
	}
	StaticPopup_Show("BDGRID_ALIAS")
end
-- turns out its not at all simpel to add a button where you want in an already-existing dropdown. that or i'm dumb
hooksecurefunc("ToggleDropDownMenu", function(level, value, dropDownFrame, anchorName, xOffset, yOffset, menuList, button, autoHideDelay) 
	if (level == 1 and not button) then
		local name = _G['DropDownList1Button1NormalText']
		local focus = _G['DropDownList1Button3NormalText']

		-- only add a button if this is a unitmenu
		if (focus and focus:GetText() == "Set Focus") then
			name = name:GetText()
			if (name and (UnitInRaid(name) or UnitInParty(name) or UnitIsUnit(name, "player"))) then
				-- add our button
				local info = UIDropDownMenu_CreateInfo()
				info.text = "Add player alias"
				info.notCheckable = true;
				info.func = function()
					aliasPrompt(name)
				end
				UIDropDownMenu_AddButton(info)

				-- loop through all, reposition
				local gap = nil
				local lasty = nil
				local idealy = nil
				for i = 1, 30 do
					local item = _G['DropDownList1Button'..i]
					if (not item) then return end
					local point, anchor, anchorpoint, x, y = item:GetPoint()
					-- calculate how large the menu is
					if (not gap) then
						if (not lasty) then
							lasty = y
						else
							gap = y - lasty
						end
					else
						local text = _G['DropDownList1Button'..i.."NormalText"]:GetText()
						if (i >= 5) then
							-- find out what y axis the new button is taking over
							if (i == 5) then
								idealy = y
							end
							
							-- send everyting down by gap
							item:SetPoint(point, anchor, anchorpoint, x, y+gap)

							if (text == "Add player alias") then
								item:SetPoint(point, anchor, anchorpoint, x, idealy)
							end
						end
					end
				end
			end
		end
	end
end);

-- disable blizzard raid frames
local addonDisabler = CreateFrame("frame", nil)
addonDisabler:RegisterEvent("ADDON_LOADED")
addonDisabler:RegisterEvent("PLAYER_REGEN_ENABLED")
addonDisabler:SetScript("OnEvent", function(self, event, addon)
	if (InCombatLockdown()) then return end
	if (IsAddOnLoaded("Blizzard_CompactRaidFrames")) then
		CompactRaidFrameManager:UnregisterAllEvents() 
		CompactRaidFrameManager:Hide() 
		CompactRaidFrameManager.Show = bdCore.noop
		CompactRaidFrameContainer:UnregisterAllEvents() 
		CompactRaidFrameContainer:Hide()
		CompactRaidFrameContainer.Show = bdCore.noop

		addonDisabler:UnregisterEvent("ADDON_LOADED")
		addonDisabler:UnregisterEvent("PLAYER_REGEN_ENABLED")
	end
end)