-- SimpleCooldownTracker: crowd-control bars for the Forever client.
-- Built on aura events and duration objects, so it never needs to read
-- "secret" values (spell IDs, combat log) that the client hides from addons.
-- Bar look and slash commands are adapted from ccc by Simon Hirsig.

local ADDON = ...

local WIDTH, HEIGHT, MAXBARS, SPACING = 170, 16, 11, 4
local TEXTURE = [[Interface\AddOns\SimpleCooldownTracker\bar]]
local FILTER_CC = 'HARMFUL|PLAYER|CROWD_CONTROL'
local FILTER_ALL = 'HARMFUL|PLAYER'

local defaults = { invert = false, growth = 'up', scale = 1, alpha = .85, plates = true, all = false }

local bars, container = {}, nil
local locked, dirty = true, true
local ccFilterOK = true
local TRACE = false

local function Print(msg) DEFAULT_CHAT_FRAME:AddMessage('<SCT> ' .. msg) end

local function IsSecret(v) return issecretvalue ~= nil and issecretvalue(v) end

local function Settings() return SimpleCooldownTracker_settings end

---------------------------------------------------------------- bars

local function CreateBar()
	local f = CreateFrame('Frame', nil, container)
	f:SetHeight(HEIGHT)

	f.icon = f:CreateTexture()
	f.icon:SetWidth(HEIGHT)
	f.icon:SetPoint('TOPLEFT')
	f.icon:SetPoint('BOTTOMLEFT')
	f.icon:SetTexCoord(.08, .92, .08, .92)

	local sb = CreateFrame('StatusBar', nil, f, 'BackdropTemplate')
	sb:SetPoint('TOPLEFT', f.icon, 'TOPRIGHT')
	sb:SetPoint('BOTTOMRIGHT')
	sb:SetStatusBarTexture(TEXTURE)
	sb:SetStatusBarColor(.3, .9, .3)
	sb:SetMinMaxValues(0, 1)
	sb:SetBackdrop({ bgFile = TEXTURE })
	sb:SetBackdropColor(.3, .9, .3, .3)
	f.statusbar = sb

	local font, _, style = GameFontHighlight:GetFont()
	f.text = sb:CreateFontString(nil, 'OVERLAY')
	f.text:SetFont(font, 11, style)
	f.text:SetPoint('TOPLEFT', 2, 0)
	f.text:SetPoint('BOTTOMRIGHT', -2, 0)
	f.text:SetJustifyH('LEFT')

	f.timertext = sb:CreateFontString(nil, 'OVERLAY')
	f.timertext:SetFont(font, 11, style)
	f.timertext:SetPoint('TOPLEFT', 2, 0)
	f.timertext:SetPoint('BOTTOMRIGHT', -2, 0)
	f.timertext:SetJustifyH('RIGHT')

	f:Hide()
	return f
end

local function PositionBars()
	local up = Settings().growth == 'up'
	for i, bar in ipairs(bars) do
		local offset = (HEIGHT + SPACING) * (i - 1)
		bar:ClearAllPoints()
		if up then
			bar:SetPoint('BOTTOMLEFT', container, 'BOTTOMLEFT', 0, offset)
			bar:SetPoint('BOTTOMRIGHT', container, 'BOTTOMRIGHT', 0, offset)
		else
			bar:SetPoint('TOPLEFT', container, 'TOPLEFT', 0, -offset)
			bar:SetPoint('TOPRIGHT', container, 'TOPRIGHT', 0, -offset)
		end
	end
end

---------------------------------------------------------------- aura scanning

local function RelevantUnit(unit)
	if type(unit) ~= 'string' then return false end
	if unit == 'target' or unit == 'focus' then return true end
	return Settings().plates and unit:find('^nameplate%d+$') ~= nil
end

