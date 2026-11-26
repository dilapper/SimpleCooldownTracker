-- Compatibility shims for the Forever client, where several legacy globals
-- have moved into namespaces (or been removed). Defined on the addon's shared
-- table so ccc-derived files pick them up through their environment.
setfenv(1, setmetatable(select(2, ...), { __index = _G }))

if not _G.GetSpellInfo and C_Spell and C_Spell.GetSpellInfo then
	function GetSpellInfo(spell)
		local info = C_Spell.GetSpellInfo(spell)
		if info then
			return info.name, nil, info.iconID, info.castTime, info.minRange, info.maxRange, info.spellID
		end
	end
end

if not _G.GetTalentInfo then
	-- No talent API available: assume no talent bonuses.
	function GetTalentInfo() return nil, nil, nil, nil, 0 end
end

if not _G.UnitDebuff then
	function UnitDebuff() end
end

-- True for "secret" values (Forever/Midnight-era clients), which cannot be
-- used as table keys or compared. Always false on clients without the API.
function IsSecret(value)
	return _G.issecretvalue ~= nil and _G.issecretvalue(value) or false
end