local function AuraIDs(unit, filter)
	local ok, ids = pcall(C_UnitAuras.GetUnitAuraInstanceIDs, unit, filter)
	if ok and type(ids) == 'table' then return ids end
	-- Older shape: full aura tables
	local ok2, list = pcall(C_UnitAuras.GetUnitAuras, unit, filter)
	if ok2 and type(list) == 'table' then
		local out = {}
		for _, a in ipairs(list) do out[#out + 1] = a.auraInstanceID end
		return out
	end
	return nil, ids
end

local function SameUnit(a, b)
	local ok, same = pcall(UnitIsUnit, a, b)
	if not ok or IsSecret(same) then return false end
	return same
end

local function Collect()
	local s = Settings()
	local filter = (s.all or not ccFilterOK) and FILTER_ALL or FILTER_CC
	local entries = {}

	local units = { 'target', 'focus' }
	if s.plates then
		for i = 1, 40 do units[#units + 1] = 'nameplate' .. i end
	end

	for idx, unit in ipairs(units) do
		if UnitExists(unit) then
			local skip = false
			-- avoid showing the same mob twice (focus/nameplate duplicates of an earlier unit)
			for j = 1, idx - 1 do
				if UnitExists(units[j]) and SameUnit(unit, units[j]) then skip = true break end
			end
			if not skip then
				local ids = AuraIDs(unit, filter)
				if not ids and filter == FILTER_CC then
					ccFilterOK = false
					Print('CROWD_CONTROL aura filter unavailable; showing all of your debuffs instead.')
					ids = AuraIDs(unit, FILTER_ALL)
				end
				for _, id in ipairs(ids or {}) do
					local data = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, id)
					if data then
						local dur = C_UnitAuras.GetAuraDuration and C_UnitAuras.GetAuraDuration(unit, id)
						entries[#entries + 1] = { unit = unit, data = data, duration = dur }
					end
				end
			end
		end
	end
	return entries
end

local function Refresh()
	dirty = false
	if not locked then return end
	local entries = Collect()
	local invert = Settings().invert
	local alpha = Settings().alpha
	for i = 1, MAXBARS do
		local bar, e = bars[i], entries[i]
		if e then
			bar.entry = e
			bar.icon:SetTexture(e.data.icon)
			bar.text:SetText(UnitName(e.unit))
			if e.duration then
				bar.statusbar:SetTimerDuration(e.duration, 0, invert and 0 or 1)
			else
				bar.statusbar:SetMinMaxValues(0, 1)
				bar.statusbar:SetValue(1)
			end
			bar:SetAlpha(alpha)
			bar:Show()
		else
			bar.entry = nil
			bar:Hide()
		end
	end
end

local function UpdateTimerTexts()
	for i = 1, MAXBARS do
		local bar = bars[i]
		local e = bar.entry
		if e and bar:IsShown() then
			if e.duration then
				local ok = pcall(function()
					bar.timertext:SetFormattedText('%.1f', e.duration:GetRemainingDuration())
				end)
				if not ok then bar.timertext:SetText('') end
			else
				bar.timertext:SetText('')
			end
		end
	end
end

---------------------------------------------------------------- lock / unlock

local function Unlock()
	locked = false
	container:EnableMouse(true)
	for i, bar in ipairs(bars) do
		bar.entry = nil
		bar:SetAlpha(Settings().alpha)
		bar.statusbar:SetMinMaxValues(0, 1)
		bar.statusbar:SetValue(1)
		bar.icon:SetTexture([[Interface\Icons\INV_Misc_QuestionMark]])
		bar.text:SetText('SCT bar')
		bar.timertext:SetText(Settings().growth == 'up' and i or MAXBARS - i + 1)
		bar:Show()
	end
end

local function Lock()
	locked = true
	container:EnableMouse(false)
	for _, bar in ipairs(bars) do
		bar.timertext:SetText('')
		bar:Hide()
	end
	dirty = true
end

---------------------------------------------------------------- slash commands

local function Usage()
	Print('Usage:')
	Print('  lock | unlock')
	Print('  invert')
	Print('  growth (up | down)')
	Print('  scale [0.5,3]')
	Print('  alpha [0,1]')
	Print('  plates   (toggle tracking on nameplates)')
	Print('  all      (toggle showing all your debuffs, not only CCs)')
	Print('  debug    (print what the addon sees on your target)')
	Print('  trace    (toggle printing every aura event, for debugging)')
end

local function Debug()
	local unit = 'target'
	Print(('debug: locked=%s ccFilterOK=%s bars=%d'):format(tostring(locked), tostring(ccFilterOK), #bars))
	Print(('debug: C_UnitAuras=%s GetUnitAuraInstanceIDs=%s GetAuraDuration=%s SetTimerDuration=%s'):format(
		tostring(C_UnitAuras ~= nil), tostring(C_UnitAuras and C_UnitAuras.GetUnitAuraInstanceIDs ~= nil),
		tostring(C_UnitAuras and C_UnitAuras.GetAuraDuration ~= nil),
		tostring(bars[1] and bars[1].statusbar.SetTimerDuration ~= nil)))
	if not UnitExists(unit) then Print('debug: no target') return end
	for _, filter in ipairs({ FILTER_CC, FILTER_ALL }) do
		local ids, err = AuraIDs(unit, filter)
		Print(('debug: [%s] -> %s'):format(filter, ids and (#ids .. ' aura(s)') or ('unavailable: ' .. tostring(err))))
		for _, id in ipairs(ids or {}) do
			local data = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, id)
			local dur = C_UnitAuras.GetAuraDuration and C_UnitAuras.GetAuraDuration(unit, id)
			Print(('  id=%s data=%s duration=%s name=%s'):format(tostring(id), data and 'yes' or 'no', dur and 'yes' or 'no',
				data and (IsSecret(data.name) and '<secret>' or tostring(data.name)) or '?'))
		end
	end
end

local function Slash(msg)
	local s = Settings()
	local cmd, arg = (msg or ''):match('^%s*(%S*)%s*(.-)%s*$')
	cmd = cmd:lower()
	if cmd == 'unlock' then Unlock() Print('Bars unlocked.')
	elseif cmd == 'lock' then Lock() Print('Bars locked.')
	elseif cmd == 'invert' then
		s.invert = not s.invert
		Print('Bar inversion ' .. (s.invert and 'on.' or 'off.'))
		dirty = true
	elseif cmd == 'growth' and (arg == 'up' or arg == 'down') then
		s.growth = arg
		PositionBars()
		Print('Growth: ' .. arg)
		if not locked then Unlock() end
	elseif cmd == 'scale' and tonumber(arg) then
		s.scale = math.max(.5, math.min(3, tonumber(arg)))
		container:SetScale(s.scale)
		Print('Scale: ' .. s.scale)
	elseif cmd == 'alpha' and tonumber(arg) then
		s.alpha = math.max(0, math.min(1, tonumber(arg)))
		Print('Alpha: ' .. s.alpha)
		if not locked then Unlock() else dirty = true end
	elseif cmd == 'plates' then
		s.plates = not s.plates
		Print('Nameplate tracking ' .. (s.plates and 'on.' or 'off.'))
		dirty = true
	elseif cmd == 'all' then
		s.all = not s.all
		Print('Showing ' .. (s.all and 'all of your debuffs.' or 'crowd controls only.'))
		dirty = true
	elseif cmd == 'debug' then
		local ok, err = pcall(Debug)
		if not ok then Print('debug error: ' .. tostring(err)) end
	elseif cmd == 'trace' then
		TRACE = not TRACE
		Print('Event trace ' .. (TRACE and 'on (watch chat while applying a CC).' or 'off.'))
	else Usage() end
end

---------------------------------------------------------------- events

local f = CreateFrame('Frame')
f:RegisterEvent('ADDON_LOADED')
f:SetScript('OnEvent', function(self, event, arg1)
	if event == 'ADDON_LOADED' then
		if arg1 ~= ADDON then return end
		self:UnregisterEvent('ADDON_LOADED')

		SimpleCooldownTracker_settings = SimpleCooldownTracker_settings or {}
		for k, v in pairs(defaults) do
			if SimpleCooldownTracker_settings[k] == nil then SimpleCooldownTracker_settings[k] = v end
		end
		local s = Settings()

		container = CreateFrame('Frame', 'SimpleCooldownTracker', UIParent)
		container:SetSize(WIDTH + HEIGHT, (HEIGHT + SPACING) * MAXBARS - SPACING)
		container:SetMovable(true)
		container:SetClampedToScreen(true)
		container:SetUserPlaced(true)
		container:SetScale(s.scale)
		container:SetPoint('CENTER', 0, 150)
		container:SetScript('OnMouseDown', function(c) c:StartMoving() end)
		container:SetScript('OnMouseUp', function(c) c:StopMovingOrSizing() end)

		-- SetScript('OnMouseDown') enables mouse input; the locked state must not
		-- swallow clicks (e.g. right-click camera rotation).
		container:EnableMouse(false)

		for i = 1, MAXBARS do bars[i] = CreateBar() end
		PositionBars()

		SLASH_SIMPLECOOLDOWNTRACKER1 = '/sct'
		SLASH_SIMPLECOOLDOWNTRACKER2 = '/ccc'
		SlashCmdList.SIMPLECOOLDOWNTRACKER = Slash

		self:RegisterEvent('UNIT_AURA')
		self:RegisterEvent('PLAYER_TARGET_CHANGED')
		self:RegisterEvent('PLAYER_FOCUS_CHANGED')
		self:RegisterEvent('NAME_PLATE_UNIT_ADDED')
		self:RegisterEvent('NAME_PLATE_UNIT_REMOVED')
		Print('loaded - /sct')
	elseif event == 'UNIT_AURA' then
		if TRACE then Print('UNIT_AURA ' .. tostring(IsSecret(arg1) and '<secret>' or arg1) .. (RelevantUnit(arg1) and ' (relevant)' or ' (ignored)')) end
		if RelevantUnit(arg1) then dirty = true end
	else
		dirty = true
	end
end)

local elapsed = 0
f:SetScript('OnUpdate', function(_, dt)
	if not locked then return end
	if dirty then Refresh() end
	elapsed = elapsed + dt
	if elapsed > .05 then
		elapsed = 0
		UpdateTimerTexts()
	end
end)
