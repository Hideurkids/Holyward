------------------------------------------------------------------------------------------------------
-- Holyward TurtleWoW
--
-- Priest addon in the style of Necrosis LdC. See the approved port plan at
-- C:\Users\Felix\.claude\plans\eager-fluttering-clock.md for the full milestone list.
------------------------------------------------------------------------------------------------------

Default_HolywardConfig = {
	Version = HolywardData.Version,
	ChatType = true,
	SM = false,
	BuffMenuPos = 34,
	UtilityMenuPos = 34,
	ConsumablesMenuPos = 34,
	ProfessionsMenuPos = 34,
	-- Master switch for the whole timer feature (2026-09-02, per the user): when false, no spell
	-- cast or cooldown poll is allowed to insert a new entry into SpellTimer at all, and
	-- HolywardSpellTimerButton (the timer anchor button -- also doubles as a Hearthstone-cast
	-- button, see its OnClick in Holyward.xml) is force-hidden. ShowSpellTimers/Graphical below only
	-- control DISPLAY MODE (text list vs. icon grid) for an already-enabled tracker; this is the one
	-- switch that turns tracking off entirely.
	TimersEnabled = true,
	ShowSpellTimers = true,
	Graphical = true,
	Yellow = true,
	SensListe = 1,
	SpellTimerPos = 1,
	SpellTimerJust = "LEFT",
	-- Left-clicking the sphere retracts/extends the five satellite buttons; this remembers the
	-- collapsed state across sessions. Replaced the old per-button Show* config toggles.
	SatellitesCollapsed = false,
	-- Sphere edge length in pixels; 58 matches the XML default. Satellite buttons keep their own
	-- configured offsets from the sphere's center regardless of this, so a much bigger sphere can
	-- start to overlap them -- acceptable trade-off, not auto-compensated.
	SphereSize = 58,
	ShowBuffTracker = true,
	ShowAbilityTracker = true,
	-- One flag per HOLYWARD_BUFF_TRACKER slot (Well Fed, Flask, Elixirs group, Weapon, Kreeg's,
	-- Fortitude, Spirit, Intellect, Mark of the Wild, Battle Shout, Blessings group, Thorns), in
	-- that order. Elixirs and Blessings are single grouped slots now: vanilla lets any number of
	-- elixirs stack (no battle/guardian split -- that's a TBC rule), so one icon shows the count
	-- and right-click expands the individual buffs.
	BuffTrackerEnabled = { true, true, true, true, true, true, true, true, true, true, true, true, true, true },
	-- One flag per HOLYWARD_ABILITY_TRACKER slot (Fade, Fear Ward, Power Infusion, Inner Focus,
	-- Pain Spike, Psychic Scream, Chastise, Ascendance, Enlighten proc, Shackle Undead, Weakened
	-- Soul, Devouring Plague, Shadow Word: Pain, Purifying Flames, Searing Light, Mana Potion, Inner
	-- Fire), in that order -- so a Shadow player can turn off the Holy/Disc-only slots and keep just
	-- their own DoTs/cooldowns. Keyed by BASE slot (a slot's identity never changes), independent of
	-- the display order below.
	AbilityTrackerEnabled = { true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true },
	-- Display order of the Ability Tracker: position k on screen shows base slot
	-- AbilityTrackerOrder[k]. A permutation of 1..17, reordered by dragging icons in the tracker.
	AbilityTrackerOrder = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17 },
	-- Master lock: freezes every draggable Holyward window (sphere, satellites, timer anchor, both
	-- trackers) and the Ability Tracker's drag-to-reorder, so nothing shifts by accident mid-fight.
	Locked = false,
	-- When on, every spell/item cast from ANY action bar (not just Holyward's own menus) targets
	-- whatever unit is under the mouse instead of your current target. See the UseAction override
	-- below -- the autoSelfCast CVar is toggled off automatically for the duration of each cast, so
	-- the user does not need to touch WoW's own Interface Options for this to work.
	MouseoverCast = false,
	-- Automatically invites whoever whispers you "inv", "invite", or "123" (exact match, see
	-- HOLYWARD_AUTOINVITE_KEYWORDS) -- no more manually inviting every LFG whisper by hand.
	AutoInvite = false,
	-- One flag per HOLYWARD_CONSUMABLE_CATEGORY slot (Water, Food, Healing Potion, Mana Potion,
	-- Elixir, Flask, Bandage), in that order -- which categories show on the Consumables menu.
	ConsumablesEnabled = { true, true, true, true, true, true, true },
	-- Direction the expanded "everything in this category" popup opens: UP, DOWN, LEFT, or RIGHT.
	ConsumablesExpandDirection = "UP",
	-- Same idea for the Buff Tracker's own Elixir/Blessing group popups (Options -> Buffs).
	BuffTrackerExpandDirection = "DOWN",
	-- The translucent dark panel behind each tracker window; off = icons float directly on the world.
	BuffTrackerBackground = true,
	AbilityTrackerBackground = true,
	-- How many icons per row before the tracker wraps to a new row. No longer exposed as a slider --
	-- it follows the corner resize grip: drag the tracker wider/narrower and this updates itself.
	BuffTrackerPerRow = 14,
	AbilityTrackerPerRow = 17,
	-- Per-tracker geometry, set from the options window: icon edge length in pixels, plus the
	-- horizontal gap between columns and the vertical gap between rows (the countdown text lives
	-- inside the vertical gap, so values below ~12 start overlapping it onto the next row).
	BuffTrackerIconSize = 30,
	BuffTrackerSpacingX = 4,
	BuffTrackerSpacingY = 14,
	AbilityTrackerIconSize = 30,
	AbilityTrackerSpacingX = 4,
	AbilityTrackerSpacingY = 14,
	-- Whether each spell is allowed to create an entry in the main active-timer list, keyed
	-- directly by HOLYWARD_SPELL_TABLE index (only the indices that can ever produce a timer are
	-- listed; Type-0 entries never reach the check that reads this, so they're omitted). Lets a
	-- Shadow player turn off Holy/Disc noise (Chastise, Ascendance, Holy Fire...) and vice versa.
	SpellTimerEnabled = {
		[1] = true, -- Fade
		[2] = true, -- Fear Ward
		[3] = true, -- Power Infusion
		[4] = true, -- Inner Focus
		[5] = true, -- Pain Spike
		[6] = true, -- Devouring Plague
		[8] = true, -- Shackle Undead
		[17] = true, -- Weakened Soul
		[23] = true, -- Enlighten
		[24] = true, -- Psychic Scream
		[25] = true, -- Chastise
		[26] = true, -- Ascendance
		[27] = true, -- Shadow Word: Pain
		[28] = true, -- Holy Fire
		[29] = true, -- Enlightened
	},
}

HolywardConfig = {}
local Loaded = false

------------------------------------------------------------------------------------------------------
-- MOUSEOVER CASTING (global action-bar hook)
------------------------------------------------------------------------------------------------------
-- Overriding the native UseAction (rather than hooking every ActionButtonN's OnClick) catches every
-- action bar, bar page, and bar-swap addon in one place, since ALL of them funnel through this single
-- Blizzard function to actually cast/use a slot. Pattern verified against HealBotBlue's own "Native
-- Hovercasting" implementation (HealBot.lua, "Native Action Bar Hovercasting (Mouseover Hook)").
--
-- Nampower (confirmed installed via pfUI's own modules/nampower.lua) adds a real engine-side spell
-- queue: a press made mid-GCD is remembered and fires automatically the instant the GCD clears --
-- from the DLL itself, NOT through another call to UseAction. The classic click-then-SpellTargetUnit
-- hack below assumes synchronous execution (cast happens now or not at all), so under Nampower a
-- queued press restores the real target long before the deferred cast actually fires, landing the
-- spell on the player instead of the mouseover unit. Nampower's own CastSpellByName(name, unit) takes
-- the target as part of the very call the queue remembers, so route through that whenever it's
-- available -- one atomic call, no target juggling, queue-safe by construction. Confirmed via pfUI's
-- modules/mouseover.lua comment: "Nampower's CastSpellByName takes a second unit parameter directly,
-- no target swap dance required."
local HolywardHasNampower = (GetNampowerVersion ~= nil)

do
	local pass = function() end
	local orig = UseAction
	function UseAction(slot, checkCursor, onSelf)
		if HolywardConfig and HolywardConfig.MouseoverCast and UnitExists("mouseover") and not UnitIsUnit("mouseover", "target") then
			-- IsConsumableAction guards item/potion slots -- CastSpellByName only resolves spells, so
			-- those fall through to the classic hack below (items don't go through Nampower's queue
			-- the same way, and this addon's own item-use buttons already work fine as-is).
			if HolywardHasNampower and not IsConsumableAction(slot) then
				local spellName = GetActionText(slot)
				if not spellName then
					HolywardTooltip:SetOwner(HolywardTooltip, "ANCHOR_NONE")
					HolywardTooltip:SetAction(slot)
					spellName = HolywardTooltipTextLeft1 and HolywardTooltipTextLeft1:GetText()
					-- CastSpellByName with just the bare name always casts the HIGHEST known rank --
					-- read the tooltip's rank text too (e.g. "Rank 1") and fold it into
					-- "Name(Rank N)", the format CastSpellByName needs to hit that exact rank instead.
					-- Without this, a lower-rank button placed specifically to save mana silently cast
					-- max rank via mouseover instead (confirmed by the user 2026-08-22, and again
					-- 2026-08-24). Debug output confirmed a 4-line tooltip with nothing matching "Rank"
					-- in any TextLeft line -- this client pairs the rank with the name on the SAME row,
					-- right-aligned (TextRight1), not as its own left-aligned line, so scan both sides
					-- of every line instead of assuming it's a separate TextLeft entry.
					local rankLine = nil
					local numLines = HolywardTooltip:NumLines()
					for i = 1, numLines, 1 do
						local rightLine = getglobal("HolywardTooltipTextRight" .. i)
						local rightText = rightLine and rightLine:GetText()
						if rightText and string.find(rightText, HOLYWARD_TRANSLATION.Rank) then
							rankLine = rightText
							break
						end
						if i > 1 then
							local leftLine = getglobal("HolywardTooltipTextLeft" .. i)
							local leftText = leftLine and leftLine:GetText()
							if leftText and string.find(leftText, HOLYWARD_TRANSLATION.Rank) then
								rankLine = leftText
								break
							end
						end
					end
					if spellName and rankLine then
						spellName = spellName .. "(" .. rankLine .. ")"
					end
					HolywardTooltip:Hide()
				end
				if spellName and spellName ~= "" then
					CastSpellByName(spellName, "mouseover")
					return
				end
			end

			-- Fallback for clients without Nampower (or when the spell name couldn't be resolved):
			-- still on GCD (or its own cooldown) means this press can't actually cast anything right
			-- now -- let it through unmodified instead of clearing/restoring the target for nothing.
			local cdStart, cdDuration = GetActionCooldown(slot)
			if cdStart and cdStart > 0 and cdDuration and cdDuration > 0 then
				orig(slot, checkCursor, onSelf)
				return
			end

			local _PlaySound = PlaySound
			local hadTarget = UnitExists("target")

			-- Swap in the mouseover unit for the duration of the cast, muting the "target changed"
			-- sound so this reads as a normal cast rather than two visible target swaps.
			PlaySound = pass
			ClearTarget()
			PlaySound = _PlaySound

			local autoSelfCast = GetCVar("autoSelfCast")
			SetCVar("autoSelfCast", "0")

			orig(slot, checkCursor, onSelf)

			if autoSelfCast then
				SetCVar("autoSelfCast", autoSelfCast)
			end

			if SpellIsTargeting() then
				SpellTargetUnit("mouseover")
			end

			if hadTarget then
				PlaySound = pass
				TargetLastTarget()
				PlaySound = _PlaySound
			end
			return
		end
		orig(slot, checkCursor, onSelf)
	end
end

------------------------------------------------------------------------------------------------------
-- STATE
------------------------------------------------------------------------------------------------------

local SpellCast = {
	Name = nil,
	TargetName = nil,
	TargetLevel = nil,
	TargetUnit = nil,
	TargetGUID = nil,
}

-- Mana Potion's Ability Tracker slot used to do a full 5-bag scan every second regardless of
-- whether anything actually changed. Bags only really change on BAG_UPDATE, so cache the found
-- slot and only re-scan when that event marks the cache dirty (see Holyward_OnEvent).
local ManaPotionCache = { bag = nil, slot = nil, dirty = true }

-- Auto-invite (Options -> General): whispers whose whole (trimmed, lowercased) text matches one
-- of these trigger an automatic InviteByName. Exact-match only, not substring, so an unrelated
-- sentence containing one of these words doesn't accidentally invite someone.
local HOLYWARD_AUTOINVITE_KEYWORDS = { ["inv"] = true, ["invite"] = true, ["123"] = true }

local MenuState = {
	BuffMenuShow = false,
	BuffShow = false,
	BuffVisible = false,
	AlphaBuffMenu = 1,
	AlphaBuffVar = 0,
	LastBuff = 0,
	UtilityMenuShow = false,
	UtilityShow = false,
	UtilityVisible = false,
	AlphaUtilityMenu = 1,
	AlphaUtilityVar = 0,
	LastUtility = 0,
	ConsumablesMenuShow = false,
	ConsumablesShow = false,
	AlphaConsumablesMenu = 1,
	AlphaConsumablesVar = 0,
	ProfessionsMenuShow = false,
	ProfessionsShow = false,
	AlphaProfessionsMenu = 1,
	AlphaProfessionsVar = 0,
}

SpellTimer = {}
local SpellGroup = {
	Name = { "Rez", "Main", "Cooldown" },
	SubName = { " ", " ", " " },
	Visible = { true, true, true },
}

local TimerTable = {}
for i = 1, 50, 1 do
	TimerTable[i] = false
end

local GraphicalTimer = {
	texte = {},
	TimeMax = {},
	Time = {},
	titre = {},
	temps = {},
	Gtimer = {},
	icon = {},
}

local function ClearGraphicalTimers()
	while table.getn(GraphicalTimer.texte) > 0 do
		table.remove(GraphicalTimer.texte)
	end
	while table.getn(GraphicalTimer.TimeMax) > 0 do
		table.remove(GraphicalTimer.TimeMax)
	end
	while table.getn(GraphicalTimer.Time) > 0 do
		table.remove(GraphicalTimer.Time)
	end
	while table.getn(GraphicalTimer.titre) > 0 do
		table.remove(GraphicalTimer.titre)
	end
	while table.getn(GraphicalTimer.temps) > 0 do
		table.remove(GraphicalTimer.temps)
	end
	while table.getn(GraphicalTimer.Gtimer) > 0 do
		table.remove(GraphicalTimer.Gtimer)
	end
	while table.getn(GraphicalTimer.icon) > 0 do
		table.remove(GraphicalTimer.icon)
	end
end

local BuffMenuCreate = {}
local UtilityMenuCreate = {}
local ConsumablesMenuCreate = {}
local ConsumablesFound = {}
local ProfessionsMenuCreate = {}
local ProfessionsFound = {}

------------------------------------------------------------------------------------------------------
-- SKIN (Holy/Disc get a white-gold-sky "Holy Light" look; Shadow keeps the dark Necrosis-style look
-- that already matches its aesthetic, matching automatically to Shadowform)
------------------------------------------------------------------------------------------------------

local HOLYWARD_SKIN = { [1] = "Holy", [2] = "Shadow" }
local CurrentSkin = 0

local function Holyward_IsInShadowform()
	local index = 1
	while true do
		local texture = UnitBuff("player", index)
		if not texture then
			return false
		end
		if string.find(texture, "Spell_Shadow_Shadowform") then
			return true
		end
		index = index + 1
	end
end

-- Throttled to 5/sec instead of every single rendered frame (~60/sec) -- this was walking the
-- player's entire buff list (UnitBuff + string.find per buff) unconditionally from Holyward_OnUpdate
-- every frame just to detect a state that only ever changes when the player manually shifts in or
-- out of Shadowform. 0.2s of latency on a skin swap is imperceptible; 60 buff-list walks a second
-- for nothing was a real, measurable cost (worse the more buffs are active, e.g. a buffed raid).
local LastSkinCheck = 0
local function Holyward_UpdateSkin()
	local curTime = GetTime()
	if curTime - LastSkinCheck < 0.2 then
		return
	end
	LastSkinCheck = curTime

	local skin = 1
	if Holyward_IsInShadowform() then
		skin = 2
	end
	if skin ~= CurrentSkin then
		CurrentSkin = skin
		-- The sphere swaps between the user's own two custom orbs now (2026-08-23) instead of the
		-- old Shard32 art -- gold/light for Holy-Disc, purple/void for Shadow.
		if skin == 2 then
			HolywardButton:SetNormalTexture("Interface\\AddOns\\Holyward\\UI\\SphereCustomShadow-01")
		else
			HolywardButton:SetNormalTexture("Interface\\AddOns\\Holyward\\UI\\SphereCustom-01")
		end
		HolywardBuffMenuButton:SetNormalTexture(
			"Interface\\AddOns\\Holyward\\UI\\" .. HOLYWARD_SKIN[skin] .. "\\BuffMenuButton-01"
		)
		HolywardUtilityMenuButton:SetNormalTexture(
			"Interface\\AddOns\\Holyward\\UI\\" .. HOLYWARD_SKIN[skin] .. "\\SpellMenuButton-01"
		)
	end
end

------------------------------------------------------------------------------------------------------
-- COOLDOWN SWIPE (this client has no "Cooldown" frame type at all -- CreateFrame("Cooldown", ...)
-- throws "Unknown frame type", and a plain <Cooldown> XML element silently fails to create, which
-- is why getglobal(...) kept returning nil. The working technique on this client: a "Model" frame
-- inheriting CooldownFrameTemplate still responds to CooldownFrame_SetTimer normally. It's a canned
-- 3D asset (fire-and-forget only, no pause/reverse/recolor), authored for a 36-unit frame, so it's
-- rescaled to match the icon size it's overlaid on.
------------------------------------------------------------------------------------------------------

HolywardCooldownFrames = {}

-- Memoized by `key` (a unique name for this swipe slot) so each swipe is created once and reused,
-- not recreated every tick. `size` is the icon's pixel width/height (the Model asset is authored
-- for a 36-unit frame, so it's rescaled to match); defaults to 32 if not given. Global (not local)
-- so HolywardGraphicalTimer.lua's pool can share it too.
function Holyward_GetOrCreateCooldown(key, parent, size)
	if HolywardCooldownFrames[key] then
		return HolywardCooldownFrames[key]
	end
	if not parent then
		return nil
	end
	local ok, cooldown = pcall(CreateFrame, "Model", nil, parent, "CooldownFrameTemplate")
	if not ok or not cooldown then
		HolywardCooldownFrames[key] = false
		return nil
	end
	size = size or 32
	cooldown:SetAllPoints(parent)
	cooldown:SetScale(size / 36)
	cooldown:ClearAllPoints()
	cooldown:SetPoint("TOPLEFT", parent, "TOPLEFT")
	cooldown:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT")
	HolywardCooldownFrames[key] = cooldown
	return cooldown
end

-- Same memoize-by-name idea as HolywardCooldownFrames above, but for plain getglobal() lookups on
-- XML-defined frames that never change identity after creation (tracker slot frames, their icon/
-- text children). The Buff and Ability Tracker's layout+update passes run once a second and were
-- each re-resolving every slot's frame/icon/text by name every single time (~150 getglobal hash
-- lookups + string concats a second combined across both trackers) -- pure waste once the frame
-- exists, same category of fix already applied to the satellite buttons' Holyward_SatelliteFrame.
-- Global (not local) so every section of this file that reads tracker slot frames can share the
-- one cache instead of each keeping its own.
HolywardGlobalFrameCache = {}
function Holyward_CachedGlobal(name)
	local frame = HolywardGlobalFrameCache[name]
	if frame == nil then
		frame = getglobal(name)
		HolywardGlobalFrameCache[name] = frame
	end
	return frame
end

------------------------------------------------------------------------------------------------------
-- TOOLTIP-SCAN HELPERS (used to resolve a buff/debuff's real display name from its internal name)
------------------------------------------------------------------------------------------------------

function Holyward_MoneyToggle()
	for index = 1, 10 do
		local textLeft = getglobal("HolywardTooltipTextLeft" .. index)
		textLeft:SetText(nil)
		local textRight = getglobal("HolywardTooltipTextRight" .. index)
		textRight:SetText(nil)
	end
	HolywardTooltip:Hide()
	HolywardTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
end

function Holyward_UnitHasEffect(unit, effect)
	local index = 1
	while UnitDebuff(unit, index) do
		Holyward_MoneyToggle()
		HolywardTooltip:SetUnitDebuff(unit, index)
		local DebuffName = tostring(HolywardTooltipTextLeft1:GetText())
		if string.find(DebuffName, effect) then
			return true
		end
		index = index + 1
	end
	return false
end

function Holyward_UnitHasBuff(unit, effect)
	local index = 1
	while UnitBuff(unit, index) do
		Holyward_MoneyToggle()
		HolywardTooltip:SetUnitBuff(unit, index)
		local BuffName = tostring(HolywardTooltipTextLeft1:GetText())
		if string.find(BuffName, effect) then
			return true
		end
		index = index + 1
	end
	return false
end

------------------------------------------------------------------------------------------------------
-- ClassicAPI-BACKED AURA/COOLDOWN READING (falls back gracefully if the DLL isn't loaded)
------------------------------------------------------------------------------------------------------

-- Live remaining-duration lookup for a target's buff/debuff, by display name (avoids needing to
-- know spell IDs). Returns the real expirationTime (a GetTime()-based timestamp) if ClassicAPI's
-- C_UnitAuras is present and the aura is found, else nil -- callers fall back to a hardcoded
-- HOLYWARD_SPELL_TABLE Length when this returns nil, so this is a pure accuracy upgrade, not a
-- hard dependency.
local function Holyward_QueryAuraExpiration(unit, name, isDebuff)
	if not (C_UnitAuras and C_UnitAuras.GetAuraDataByIndex) then
		return nil
	end
	local filter = isDebuff and "HARMFUL" or "HELPFUL"
	local index = 1
	while true do
		local data = C_UnitAuras.GetAuraDataByIndex(unit, index, filter)
		if not data then
			return nil
		end
		if data.name == name and data.expirationTime then
			return data.expirationTime
		end
		index = index + 1
	end
end

------------------------------------------------------------------------------------------------------
-- SPELLBOOK SCAN
------------------------------------------------------------------------------------------------------

-- Walks the live spellbook so the table only ever reflects spells the player actually knows
-- (this is level/talent-agnostic by construction: baseline TWoW grants like Fear Ward at 20 or
-- Divine Spirit at 30 just show up once the spellbook has them, no special-casing needed).
function Holyward_SpellSetup()
	Holyward_ResetSpellTable()

	local slot = 1
	while true do
		local spellName, subSpellName = GetSpellName(slot, BOOKTYPE_SPELL)
		if not spellName then
			break
		end
		for index = 1, table.getn(HOLYWARD_SPELL_TABLE), 1 do
			if HOLYWARD_SPELL_TABLE[index].Name == spellName then
				HOLYWARD_SPELL_TABLE[index].ID = slot
				HOLYWARD_SPELL_TABLE[index].Icon = GetSpellTexture(slot, BOOKTYPE_SPELL)
				if subSpellName and string.find(subSpellName, HOLYWARD_TRANSLATION.Rank) then
					HOLYWARD_SPELL_TABLE[index].Rank = tonumber(strsub(subSpellName, 6, strlen(subSpellName)))
				end
				break
			end
		end
		slot = slot + 1
	end

	-- Purifying Flames (index 31) has no spellbook entry of its own -- it's a proc, not a cast -- so
	-- the loop above never fills its .Icon. The user confirmed it shares Holy Fire's (index 28) icon
	-- in-game, so copy the real one Holy Fire just picked up instead of hardcoding a guess.
	HOLYWARD_SPELL_TABLE[31].Icon = HOLYWARD_SPELL_TABLE[28].Icon

	-- The merged Enlighten tracker slot tracks the "Enlightened" proc (index 29) but must LOOK like
	-- Enlighten itself (gray until it procs) -- give the proc entry Enlighten's real spellbook icon
	-- when known, keeping index 29's hardcoded fallback for characters without the talent.
	if HOLYWARD_SPELL_TABLE[23].Icon then
		HOLYWARD_SPELL_TABLE[29].Icon = HOLYWARD_SPELL_TABLE[23].Icon
	end
end

------------------------------------------------------------------------------------------------------
-- SPELL -> TIMER MANAGEMENT
------------------------------------------------------------------------------------------------------

-- Two timer entries are "the same target" if both have a SuperWoW GUID and it matches, else we
-- fall back to the name+level heuristic (works with or without SuperWoW, just less precise --
-- two identically-named/leveled mobs near each other would otherwise be indistinguishable).
local function Holyward_TargetsMatch(timerEntry, guid, name, level)
	if guid and timerEntry.TargetGUID then
		return timerEntry.TargetGUID == guid
	end
	return timerEntry.Target == name and timerEntry.TargetLevel == level
end

-- Inserts or refreshes a target-nominative timer for spell table index `spell`, preferring a
-- real expirationTime read via ClassicAPI's C_UnitAuras over the table's hardcoded Length when
-- available (isDebuff picks the "HARMFUL" vs "HELPFUL" filter for GetAuraDataByIndex on
-- SpellCast.TargetUnit).
local function Holyward_InsertOrRefreshTargetTimer(spell, isDebuff)
	local name = HOLYWARD_SPELL_TABLE[spell].Name
	local realExpiration = nil
	if SpellCast.TargetUnit then
		realExpiration = Holyward_QueryAuraExpiration(SpellCast.TargetUnit, name, isDebuff)
	end

	for thisspell = 1, table.getn(SpellTimer), 1 do
		if
			SpellTimer[thisspell].Name == name
			and Holyward_TargetsMatch(SpellTimer[thisspell], SpellCast.TargetGUID, SpellCast.TargetName, SpellCast.TargetLevel)
		then
			if realExpiration then
				SpellTimer[thisspell].TimeMax = floor(realExpiration)
				SpellTimer[thisspell].Time = floor(realExpiration - GetTime())
			else
				SpellTimer[thisspell].Time = HOLYWARD_SPELL_TABLE[spell].Length
				SpellTimer[thisspell].TimeMax = floor(GetTime() + HOLYWARD_SPELL_TABLE[spell].Length)
			end
			SpellTimer[thisspell].TargetGUID = SpellCast.TargetGUID
			return
		end
	end

	-- A target-nominative debuff (Type 4) replaces any existing one on the same target
	if HOLYWARD_SPELL_TABLE[spell].Type == 4 then
		for thisspell = table.getn(SpellTimer), 1, -1 do
			if
				SpellTimer[thisspell].Type == 4
				and Holyward_TargetsMatch(SpellTimer[thisspell], SpellCast.TargetGUID, SpellCast.TargetName, SpellCast.TargetLevel)
			then
				SpellTimer, TimerTable = Holyward_RetraitTimerParIndex(thisspell, SpellTimer, TimerTable)
			end
		end
	end

	SpellGroup, SpellTimer, TimerTable =
		Holyward_InsertTimerParTable(spell, SpellCast.TargetName, SpellCast.TargetLevel, SpellGroup, SpellTimer, TimerTable)
	local lastIndex = table.getn(SpellTimer)
	SpellTimer[lastIndex].TargetGUID = SpellCast.TargetGUID
	if realExpiration then
		SpellTimer[lastIndex].TimeMax = floor(realExpiration)
		SpellTimer[lastIndex].Time = floor(realExpiration - GetTime())
	end
end

function Holyward_SpellManagement()
	if not SpellCast.Name then
		return
	end
	-- Master switch (2026-09-02): still clear SpellCast.Name even when disabled -- this function is
	-- what normally consumes/clears it once a cast has been considered, and leaving it set would
	-- either cause reprocessing on a later call or let a stale cast surface as a timer the moment
	-- the feature gets re-enabled.
	if not HolywardConfig.TimersEnabled then
		SpellCast.Name = nil
		return
	end

	for spell = 1, table.getn(HOLYWARD_SPELL_TABLE), 1 do
		-- Type 3 (cooldowns) are no longer cast-triggered: Holyward_PollCooldowns reads them
		-- straight from GetSpellCooldown every tick, which is both simpler and self-correcting.
		if
			SpellCast.Name == HOLYWARD_SPELL_TABLE[spell].Name
			and HOLYWARD_SPELL_TABLE[spell].Type ~= 0
			and HOLYWARD_SPELL_TABLE[spell].Type ~= 3
			and HolywardConfig.SpellTimerEnabled[spell] ~= false
		then
			Holyward_InsertOrRefreshTargetTimer(spell, HOLYWARD_SPELL_TABLE[spell].Type == 4)
			break
		end
	end

	-- Power Word: Shield applies Weakened Soul on the same target, blocking a re-shield for its
	-- duration; it isn't itself a cast so it can't go through the generic name-match loop above.
	-- Only tracked when shielding yourself -- shielding a party member's Weakened Soul isn't
	-- actionable from your own personal timer list.
	if
		SpellCast.Name == "Power Word: Shield"
		and (SpellCast.TargetName == "" or SpellCast.TargetName == UnitName("player"))
		and HolywardConfig.SpellTimerEnabled[17] ~= false
	then
		Holyward_InsertOrRefreshTargetTimer(17, true)
	end

	SpellCast.Name = nil
end

------------------------------------------------------------------------------------------------------
-- COOLDOWN POLLING (Type 3): reads real cooldown state every tick via the native GetSpellCooldown,
-- so no cast-detection is needed and durations self-correct if talents/gear/TWoW change them.
------------------------------------------------------------------------------------------------------

function Holyward_PollCooldowns()
	-- Master switch (2026-09-02): stateless entry point (reads live cooldowns fresh every call), so
	-- unlike Holyward_SpellManagement there's no pending state to clear here -- just skip the work.
	if not HolywardConfig.TimersEnabled then
		return
	end
	for spell = 1, table.getn(HOLYWARD_SPELL_TABLE), 1 do
		if HOLYWARD_SPELL_TABLE[spell].Type == 3 and HOLYWARD_SPELL_TABLE[spell].ID then
			local start, duration = GetSpellCooldown(HOLYWARD_SPELL_TABLE[spell].ID, BOOKTYPE_SPELL)
			local name = HOLYWARD_SPELL_TABLE[spell].Name
			local existingIndex = nil
			for thisspell = 1, table.getn(SpellTimer), 1 do
				if SpellTimer[thisspell].Name == name then
					existingIndex = thisspell
					break
				end
			end

			-- duration > 1.5 filters out the global cooldown so it doesn't flash a timer bar. A
			-- disabled spell (SpellTimerEnabled == false) never starts a new entry, but one already
			-- running still counts down and gets cleaned up normally instead of freezing mid-cooldown.
			if
				start
				and start > 0
				and duration
				and duration > 1.5
				and (existingIndex or HolywardConfig.SpellTimerEnabled[spell] ~= false)
			then
				if existingIndex then
					SpellTimer[existingIndex].TimeMax = floor(start + duration)
					SpellTimer[existingIndex].Time = floor(duration)
				else
					SpellGroup, SpellTimer, TimerTable =
						Holyward_InsertTimerParTable(spell, "", "", SpellGroup, SpellTimer, TimerTable)
					local lastIndex = table.getn(SpellTimer)
					SpellTimer[lastIndex].TimeMax = floor(start + duration)
					SpellTimer[lastIndex].Time = floor(duration)
				end
			elseif existingIndex then
				SpellTimer, TimerTable = Holyward_RetraitTimerParIndex(existingIndex, SpellTimer, TimerTable)
			end
		end
	end
end

------------------------------------------------------------------------------------------------------
-- BUFF TRACKER (separate movable window): fixed set of watched consumable/utility buffs, shown
-- grayed-out when absent, full-color the moment it lands, and fading back to gray as its duration
-- runs out (plus a remaining-time label). No cooldown swipe here: this client's Model+
-- CooldownFrameTemplate fallback (Holyward_GetOrCreateCooldown) can't run in reverse, and a
-- draining "classic" swipe would light the icon UP as the buff runs out instead of dimming it
-- (see WeakestAuras/RegionPrototype.lua's swipe docs) -- the wrong direction for "still buffed" vs.
-- "about to fall off". The vertex-color fade carries that signal directly instead.
------------------------------------------------------------------------------------------------------

-- Elixir/battle-potion aura names that don't contain the substring "Elixir" at all, so the plain
-- substring match below would silently miss them entirely. Confirmed real via three reference
-- addons (2026-08-24, user-provided): Akkio_Consume_Helper (TurtleWoW-specific consumables, e.g.
-- the Concoction line and Danonzo's-adjacent "Special Potions") and DopingControl (vanilla raid-
-- consumable audit tool, which also documents cases where the live AURA name measured in-game
-- differs from the ITEM name -- e.g. Elixir of Fortitude's own buff is literally titled "Health II").
-- Kept as its own lookup so it's easy to extend later without touching the match logic itself.
local HOLYWARD_ELIXIR_EXTRA_NAMES = {
	["Juju Might"] = true, ["Juju Power"] = true, ["Juju Flurry"] = true,
	["Winterfall Firewater"] = true, ["Spirit of Zanza"] = true, ["R.O.I.D.S."] = true,
	["Ground Scorpok Assay"] = true, ["Gift of Arthas"] = true,
	["Cerebral Cortex Compound"] = true, ["Dreamtonic"] = true,
	["Mageblood Potion"] = true, ["Mageblood"] = true,
	["Concoction of the Emerald Mongoose"] = true, ["Concoction of the Dreamwater"] = true,
	["Concoction of the Arcane Giant"] = true,
	-- Aura name differs from the item name on this client (see comment above).
	["Health II"] = true, ["Greater Agility"] = true, ["Greater Frost Power"] = true,
}

-- Match = substring searched in the aura name. Occurrence lets two slots share the same substring
-- (the two Elixir slots, since vanilla allows one Battle + one Guardian elixir at once). Weapon=true
-- reads GetWeaponEnchantInfo instead of the aura list, since weapon oils/stones aren't regular auras.
local HOLYWARD_BUFF_TRACKER = {
	{ Match = "Well Fed", Icon = "Interface\\Icons\\INV_Misc_Food_11", Label = "Well Fed" },
	{ Match = "Flask", Icon = "Interface\\Icons\\INV_Potion_62", Label = "Flask" },
	-- Group slots: vanilla stacks any number of elixirs at once (no battle/guardian split -- that's
	-- TBC+), and a raid can carry several paladin blessings. One icon per group showing the active
	-- count; right-click expands the individual buff icons in a column below the slot. Per the user
	-- (2026-08-23), the MAIN slot's tooltip stays generic ("Elixir"/"Blessings") -- only the expanded
	-- popup icons underneath show the real tooltip of that specific buff. ExtraNames covers elixir-
	-- category buffs whose aura name has no "Elixir" substring to match on (see table above).
	{ Group = "Elixir", Icon = "Interface\\Icons\\INV_Potion_92", Label = "Elixir", ExtraNames = HOLYWARD_ELIXIR_EXTRA_NAMES },
	{ Weapon = true, Icon = "Interface\\Icons\\Spell_Fire_EnchantWeapon", Label = "Weapon Buff" },
	-- Kreeg's Stout Beatdown (Dire Maul, https://www.wowhead.com/classic/item=18284) -- +15 Spirit,
	-- gambles a stun debuff too; the buff aura is named the same as the item.
	{ Match = "Kreeg's Stout Beatdown", Icon = "Interface\\Icons\\INV_Drink_07", Label = "Kreeg's Stout Beatdown" },
	-- Standard raid/class buffs. Match strings target the substring shared by the single-target and
	-- AOE/Prayer-of/Greater- ranks (e.g. "Fortitude" covers both Power Word: Fortitude and Prayer of
	-- Fortitude) so either rank lights up the same slot.
	{ Match = "Fortitude", Icon = "Interface\\Icons\\Spell_Holy_WordFortitude", Label = "Fortitude" },
	{ Match = "Spirit", Icon = "Interface\\Icons\\Spell_Holy_DivineSpirit", Label = "Divine Spirit" },
	{ Match = "Intellect", Icon = "Interface\\Icons\\Spell_Holy_ArcaneIntellect", Label = "Arcane Intellect" },
	{ Match = "the Wild", Icon = "Interface\\Icons\\Spell_Nature_Regeneration", Label = "Mark of the Wild" },
	{ Match = "Battle Shout", Icon = "Interface\\Icons\\Ability_Warrior_BattleShout", Label = "Battle Shout" },
	{ Group = "Blessing of", Icon = "Interface\\Icons\\Spell_Magic_GreaterBlessingofKings", Label = "Blessings" },
	{ Match = "Thorns", Icon = "Interface\\Icons\\Spell_Nature_Thorns", Label = "Thorns" },
	{ Match = "Inner Fire", Icon = "Interface\\Icons\\Spell_Holy_InnerFire", Label = "Inner Fire" },
	-- Slot 14, appended (2026-08-24) per the user -- not inserted among the others, so no existing
	-- slot's index (and no existing saved BuffTrackerEnabled/HolywardBuffTrackerN XML frame) shifts.
	-- Matches both ranks ("Shadow Protection" and "Prayer of Shadow Protection") same as Fortitude.
	{ Match = "Shadow Protection", Icon = "Interface\\Icons\\Spell_Shadow_AntiShadow", Label = "Shadow Protection" },
}

-- Buff Tracker slot -> HOLYWARD_SPELL_TABLE index, for the 3 slots that are actually spells the
-- player can cast (the rest are other classes' buffs or consumables -- nothing to cast). Clicking
-- one of these casts it; see Holyward_BuffTrackerSlot_OnMouseUp.
local HOLYWARD_BUFF_TRACKER_CAST = { [6] = 9, [7] = 11, [13] = 15 }

-- Global accessor so the config-tab sync code (defined earlier in this file, before this local
-- exists) can read a category's icon for its checkbox row without hitting the upvalue trap.
function Holyward_GetBuffTrackerIcon(i)
	return HOLYWARD_BUFF_TRACKER[i] and HOLYWARD_BUFF_TRACKER[i].Icon
end

-- Finds the Nth (Occurrence) player buff whose name contains matchText. Returns found,
-- expirationTime, duration, icon -- the latter three nil if ClassicAPI's C_UnitAuras isn't
-- available (presence-only fallback via tooltip scan, no live countdown or icon).
local function Holyward_FindBuffOccurrence(matchText, occurrence)
	occurrence = occurrence or 1
	local seen = 0
	if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
		local index = 1
		while true do
			local data = C_UnitAuras.GetAuraDataByIndex("player", index, "HELPFUL")
			if not data then
				break
			end
			if data.name and string.find(data.name, matchText, 1, true) then
				seen = seen + 1
				if seen == occurrence then
					return true, data.expirationTime, data.duration, data.icon
				end
			end
			index = index + 1
		end
		return false, nil, nil, nil
	end
	local index = 1
	while UnitBuff("player", index) do
		Holyward_MoneyToggle()
		HolywardTooltip:SetUnitBuff("player", index)
		local buffName = tostring(HolywardTooltipTextLeft1:GetText())
		if string.find(buffName, matchText, 1, true) then
			seen = seen + 1
			if seen == occurrence then
				return true, nil, nil, nil
			end
		end
		index = index + 1
	end
	return false, nil, nil, nil
end

-- Collects every player buff whose name contains matchText: array of { name, icon, expiration,
-- index }. With ClassicAPI's C_UnitAuras the entries carry live icons; the tooltip-scan fallback
-- yields names only (icon nil -> the group popup shows a placeholder). `index` is the raw aura
-- index at collection time, kept so the popup's OnEnter can show the real tooltip via
-- GameTooltip:SetUnitBuff("player", index) instead of just the generic group label.
local function Holyward_BuffNameMatches(name, matchText, extraNames)
	if string.find(name, matchText, 1, true) then
		return true
	end
	return extraNames and extraNames[name] or false
end

local function Holyward_CollectBuffMatches(matchText, extraNames)
	local matches = {}
	if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
		local index = 1
		while true do
			local data = C_UnitAuras.GetAuraDataByIndex("player", index, "HELPFUL")
			if not data then
				break
			end
			if data.name and Holyward_BuffNameMatches(data.name, matchText, extraNames) then
				table.insert(matches, { name = data.name, icon = data.icon, expiration = data.expirationTime, index = index })
			end
			index = index + 1
		end
		return matches
	end
	local index = 1
	while UnitBuff("player", index) do
		Holyward_MoneyToggle()
		HolywardTooltip:SetUnitBuff("player", index)
		local buffName = tostring(HolywardTooltipTextLeft1:GetText())
		if Holyward_BuffNameMatches(buffName, matchText, extraNames) then
			table.insert(matches, { name = buffName, index = index })
		end
		index = index + 1
	end
	return matches
end

------------------------------------------------------------------------------------------------------
-- BUFF GROUP POPUPS: a Group slot (Elixirs, Blessings) shows one icon plus the active count;
-- right-clicking it expands a column of the individual matched buffs' icons below the slot, and
-- right-clicking again collapses it. Popup frames are Lua-created lazily, one small pool per slot.
------------------------------------------------------------------------------------------------------

local BuffGroupExpanded = {}
local BuffGroupExpireAt = {}
local BuffGroupPopups = {}
local HOLYWARD_BUFF_GROUP_POPUP_MAX = 8
-- Auto-collapse an expanded group popup after this many seconds with no further toggle, so it
-- doesn't sit open forever (per the user, 2026-08-24). Checked once a second from
-- Holyward_UpdateBuffTracker below, not every frame -- plenty precise for a multi-second timeout.
local HOLYWARD_BUFF_GROUP_EXPAND_TIMEOUT = 6

-- Either click on a Group slot toggles its expand popup (both left and right, per the user,
-- 2026-08-24); left-click on one of the 3 castable slots casts it. One handler, OnMouseDown --
-- OnMouseUp turned out not to fire reliably on a plain Frame on this client (confirmed 2026-08-23),
-- so both live on the same proven event.
local function Holyward_BuffTrackerSlot_OnMouseDown()
	if this.holywardGroupSlot then
		local slot = this.holywardGroupSlot
		BuffGroupExpanded[slot] = not BuffGroupExpanded[slot]
		BuffGroupExpireAt[slot] = BuffGroupExpanded[slot] and (GetTime() + HOLYWARD_BUFF_GROUP_EXPAND_TIMEOUT) or nil
		return
	end
	local castIndex = this.holywardBuffSlot and HOLYWARD_BUFF_TRACKER_CAST[this.holywardBuffSlot]
	if castIndex and HOLYWARD_SPELL_TABLE[castIndex] and HOLYWARD_SPELL_TABLE[castIndex].ID then
		CastSpell(HOLYWARD_SPELL_TABLE[castIndex].ID, "spell")
	end
end

-- Tooltip for a Buff Tracker slot: the 3 castable ones (Fortitude/Divine Spirit/Inner Fire, see
-- HOLYWARD_BUFF_TRACKER_CAST) get the real spell tooltip; everything else -- including the Group
-- slots' own icon, per the user (2026-08-23) -- gets a plain generic label instead.
local function Holyward_BuffTrackerSlot_OnEnter()
	local slot = this.holywardBuffSlot
	local category = slot and HOLYWARD_BUFF_TRACKER[slot]
	if not category then
		return
	end
	local castIndex = HOLYWARD_BUFF_TRACKER_CAST[slot]
	if castIndex and HOLYWARD_SPELL_TABLE[castIndex] and HOLYWARD_SPELL_TABLE[castIndex].ID then
		GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
		GameTooltip:SetSpell(HOLYWARD_SPELL_TABLE[castIndex].ID, BOOKTYPE_SPELL)
		GameTooltip:Show()
		return
	end
	GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
	GameTooltip:AddLine(category.Label or category.Match or "", 1.0, 1.0, 1.0)
	GameTooltip:Show()
end

local function Holyward_BuffTrackerSlot_OnLeave()
	GameTooltip:Hide()
end

-- One-time wiring of every Buff Tracker slot's mouse handling; called from Holyward_Initialize (the
-- slot frames exist by then). Enabling mouse on all of them means the tracker window can't be
-- dragged FROM a slot specifically -- drag from the window background/padding instead, same
-- trade-off already accepted for the two Group slots before this.
function Holyward_SetupBuffGroupSlots()
	for slot = 1, table.getn(HOLYWARD_BUFF_TRACKER), 1 do
		local slotFrame = getglobal("HolywardBuffTracker" .. slot)
		if slotFrame then
			slotFrame.holywardBuffSlot = slot
			slotFrame:EnableMouse(true)
			slotFrame:SetScript("OnEnter", Holyward_BuffTrackerSlot_OnEnter)
			slotFrame:SetScript("OnLeave", Holyward_BuffTrackerSlot_OnLeave)
			slotFrame:SetScript("OnMouseDown", Holyward_BuffTrackerSlot_OnMouseDown)
			if HOLYWARD_BUFF_TRACKER[slot].Group then
				slotFrame.holywardGroupSlot = slot
			end
		end
	end
end

-- Real per-buff tooltip for an expanded group popup icon (Elixir/Blessing list) -- the aura index
-- at collection time is stashed on the frame by Holyward_UpdateBuffGroupPopup below. Always shows
-- something on hover (per the user, 2026-08-24): falls back to the group's generic label on the
-- rare frame where the aura index hasn't been set yet instead of showing nothing.
-- THE ACTUAL BUG (2026-08-24): this took `frame` as a function PARAMETER, but a plain
-- `popup:SetScript("OnEnter", Holyward_BuffGroupPopup_OnEnter)` never passes the frame as an
-- argument on this client -- it sets the implicit `this` global instead (documented project-wide
-- gotcha: XML-script-handler callbacks read `this`/`argN`, not `function(self, ...)` params). So
-- `frame` was nil on every single call and this returned immediately, every time -- the tooltip
-- never had a chance to show. Rewritten to read `this` like every other OnEnter in this file.
function Holyward_BuffGroupPopup_OnEnter()
	GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
	if this.holywardAuraIndex then
		GameTooltip:SetUnitBuff("player", this.holywardAuraIndex)
	else
		local category = this.holywardGroupSlot and HOLYWARD_BUFF_TRACKER[this.holywardGroupSlot]
		GameTooltip:AddLine(category and (category.Label or category.Group) or "", 1.0, 1.0, 1.0)
	end
	GameTooltip:Show()
end

local HOLYWARD_BUFF_GROUP_POPUP_SIZE = 24
-- Gap between the trigger slot's own edge and the first popup icon (per the user, 2026-08-24:
-- reduce this one) and the pitch between consecutive popup icons (must be >= the icon size above
-- or consecutive icons overlap -- confirmed the actual bug behind the "too cramped" screenshot:
-- the old fixed -10/-22 formula had a 22px pitch against a 24px icon, a 2px overlap every step).
local HOLYWARD_BUFF_GROUP_POPUP_GAP = 2
local HOLYWARD_BUFF_GROUP_POPUP_SPACING = HOLYWARD_BUFF_GROUP_POPUP_SIZE + 3

local function Holyward_GetBuffGroupPopup(slot, j)
	if not BuffGroupPopups[slot] then
		BuffGroupPopups[slot] = {}
	end
	if not BuffGroupPopups[slot][j] then
		local slotFrame = getglobal("HolywardBuffTracker" .. slot)
		if not slotFrame then
			return nil
		end
		-- "Button", not plain "Frame" (2026-08-24 fix): the Consumables Menu's own popups, which
		-- never had this tooltip problem, are CreateFrame("Button", ...) -- these were the one place
		-- still using a plain Frame for a hover-only widget, and this client has already shown (see
		-- the OnMouseUp gotcha elsewhere in this file) that a bare Frame's mouse events aren't
		-- reliable here even with EnableMouse(true); Button is the widget type actually proven to
		-- work for both click and hover across the rest of this addon.
		local popup = CreateFrame("Button", nil, slotFrame)
		popup:SetWidth(HOLYWARD_BUFF_GROUP_POPUP_SIZE)
		popup:SetHeight(HOLYWARD_BUFF_GROUP_POPUP_SIZE)
		-- TOOLTIP strata: without this, the tracker window's own background/drag region -- a sibling
		-- frame covering the same screen area the popups extend into -- could win the mouse hit-test
		-- over a popup sitting visually on top of it. Same fix already applied to the Consumables
		-- Menu's own popups (see Holyward_GetConsumablesGroupPopup).
		popup:SetFrameStrata("TOOLTIP")
		local tex = popup:CreateTexture(nil, "ARTWORK")
		tex:SetAllPoints(popup)
		popup.holywardIcon = tex
		popup.holywardGroupSlot = slot
		popup:EnableMouse(true)
		popup:SetScript("OnEnter", Holyward_BuffGroupPopup_OnEnter)
		popup:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
		popup:Hide()
		BuffGroupPopups[slot][j] = popup
	end
	return BuffGroupPopups[slot][j]
end

-- Position is recomputed every update (not just at creation) so a live change to
-- HolywardConfig.BuffTrackerExpandDirection (Options -> Buffs) reflows an already-built popup pool
-- immediately instead of only taking effect on the next relog.
-- LastShown tracks the previous call's count per slot so a fully-collapsed group (the overwhelming
-- majority of ticks, since these lists are rarely left open) can skip the pool loop entirely instead
-- of re-hiding up to 8 already-hidden popups every second for the lifetime of the session.
local BuffGroupLastShown = {}
local function Holyward_UpdateBuffGroupPopup(slot, matches)
	local shown = 0
	if BuffGroupExpanded[slot] and matches then
		shown = table.getn(matches)
		if shown > HOLYWARD_BUFF_GROUP_POPUP_MAX then
			shown = HOLYWARD_BUFF_GROUP_POPUP_MAX
		end
	end
	if shown == 0 and (BuffGroupLastShown[slot] or 0) == 0 then
		return
	end
	BuffGroupLastShown[slot] = shown
	local direction = HolywardConfig.BuffTrackerExpandDirection or "DOWN"
	local slotFrame = Holyward_CachedGlobal("HolywardBuffTracker" .. slot)
	for j = 1, HOLYWARD_BUFF_GROUP_POPUP_MAX, 1 do
		local popup = Holyward_GetBuffGroupPopup(slot, j)
		if popup then
			if j <= shown then
				popup.holywardIcon:SetTexture(matches[j].icon or "Interface\\Icons\\INV_Misc_QuestionMark")
				popup.holywardAuraIndex = matches[j].index
				popup:ClearAllPoints()
				local offset = HOLYWARD_BUFF_GROUP_POPUP_GAP + (j - 1) * HOLYWARD_BUFF_GROUP_POPUP_SPACING
				if direction == "UP" then
					popup:SetPoint("BOTTOM", slotFrame, "TOP", 0, offset)
				elseif direction == "LEFT" then
					popup:SetPoint("RIGHT", slotFrame, "LEFT", -offset, 0)
				elseif direction == "RIGHT" then
					popup:SetPoint("LEFT", slotFrame, "RIGHT", offset, 0)
				else
					popup:SetPoint("TOP", slotFrame, "BOTTOM", 0, -offset)
				end
				popup:Show()
			else
				popup.holywardAuraIndex = nil
				popup:Hide()
			end
		end
	end
end

-- Absent-buff tint. The fade below runs from full color (1,1,1) at application down to this same
-- gray, so a buff about to fall off reads visually the same as one already gone.
local HOLYWARD_BUFF_TRACKER_ABSENT_SHADE = 0.35

function Holyward_UpdateBuffTracker()
	Holyward_LayoutBuffTracker()
	for slot = 1, table.getn(HOLYWARD_BUFF_TRACKER), 1 do
		local category = HOLYWARD_BUFF_TRACKER[slot]
		local icon = Holyward_CachedGlobal("HolywardBuffTracker" .. slot .. "Icon")
		local text = Holyward_CachedGlobal("HolywardBuffTracker" .. slot .. "Text")
		if category.Group and icon and text then
			-- Grouped slot: count of active matches on the icon, left or right click to expand the
			-- list. A disabled/hidden slot also collapses its popup, and an expanded one auto-
			-- collapses on its own once HOLYWARD_BUFF_GROUP_EXPAND_TIMEOUT elapses.
			if BuffGroupExpanded[slot] and BuffGroupExpireAt[slot] and GetTime() >= BuffGroupExpireAt[slot] then
				BuffGroupExpanded[slot] = nil
				BuffGroupExpireAt[slot] = nil
			end
			if HolywardConfig.BuffTrackerEnabled[slot] then
				icon:SetTexture(category.Icon)
				local matches = Holyward_CollectBuffMatches(category.Group, category.ExtraNames)
				local count = table.getn(matches)
				if count > 0 then
					icon:SetVertexColor(1, 1, 1)
					text:SetText(count)
				else
					icon:SetVertexColor(HOLYWARD_BUFF_TRACKER_ABSENT_SHADE, HOLYWARD_BUFF_TRACKER_ABSENT_SHADE, HOLYWARD_BUFF_TRACKER_ABSENT_SHADE)
					text:SetText("")
					BuffGroupExpanded[slot] = nil
					BuffGroupExpireAt[slot] = nil
				end
				Holyward_UpdateBuffGroupPopup(slot, matches)
			else
				BuffGroupExpanded[slot] = nil
				BuffGroupExpireAt[slot] = nil
				Holyward_UpdateBuffGroupPopup(slot, nil)
			end
		elseif icon and text and HolywardConfig.BuffTrackerEnabled[slot] then
			icon:SetTexture(category.Icon)

			local present, expiration, duration = false, nil, nil
			if category.Weapon then
				local hasMainHand, mainHandExpirationMs = GetWeaponEnchantInfo()
				if hasMainHand then
					present = true
					duration = mainHandExpirationMs / 1000
					expiration = GetTime() + duration
				end
			else
				present, expiration, duration = Holyward_FindBuffOccurrence(category.Match, category.Occurrence)
			end

			if present then
				if expiration then
					local remaining = expiration - GetTime()
					local total = (duration and duration > 0) and duration or remaining
					local fraction = 1
					if total > 0 then
						fraction = remaining / total
						if fraction < 0 then
							fraction = 0
						elseif fraction > 1 then
							fraction = 1
						end
					end
					local shade = HOLYWARD_BUFF_TRACKER_ABSENT_SHADE + (1 - HOLYWARD_BUFF_TRACKER_ABSENT_SHADE) * fraction
					icon:SetVertexColor(shade, shade, shade)
					local remainingInt = floor(remaining)
					if remainingInt < 0 then
						remainingInt = 0
					end
					local minutes = floor(remainingInt / 60)
					if minutes > 0 then
						text:SetText(minutes .. "m")
					else
						text:SetText(mod(remainingInt, 60) .. "s")
					end
				else
					icon:SetVertexColor(1, 1, 1)
					text:SetText("")
				end
			else
				icon:SetVertexColor(HOLYWARD_BUFF_TRACKER_ABSENT_SHADE, HOLYWARD_BUFF_TRACKER_ABSENT_SHADE, HOLYWARD_BUFF_TRACKER_ABSENT_SHADE)
				text:SetText("")
			end
		end
	end
end

------------------------------------------------------------------------------------------------------
-- ABILITY TRACKER (separate movable window): a fixed WeakAuras-style row of square game icons for
-- cooldowns, target-nominative DoTs/debuffs, and (once specific procs are confirmed) procs.
--
-- Type 3 (cooldown) entries poll GetSpellCooldown directly: gray + seconds-remaining while on CD,
-- full color + blank while ready. Every other tracked type reads the SpellTimer array that the rest
-- of the addon already maintains (no separate aura polling): full color + seconds-remaining while
-- an entry with a matching name is active, gray + blank otherwise. Type 6 (proc) entries get the
-- same color/text treatment plus a pulsing gold border while active, to draw the eye.
------------------------------------------------------------------------------------------------------

-- Ordered by spell-table index: 8 cooldowns (Fade, Fear Ward, Power Infusion, Inner Focus, Pain
-- Spike, Psychic Scream, Chastise, Ascendance), then Enlighten's proc (index 29 -- one merged slot
-- per user request: gray until the "Enlightened" buff procs, then glowing; the talent's own 1min
-- cooldown, index 23, is no longer a tracker slot but stays available in the timer list), then 4
-- durations (Shackle Undead, Weakened Soul, Devouring Plague, Shadow Word: Pain) then 2 more procs
-- (Purifying Flames, Searing Light). Global (not local) so the config-tab sync code, which is
-- defined earlier in this file, can read it too without hitting the local-declared-too-late upvalue
-- trap documented elsewhere in this file.
-- Slot 14 tracks Purifying Flames (Holy Fire's proc buff, index 31) instead of Holy Fire's own burn
-- DoT (index 28) -- the user asked to prioritize the buff over the DoT. Index 28 stays defined in
-- the spell table (still eligible for the dynamic timer list) but isn't a fixed Ability Tracker slot.
HOLYWARD_ABILITY_TRACKER = { 1, 2, 3, 4, 5, 24, 25, 26, 29, 8, 17, 6, 27, 31, 30, 33, 15 }

local HOLYWARD_ABILITY_TRACKER_ABSENT_SHADE = 0.35

-- Target-nominative entries (a non-empty .Target) only count as "active" against whichever unit is
-- currently targeted -- otherwise a DoT still ticking on some other, now-deselected mob would keep
-- this slot lit forever. Self-only entries (.Target == "") match on name alone.
local function Holyward_FindActiveTimer(name)
	for i = 1, table.getn(SpellTimer), 1 do
		if SpellTimer[i].Name == name then
			if SpellTimer[i].Target == nil or SpellTimer[i].Target == "" or SpellTimer[i].Target == UnitName("target") then
				return SpellTimer[i]
			end
		end
	end
	return nil
end

function Holyward_UpdateAbilityTracker()
	Holyward_LayoutAbilityTracker()
	local pulse = 0.4 + 0.6 * math.abs(math.sin(GetTime() * 4))
	for slot = 1, table.getn(HOLYWARD_ABILITY_TRACKER), 1 do
		local spellIndex = HOLYWARD_ABILITY_TRACKER[slot]
		local entry = HOLYWARD_SPELL_TABLE[spellIndex]
		local slotFrame = Holyward_CachedGlobal("HolywardAbilityTracker" .. slot)
		local icon = Holyward_CachedGlobal("HolywardAbilityTracker" .. slot .. "Icon")
		local text = Holyward_CachedGlobal("HolywardAbilityTracker" .. slot .. "Text")
		local glow = slotFrame and slotFrame.holywardGlow

		if icon and text and glow and HolywardConfig.AbilityTrackerEnabled[slot] then
			icon:SetTexture(entry.Icon or "Interface\\Icons\\INV_Misc_QuestionMark")

			local colored = false
			local remaining = 0
			local showRemaining = false
			if entry.Type == 3 then
				-- Cooldown-kind: colored+blank when ready, gray+seconds-left while on CD. Item-based
				-- cooldowns (entry.Item, e.g. Mana Potion) have no spell ID to query -- read the item's
				-- own cooldown off whichever tier is currently in bags instead, and stay gray+blank
				-- (not "ready") if none is carried at all, since there's nothing to use.
				local start, duration = 0, 0
				local usable = true
				if entry.Item then
					if ManaPotionCache.dirty then
						ManaPotionCache.bag, ManaPotionCache.slot = Holyward_ScanBagsForNames(entry.Item)
						ManaPotionCache.dirty = false
					end
					if ManaPotionCache.bag then
						start, duration = GetContainerItemCooldown(ManaPotionCache.bag, ManaPotionCache.slot)
					else
						usable = false
					end
				elseif entry.ID then
					start, duration = GetSpellCooldown(entry.ID, BOOKTYPE_SPELL)
				end
				if start and start > 0 and duration and duration > 1.5 then
					remaining = floor(start + duration - GetTime())
					showRemaining = true
				elseif usable then
					colored = true
				end
			elseif entry.Type == 6 then
				-- Proc-kind: not player-cast, so it's read live off the player's own aura list
				-- (same lookup the Buff Tracker uses) instead of the cast-detected SpellTimer array.
				-- The slot keeps its static icon in both states (gray when absent, glowing when up)
				-- per user request -- no live-aura icon swap.
				local present, expiration = Holyward_FindBuffOccurrence(entry.Name, 1)
				if present then
					colored = true
					if expiration then
						remaining = floor(expiration - GetTime())
						showRemaining = true
					end
				end
			elseif entry.AuraTrack then
				-- Same live-aura presence read as Type 6, opted into by a plain self-buff (Inner Fire)
				-- instead of an actual Type change -- keeps its Type 0 elsewhere (Buff Menu cast,
				-- SpellManagement's cast-detection loop) untouched, and skips the proc glow below since
				-- a steady-state buff you refresh occasionally isn't an "act now" proc.
				local present, expiration = Holyward_FindBuffOccurrence(entry.Name, 1)
				if present then
					colored = true
					if expiration then
						remaining = floor(expiration - GetTime())
						showRemaining = true
					end
				end
			else
				-- Duration-kind (debuff-on-target, etc.): gray+blank when absent, colored+seconds-
				-- remaining while active.
				local timer = Holyward_FindActiveTimer(entry.Name)
				if timer then
					colored = true
					remaining = floor(timer.TimeMax - GetTime())
					showRemaining = true
				end
			end

			if colored then
				icon:SetVertexColor(1, 1, 1)
			else
				icon:SetVertexColor(HOLYWARD_ABILITY_TRACKER_ABSENT_SHADE, HOLYWARD_ABILITY_TRACKER_ABSENT_SHADE, HOLYWARD_ABILITY_TRACKER_ABSENT_SHADE)
			end
			if showRemaining and remaining > 0 then
				text:SetText(remaining .. "s")
			else
				text:SetText("")
			end

			if entry.Type == 6 and colored then
				glow:Show()
				glow:SetAlpha(pulse)
			else
				glow:Hide()
			end
		end
	end
end

------------------------------------------------------------------------------------------------------
-- SETTINGS: applies the config toggles exposed on the Botones/Trackeos config tabs. Called once at
-- login (Holyward_Initialize) and again by each checkbox's OnClick so the change is instant.
------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------
-- SATELLITE COLLAPSE: left-clicking the sphere retracts the four satellite buttons into it (a short
-- slide+fade animation toward the sphere's center), and clicking again expands them back out to
-- wherever they were. Replaces the old per-button show/hide config checkboxes.
------------------------------------------------------------------------------------------------------

local SATELLITE_ANIM_TIME = 0.25
local SatelliteAnim = nil

-- Fallback rest offsets (the XML defaults) for a button whose live offset was never captured --
-- e.g. logging in already collapsed and expanding before ever collapsing manually.
local SATELLITE_BUTTONS = {
	{ name = "HolywardMountButton", x = -44, y = 0 },
	{ name = "HolywardUtilityMenuButton", x = 0, y = 44 },
	{ name = "HolywardBuffMenuButton", x = 44, y = 0 },
	{ name = "HolywardConsumablesButton", x = 0, y = -44 },
	{ name = "HolywardProfessionsButton", x = 31, y = 31 },
}

-- Caches each satellite's frame reference on first lookup instead of paying a getglobal() hash
-- lookup every single animation frame (the anim reflows all 4 buttons every tick for 0.25s) -- part
-- of the fix for the small stutter the user reported when the buttons expand.
local function Holyward_SatelliteFrame(entry)
	if not entry.frame then
		entry.frame = getglobal(entry.name)
	end
	return entry.frame
end

-- Records each satellite's current offset from the sphere's center so the expand animation returns
-- it to exactly where the user had dragged it (positions aren't otherwise persisted, so after a
-- fresh login this just captures the XML defaults).
local function Holyward_CaptureSatelliteOffsets()
	local sphereX, sphereY = HolywardButton:GetCenter()
	if not sphereX then
		return
	end
	for i = 1, table.getn(SATELLITE_BUTTONS), 1 do
		local button = Holyward_SatelliteFrame(SATELLITE_BUTTONS[i])
		if button then
			local bx, by = button:GetCenter()
			if bx then
				button.holywardRestX = bx - sphereX
				button.holywardRestY = by - sphereY
			end
		end
	end
end

-- Runs every frame from Holyward_OnUpdate while an animation is active.
function Holyward_UpdateSatelliteAnim()
	if not SatelliteAnim then
		return
	end
	local t = (GetTime() - SatelliteAnim.start) / SATELLITE_ANIM_TIME
	if t > 1 then
		t = 1
	end
	local frac = t
	if SatelliteAnim.mode == "collapse" then
		frac = 1 - t
	end
	if SatelliteAnim.mode == "expand" and SatelliteAnim.shown and SatelliteAnim.shown < table.getn(SATELLITE_BUTTONS) then
		SatelliteAnim.shown = SatelliteAnim.shown + 1
		local button = Holyward_SatelliteFrame(SATELLITE_BUTTONS[SatelliteAnim.shown])
		if button then
			button:Show()
		end
	end
	for i = 1, table.getn(SATELLITE_BUTTONS), 1 do
		local entry = SATELLITE_BUTTONS[i]
		local button = Holyward_SatelliteFrame(entry)
		if button then
			local rx = button.holywardRestX or entry.x
			local ry = button.holywardRestY or entry.y
			-- No ClearAllPoints here: this frame only ever carries one "CENTER" anchor, and
			-- re-SetPoint-ing the same point type replaces it outright -- clearing first was pure
			-- overhead paid every tick of the animation for no behavioral difference.
			button:SetPoint("CENTER", "HolywardButton", "CENTER", rx * frac, ry * frac)
			button:SetAlpha(frac)
		end
	end
	if t >= 1 then
		for i = 1, table.getn(SATELLITE_BUTTONS), 1 do
			local entry = SATELLITE_BUTTONS[i]
			local button = Holyward_SatelliteFrame(entry)
			if button then
				if SatelliteAnim.mode == "collapse" then
					button:Hide()
				elseif not button:IsShown() then
					-- Safety net for the staggered Show() above: at a very low framerate, the
					-- animation can reach t>=1 before all 5 got their turn -- make sure none are left
					-- permanently hidden regardless of how choppy the animation was.
					button:Show()
				end
				-- Leave the frame parked at its rest position with full alpha either way, so the
				-- next Show() (or the next expand) starts from a sane state.
				button:ClearAllPoints()
				button:SetPoint("CENTER", "HolywardButton", "CENTER", button.holywardRestX or entry.x, button.holywardRestY or entry.y)
				button:SetAlpha(1)
			end
		end
		SatelliteAnim = nil
	end
end

function Holyward_ToggleSatellites()
	if SatelliteAnim then
		return
	end
	if HolywardConfig.SatellitesCollapsed then
		HolywardConfig.SatellitesCollapsed = false
		for i = 1, table.getn(SATELLITE_BUTTONS), 1 do
			local button = Holyward_SatelliteFrame(SATELLITE_BUTTONS[i])
			if button then
				button:SetAlpha(0)
			end
		end
		-- Show() is deferred to Holyward_UpdateSatelliteAnim, one button per frame instead of all 5
		-- in this same tick -- showing several previously-hidden textured frames at once can make the
		-- client do a visible texture-load pass in one go (a small stutter the user reported); alpha
		-- is already 0 so nothing is visible early regardless of when each one actually shows.
		SatelliteAnim = { mode = "expand", start = GetTime(), shown = 0 }
	else
		-- Close any open popup menu first -- its icons anchor to the trigger button being retracted.
		if MenuState.BuffMenuShow then
			Holyward_BuffMenu()
		end
		if MenuState.UtilityMenuShow then
			Holyward_UtilityMenu()
		end
		if MenuState.ConsumablesMenuShow then
			Holyward_ConsumablesButtonClick("LeftButton")
		end
		if MenuState.ProfessionsMenuShow then
			Holyward_ProfessionsButtonClick("LeftButton")
		end
		Holyward_CaptureSatelliteOffsets()
		HolywardConfig.SatellitesCollapsed = true
		SatelliteAnim = { mode = "collapse", start = GetTime() }
	end
end

-- Login-time application of the saved state: no animation, just snap to collapsed/expanded.
function Holyward_ApplySatelliteState()
	Holyward_CaptureSatelliteOffsets()
	for i = 1, table.getn(SATELLITE_BUTTONS), 1 do
		local button = Holyward_SatelliteFrame(SATELLITE_BUTTONS[i])
		if button then
			if HolywardConfig.SatellitesCollapsed then
				button:Hide()
			else
				button:Show()
			end
		end
	end
end

-- Called once at login and again by the General tab's slider so the change is instant.
function Holyward_ApplySphereSize()
	local size = HolywardConfig.SphereSize or 58
	HolywardButton:SetWidth(size)
	HolywardButton:SetHeight(size)
end

function Holyward_ApplyTrackerVisibility()
	if HolywardConfig.ShowBuffTracker then
		HolywardBuffTrackerFrame:Show()
	else
		HolywardBuffTrackerFrame:Hide()
	end
	if HolywardConfig.ShowAbilityTracker then
		HolywardAbilityTrackerFrame:Show()
	else
		HolywardAbilityTrackerFrame:Hide()
	end
end

------------------------------------------------------------------------------------------------------
-- TRACKER GRID LAYOUT: repositions a tracker's fixed slots into a perRow x rows grid (perRow==count
-- is one full row; perRow==1 is a single vertical column hugging one side) and resizes the container
-- to fit. Shared by the Buff Tracker and Ability Tracker so "how many per row" is one slider each,
-- not bespoke math per window.
------------------------------------------------------------------------------------------------------

-- Reads a tracker's live geometry from config (prefix "Ability" or "Buff"), with the original
-- 30px icon / 4px column gap / 14px row gap as fallbacks.
local function Holyward_TrackerGeometry(prefix)
	local size = HolywardConfig[prefix .. "TrackerIconSize"] or 30
	local sx = HolywardConfig[prefix .. "TrackerSpacingX"]
	if sx == nil then
		sx = 4
	end
	local sy = HolywardConfig[prefix .. "TrackerSpacingY"]
	if sy == nil then
		sy = 14
	end
	return size, sx, sy
end

-- Disabled slots (per enabledArray, from the Buffs/Trackeos config tabs) are hidden AND skipped when
-- assigning grid positions, so the remaining visible icons pack together with no empty holes -- the
-- grid is sized off the visible count, not the raw slot count. orderArray (optional) is a
-- permutation of 1..count: grid position k renders base slot orderArray[k], which is how dragging
-- an icon over another changes the on-screen order without touching frame identity.
-- centered: each row's icons are centered within the container width (text-align:center style) --
-- the Ability Tracker uses this, the Buff Tracker stays left-aligned.
-- liveSizing: skip the container's snap-to-fit resize because the user is actively dragging the
-- resize grip -- the icons reflow inside whatever size the drag currently is, and the snap happens
-- on release.
-- iconSize/spacingX/spacingY: per-tracker geometry from the options window. innerIconRatio: for
-- slots whose icon texture is a fixed-size CENTER-anchored child inside a decorative border (the
-- Buff Tracker's 26-in-32 inset), the inner texture is rescaled by this ratio; nil skips it (the
-- Ability Tracker's icons are setAllPoints and follow the slot frame automatically).
local function Holyward_LayoutTrackerGrid(slotPrefix, containerName, count, perRow, enabledArray, orderArray, centered, liveSizing, iconSize, spacingX, spacingY, innerIconRatio)
	iconSize = iconSize or 30
	spacingX = spacingX or 4
	spacingY = spacingY or 14
	local colPitch = iconSize + spacingX
	local rowPitch = iconSize + spacingY

	local visible = 0
	for i = 1, count, 1 do
		if not enabledArray or enabledArray[i] then
			visible = visible + 1
		end
	end
	if visible < 1 then
		visible = 1
	end

	if not perRow or perRow < 1 then
		perRow = 1
	elseif perRow > visible then
		perRow = visible
	end
	local rows = ceil(visible / perRow)

	local container = Holyward_CachedGlobal(containerName)

	-- Snapped grid width: side pads (3+3) + perRow icons with gaps between (not after the last).
	local snapWidth = perRow * colPitch - spacingX + 6

	-- The width rows center against: the snapped grid width normally, or the live-dragged width
	-- mid-resize so the icons track the user's hand.
	local layoutWidth = snapWidth
	if liveSizing and container and container.GetWidth then
		local current = container:GetWidth()
		if current and current > 0 then
			layoutWidth = current
		end
	end

	local placed = 0
	for k = 1, count, 1 do
		local i = orderArray and orderArray[k] or k
		local slot = i and Holyward_CachedGlobal(slotPrefix .. i)
		if slot then
			if not enabledArray or enabledArray[i] then
				placed = placed + 1
				local col = mod(placed - 1, perRow)
				local row = floor((placed - 1) / perRow)
				local x
				if centered then
					-- Icons actually in this row (the last row may be partial): center that run.
					-- For a full row this collapses to the standard 3px inset.
					local iconsInRow = visible - row * perRow
					if iconsInRow > perRow then
						iconsInRow = perRow
					end
					x = (layoutWidth - iconsInRow * colPitch + spacingX) / 2 + col * colPitch
				else
					x = 3 + col * colPitch
				end
				slot:SetWidth(iconSize)
				slot:SetHeight(iconSize)
				if innerIconRatio then
					local inner = Holyward_CachedGlobal(slotPrefix .. i .. "Icon")
					if inner then
						inner:SetWidth(floor(iconSize * innerIconRatio))
						inner:SetHeight(floor(iconSize * innerIconRatio))
					end
				end
				if slot.holywardGlow then
					-- The action-button border ring's art is padded: vanilla pairs a 62px border
					-- with a 36px button (~1.7x), so scale the glow with the icon at that ratio.
					slot.holywardGlow:SetWidth(floor(iconSize * 1.7))
					slot.holywardGlow:SetHeight(floor(iconSize * 1.7))
				end
				slot:ClearAllPoints()
				-- Anchor to the already-resolved container frame object, not its name string --
				-- passing a name here makes the engine re-resolve it internally on every call.
				slot:SetPoint(
					"TOPLEFT",
					container or containerName,
					"TOPLEFT",
					x,
					-3 - row * rowPitch
				)
				slot:Show()
			else
				slot:Hide()
			end
		end
	end

	if container and not liveSizing then
		-- Snug fit: height is top pad (3) + full rows + the last row's icon and its countdown text
		-- strip (which lives inside the vertical gap), with no dead band below.
		container:SetWidth(snapWidth)
		container:SetHeight((rows - 1) * rowPitch + iconSize + spacingY + 3)
	end
end

-- Shows/hides each tracker's translucent dark panel per config -- called at login and from the
-- options toggles.
function Holyward_ApplyTrackerBackgrounds()
	local buffBg = getglobal("HolywardBuffTrackerFrameBackground")
	if buffBg then
		if HolywardConfig.BuffTrackerBackground then
			buffBg:Show()
		else
			buffBg:Hide()
		end
	end
	local abilityBg = getglobal("HolywardAbilityTrackerFrameBackground")
	if abilityBg then
		if HolywardConfig.AbilityTrackerBackground then
			abilityBg:Show()
		else
			abilityBg:Hide()
		end
	end
end

-- Slot counts are hardcoded rather than read from HOLYWARD_BUFF_TRACKER/HOLYWARD_ABILITY_TRACKER --
-- those tables are declared `local` further down the file, so a function defined up here would
-- capture them before that local exists and see a global (nil) instead (same upvalue-ordering trap
-- as elsewhere in this file). Both counts must stay in sync with those tables' lengths by hand.
-- Called every tracker update tick (not just when the perRow slider moves) so a checkbox toggle in
-- the Buffs/Trackeos tab reflows the grid within a second, without needing every one of those
-- checkboxes to individually call back into layout code.
function Holyward_LayoutBuffTracker(liveSizing)
	-- The 1s tracker tick also calls this with no args; while the user is actively dragging the
	-- resize grip that must not snap the frame out from under their cursor.
	if HolywardBuffTrackerFrame and HolywardBuffTrackerFrame.holywardSizing then
		liveSizing = true
	end
	local size, sx, sy = Holyward_TrackerGeometry("Buff")
	Holyward_LayoutTrackerGrid(
		"HolywardBuffTracker",
		"HolywardBuffTrackerFrame",
		14,
		HolywardConfig.BuffTrackerPerRow,
		HolywardConfig.BuffTrackerEnabled,
		nil,
		false,
		liveSizing,
		size,
		sx,
		sy,
		26 / 32
	)
end

function Holyward_LayoutAbilityTracker(liveSizing)
	if HolywardAbilityTrackerFrame and HolywardAbilityTrackerFrame.holywardSizing then
		liveSizing = true
	end
	local size, sx, sy = Holyward_TrackerGeometry("Ability")
	Holyward_LayoutTrackerGrid(
		"HolywardAbilityTracker",
		"HolywardAbilityTrackerFrame",
		17,
		HolywardConfig.AbilityTrackerPerRow,
		HolywardConfig.AbilityTrackerEnabled,
		HolywardConfig.AbilityTrackerOrder,
		true,
		liveSizing,
		size,
		sx,
		sy
	)
end

-- Repairs HolywardConfig.AbilityTrackerOrder into a valid permutation of 1..17 -- drops duplicates
-- and out-of-range values, then appends whatever base slots are missing in ascending order. Keeps a
-- stale saved order (from before a slot was added) working instead of silently dropping slots.
function Holyward_NormalizeAbilityOrder()
	local order = HolywardConfig.AbilityTrackerOrder
	if type(order) ~= "table" then
		order = {}
		HolywardConfig.AbilityTrackerOrder = order
	end
	local seen = {}
	local cleaned = {}
	for k = 1, table.getn(order), 1 do
		local v = order[k]
		if type(v) == "number" and v >= 1 and v <= 17 and not seen[v] then
			seen[v] = true
			table.insert(cleaned, v)
		end
	end
	for i = 1, 17, 1 do
		if not seen[i] then
			table.insert(cleaned, i)
		end
	end
	for k = 1, 17, 1 do
		order[k] = cleaned[k]
	end
	while table.getn(order) > 17 do
		table.remove(order)
	end
end

------------------------------------------------------------------------------------------------------
-- ABILITY TRACKER DRAG-TO-REORDER: press an icon and sweep the cursor over another icon to swap
-- their display positions -- the grid reflows live under the cursor; release to finish. The window
-- itself still moves by dragging its background strip (the padding/gaps between icons), and the
-- master lock disables both.
------------------------------------------------------------------------------------------------------

local AbilityDragBase = nil

-- Shared by both trackers' resize grips: while the user drags, derive how many columns fit the
-- current width (at that tracker's configured icon size/spacing) and reflow the icons live
-- (liveSizing layout, no snap) whenever that count changes. geomPrefix is "Ability" or "Buff".
local function Holyward_TrackerSizing_OnUpdate(container, perRowKey, maxPerRow, layoutFn, geomPrefix)
	local width = container:GetWidth()
	if not width then
		return
	end
	local size, sx = Holyward_TrackerGeometry(geomPrefix)
	local per = floor((width - 6 + sx) / (size + sx))
	if per < 1 then
		per = 1
	elseif per > maxPerRow then
		per = maxPerRow
	end
	if per ~= HolywardConfig[perRowKey] then
		HolywardConfig[perRowKey] = per
	end
	layoutFn(true)
end

local function Holyward_CursorInFrame(frame, inflate)
	if not frame or not frame:IsVisible() then
		return false
	end
	local x, y = GetCursorPosition()
	local scale = frame:GetEffectiveScale()
	x = x / scale
	y = y / scale
	local left, right = frame:GetLeft(), frame:GetRight()
	local top, bottom = frame:GetTop(), frame:GetBottom()
	if not left or not right or not top or not bottom then
		return false
	end
	inflate = inflate or 0
	return x >= (left - inflate) and x <= (right + inflate) and y >= (bottom - inflate) and y <= (top + inflate)
end

local function Holyward_AbilityDrag_OnUpdate()
	-- Mid-resize the same OnUpdate drives the live reflow instead of drag-reorder.
	if HolywardAbilityTrackerFrame.holywardSizing then
		Holyward_TrackerSizing_OnUpdate(HolywardAbilityTrackerFrame, "AbilityTrackerPerRow", 17, Holyward_LayoutAbilityTracker, "Ability")
		return
	end
	if not AbilityDragBase then
		return
	end
	if HolywardConfig.Locked then
		AbilityDragBase = nil
		return
	end
	-- Safety net for a missed OnMouseUp (released outside the UI): cancel once the cursor strays
	-- well past the tracker window.
	if not Holyward_CursorInFrame(HolywardAbilityTrackerFrame, 80) then
		AbilityDragBase = nil
		return
	end

	local order = HolywardConfig.AbilityTrackerOrder
	for k = 1, 15, 1 do
		local base = order[k]
		if base and base ~= AbilityDragBase and HolywardConfig.AbilityTrackerEnabled[base] then
			local frame = Holyward_CachedGlobal("HolywardAbilityTracker" .. base)
			if frame and Holyward_CursorInFrame(frame, 0) then
				local from = nil
				for j = 1, 15, 1 do
					if order[j] == AbilityDragBase then
						from = j
						break
					end
				end
				if from then
					order[from], order[k] = order[k], order[from]
					Holyward_LayoutAbilityTracker()
				end
				return
			end
		end
	end
end

local function Holyward_AbilitySlot_OnMouseDown()
	if arg1 == "LeftButton" and this.holywardAbilityBase and not (HolywardConfig and HolywardConfig.Locked) then
		AbilityDragBase = this.holywardAbilityBase
	end
end

local function Holyward_AbilitySlot_OnMouseUp()
	if AbilityDragBase then
		AbilityDragBase = nil
		-- Keep the options window's Tracking list in sync with the new on-screen order.
		if Holyward_RefreshOptions then
			Holyward_RefreshOptions()
		end
	end
end

-- One-time wiring, called from Holyward_Initialize once the slot frames exist. Besides the drag
-- handlers this also restyles each slot at runtime:
--  * the countdown text moves INSIDE the icon, hugging its bottom edge (WeakAuras-style), instead
--    of hanging below the frame;
--  * the proc glow becomes the classic gold action-button ring (Interface\Buttons\
--    UI-ActionButton-Border with ADD blend -- the exact texture+blend vanilla's own ActionButton
--    uses for its gold border, so it's guaranteed present), drawn on OVERLAY so its soft inner
--    edge sits on the icon's borders. The old XML Glow texture (a flat gold square) starts hidden
--    and is simply never shown again.
-- Real spell tooltip when the slot's spell is known (Type 3/4 cooldowns, castable ones); otherwise
-- just the plain name (procs with no .ID, Weakened Soul, Mana Potion) -- always something, not just
-- while the slot happens to be active/colored.
local function Holyward_AbilitySlot_OnEnter()
	local base = this.holywardAbilityBase
	local spellIndex = base and HOLYWARD_ABILITY_TRACKER[base]
	local entry = spellIndex and HOLYWARD_SPELL_TABLE[spellIndex]
	if not entry then
		return
	end
	GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
	if entry.ID then
		GameTooltip:SetSpell(entry.ID, BOOKTYPE_SPELL)
	else
		GameTooltip:AddLine(entry.Name or "", 1.0, 1.0, 1.0)
	end
	GameTooltip:Show()
end

local function Holyward_AbilitySlot_OnLeave()
	GameTooltip:Hide()
end

function Holyward_SetupAbilityDrag()
	for base = 1, 17, 1 do
		local frame = getglobal("HolywardAbilityTracker" .. base)
		if frame then
			frame.holywardAbilityBase = base
			frame:EnableMouse(true)
			frame:SetScript("OnMouseDown", Holyward_AbilitySlot_OnMouseDown)
			frame:SetScript("OnMouseUp", Holyward_AbilitySlot_OnMouseUp)
			frame:SetScript("OnEnter", Holyward_AbilitySlot_OnEnter)
			frame:SetScript("OnLeave", Holyward_AbilitySlot_OnLeave)

			local text = getglobal("HolywardAbilityTracker" .. base .. "Text")
			if text then
				text:ClearAllPoints()
				text:SetPoint("BOTTOM", frame, "BOTTOM", 0, 2)
			end

			local glow = frame:CreateTexture(nil, "OVERLAY")
			glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
			glow:SetBlendMode("ADD")
			glow:SetPoint("CENTER", frame, "CENTER", 0, 0)
			glow:Hide()
			frame.holywardGlow = glow
		end
	end
	HolywardAbilityTrackerFrame:SetScript("OnUpdate", Holyward_AbilityDrag_OnUpdate)
end

------------------------------------------------------------------------------------------------------
-- TRACKER RESIZE GRIPS: a small grab notch in each tracker's bottom-left corner. Dragging it
-- resizes the window; the per-row count follows the width live (icons reflow under the cursor) and
-- the frame snaps to an exact grid fit on release. The visual and StartSizing pattern are copied
-- from AceGUI's own bottom-right sizer (AceGUIContainer-Frame.lua), which is proven on this client;
-- only the corner and the texture mirroring differ.
------------------------------------------------------------------------------------------------------

local function Holyward_TrackerGrip_OnMouseDown()
	if HolywardConfig and HolywardConfig.Locked then
		return
	end
	local container = this:GetParent()
	container.holywardSizing = true
	container:StartSizing("BOTTOMLEFT")
end

local function Holyward_TrackerGrip_OnMouseUp()
	local container = this:GetParent()
	container:StopMovingOrSizing()
	if container.holywardSizing then
		container.holywardSizing = nil
		if container.holywardSnapLayout then
			container.holywardSnapLayout()
		end
	end
end

local function Holyward_CreateTrackerGrip(container, snapLayout)
	container:SetResizable(true)
	if container.SetMinResize then
		-- Loose floor (roughly one small icon) -- the live per-row clamp does the real limiting,
		-- and icon size is user-configurable now so a hardcoded exact minimum would drift.
		container:SetMinResize(24, 24)
	end
	container.holywardSnapLayout = snapLayout

	local grip = CreateFrame("Frame", nil, container)
	grip:SetWidth(16)
	grip:SetHeight(16)
	grip:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 0, 0)
	grip:SetFrameLevel(container:GetFrameLevel() + 5)
	grip:EnableMouse(true)
	grip:SetScript("OnMouseDown", Holyward_TrackerGrip_OnMouseDown)
	grip:SetScript("OnMouseUp", Holyward_TrackerGrip_OnMouseUp)

	local tex = grip:CreateTexture(nil, "OVERLAY")
	tex:SetAllPoints(grip)
	tex:SetTexture("Interface\\Cursor\\Item")
	-- AceGUI's bottom-RIGHT grip uses (1,0,1,0); mirror horizontally for the left corner.
	tex:SetTexCoord(0, 1, 1, 0)
end

local function Holyward_BuffTracker_OnUpdate()
	if HolywardBuffTrackerFrame.holywardSizing then
		Holyward_TrackerSizing_OnUpdate(HolywardBuffTrackerFrame, "BuffTrackerPerRow", 14, Holyward_LayoutBuffTracker, "Buff")
	end
end

function Holyward_SetupTrackerResize()
	Holyward_CreateTrackerGrip(HolywardAbilityTrackerFrame, Holyward_LayoutAbilityTracker)
	Holyward_CreateTrackerGrip(HolywardBuffTrackerFrame, Holyward_LayoutBuffTracker)
	HolywardBuffTrackerFrame:SetScript("OnUpdate", Holyward_BuffTracker_OnUpdate)
end

-- Re-centers every movable Holyward window -- the sphere, the timer list anchor, and the two
-- tracker bars -- in case one got dragged off-screen. Extends the original `/holyward recall`
-- behavior (sphere + timer button only) to the trackers added this session.
function Holyward_RecenterWindows()
	HolywardButton:ClearAllPoints()
	HolywardButton:SetPoint("CENTER", "UIParent", "CENTER", 0, 0)
	HolywardSpellTimerButton:ClearAllPoints()
	HolywardSpellTimerButton:SetPoint("CENTER", "UIParent", "CENTER", 120, 240)
	HolywardBuffTrackerFrame:ClearAllPoints()
	HolywardBuffTrackerFrame:SetPoint("CENTER", "UIParent", "CENTER", 0, 200)
	HolywardAbilityTrackerFrame:ClearAllPoints()
	HolywardAbilityTrackerFrame:SetPoint("CENTER", "UIParent", "CENTER", 0, 140)
end

------------------------------------------------------------------------------------------------------
-- LOAD / UPDATE / EVENT
------------------------------------------------------------------------------------------------------

function Holyward_OnLoad()
	this:RegisterEvent("PLAYER_ENTERING_WORLD")
	this:RegisterEvent("PLAYER_LEAVING_WORLD")
	-- ClassicAPI event: fires once per successful cast (instant or cast-time alike) with the real
	-- spell name/rank already resolved, replacing the old UseAction/CastSpell/CastSpellByName hook
	-- trio entirely -- simpler and can't miss or misfire on a failed/interrupted cast.
	this:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	this:RegisterEvent("LEARNED_SPELL_IN_TAB")
	this:RegisterEvent("PLAYER_REGEN_ENABLED")
	-- Invalidates the Mana Potion bag-scan cache (see ManaPotionCache below) -- bags only actually
	-- change on this event, so there's no reason to re-scan every second regardless.
	this:RegisterEvent("BAG_UPDATE")
	this:RegisterEvent("CHAT_MSG_WHISPER")

	HolywardButton:RegisterForDrag("LeftButton")
	HolywardButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	HolywardButton:SetFrameLevel(1)

	SlashCmdList["HolywardCommand"] = Holyward_SlashHandler
	SLASH_HolywardCommand1 = "/holyward"
end

-- Polled every frame by Holyward_Variable_Frame until saved variables are ready.
-- Called from Holyward_Variable_Frame's XML OnUpdate (Holyward.xml) every single frame until
-- SavedVariables are ready. Once there's a final answer -- either loaded, or confirmed not a Priest
-- (a character's class never changes mid-session, so that answer can't go stale) -- unregister the
-- OnUpdate via `this` (the frame the XML handler is bound to) so this stops polling 60 times a
-- second, forever, for nothing (2026-08-24 fix).
function Holyward_LoadVariables()
	if Loaded then
		return
	end
	if UnitClass("player") ~= HOLYWARD_UNIT_PRIEST then
		this:SetScript("OnUpdate", nil)
		return
	end

	Holyward_Initialize()
	Loaded = true
	this:SetScript("OnUpdate", nil)
end

local LastFullUpdate = 0
local UpdateStage = 0
local textTimersDisplay = ""

function Holyward_OnUpdate()
	if (not Loaded) and UnitClass("player") ~= HOLYWARD_UNIT_PRIEST then
		return
	end

	-- Deferred from Holyward_Initialize (see HolywardInitialize.lua's own comment) -- runs exactly
	-- once, on the first real OnUpdate tick after login/reload, by which point the client has had at
	-- least one full frame to lay out the satellite buttons for real.
	if Holyward_NeedsSatelliteStateApply then
		Holyward_NeedsSatelliteStateApply = false
		Holyward_ApplySatelliteState()
	end

	Holyward_UpdateSatelliteAnim()
	Holyward_UpdateSkin()

	-- CONFIRMED (2026-09-02): this ran unconditionally, every single frame -- without the
	-- TimersEnabled check, it would re-show the button the very next frame after the throttled
	-- once-a-second block below calls HideUIPanel for the master switch, undoing the hide almost
	-- instantly.
	if HolywardConfig.TimersEnabled and not HolywardSpellTimerButton:IsVisible() then
		ShowUIPanel(HolywardSpellTimerButton)
	end

	local curTime = GetTime()

	-- Buff menu auto-fade
	if MenuState.BuffShow then
		if curTime >= MenuState.AlphaBuffVar and MenuState.AlphaBuffMenu > 0 and not MenuState.BuffVisible then
			MenuState.AlphaBuffVar = curTime + 0.1
			for i = 1, table.getn(BuffMenuCreate), 1 do
				getglobal("HolywardBuffMenu" .. i):SetAlpha(MenuState.AlphaBuffMenu)
			end
			MenuState.AlphaBuffMenu = MenuState.AlphaBuffMenu - 0.1
		end
		if MenuState.AlphaBuffMenu <= 0 then
			Holyward_BuffMenu()
		end
	end

	-- Utility menu auto-fade
	if MenuState.UtilityShow then
		if curTime >= MenuState.AlphaUtilityVar and MenuState.AlphaUtilityMenu > 0 and not MenuState.UtilityVisible then
			MenuState.AlphaUtilityVar = curTime + 0.1
			for i = 1, table.getn(UtilityMenuCreate), 1 do
				getglobal("HolywardUtilityMenu" .. i):SetAlpha(MenuState.AlphaUtilityMenu)
			end
			MenuState.AlphaUtilityMenu = MenuState.AlphaUtilityMenu - 0.1
		end
		if MenuState.AlphaUtilityMenu <= 0 then
			Holyward_UtilityMenu()
		end
	end

	-- Consumables menu auto-fade
	if MenuState.ConsumablesShow then
		if curTime >= MenuState.AlphaConsumablesVar and MenuState.AlphaConsumablesMenu > 0 then
			MenuState.AlphaConsumablesVar = curTime + 0.1
			for i = 1, table.getn(ConsumablesMenuCreate), 1 do
				ConsumablesMenuCreate[i]:SetAlpha(MenuState.AlphaConsumablesMenu)
			end
			MenuState.AlphaConsumablesMenu = MenuState.AlphaConsumablesMenu - 0.1
		end
		if MenuState.AlphaConsumablesMenu <= 0 then
			Holyward_ConsumablesButtonClick("LeftButton")
		end
	end

	-- Professions menu auto-fade
	if MenuState.ProfessionsShow then
		if curTime >= MenuState.AlphaProfessionsVar and MenuState.AlphaProfessionsMenu > 0 then
			MenuState.AlphaProfessionsVar = curTime + 0.1
			for i = 1, table.getn(ProfessionsMenuCreate), 1 do
				ProfessionsMenuCreate[i]:SetAlpha(MenuState.AlphaProfessionsMenu)
			end
			MenuState.AlphaProfessionsMenu = MenuState.AlphaProfessionsMenu - 0.1
		end
		if MenuState.AlphaProfessionsMenu <= 0 then
			Holyward_ProfessionsButtonClick("LeftButton")
		end
	end

	-- Timer sweep/render, throttled to once a second and then SPREAD across the next few frames
	-- instead of all landing in the same one -- PollCooldowns (bag scan + ~30 spell-table cooldown
	-- checks), UpdateBuffTracker (14 slots), UpdateAbilityTracker (17 slots), and the timer sweep
	-- all bundled into a single frame once a second was a real, periodic stutter (confirmed by the
	-- user 2026-08-24) once the trackers grew to their current slot counts. Each stage still
	-- effectively refreshes about once a second; only WHEN within that second it runs is staggered.
	if (curTime - LastFullUpdate) >= 1 then
		LastFullUpdate = curTime
		UpdateStage = 1
	end

	if UpdateStage == 1 then
		Holyward_PollCooldowns()
		Holyward_UpdateMenuCooldowns()
		Holyward_CheckConsumablesAutoCollapse()
		UpdateStage = 2
	elseif UpdateStage == 2 then
		Holyward_UpdateBuffTracker()
		UpdateStage = 3
	elseif UpdateStage == 3 then
		Holyward_UpdateAbilityTracker()
		UpdateStage = 4
	elseif UpdateStage == 4 then
		ClearGraphicalTimers()
		textTimersDisplay = ""
		for index = 1, table.getn(SpellTimer), 1 do
			if SpellTimer[index] then
				if curTime <= SpellTimer[index].TimeMax then
					textTimersDisplay, SpellGroup, GraphicalTimer, TimerTable =
						Holyward_DisplayTimer(textTimersDisplay, index, SpellGroup, SpellTimer, GraphicalTimer, TimerTable)
				end

				if curTime >= (SpellTimer[index].TimeMax - 0.5) then
					SpellTimer, TimerTable = Holyward_RetraitTimerParIndex(index, SpellTimer, TimerTable)
					break
				end

				-- Drop Type 4/5 timers early if the target no longer shows the effect (resist, dispel...)
				if
					SpellTimer[index]
					and (SpellTimer[index].Type == 4 or SpellTimer[index].Type == 5)
					and SpellTimer[index].Target == UnitName("target")
				then
					if
						curTime >= ((SpellTimer[index].TimeMax - SpellTimer[index].Time) + 1.5)
						and not Holyward_UnitHasEffect("target", SpellTimer[index].Name)
					then
						SpellTimer, TimerTable = Holyward_RetraitTimerParIndex(index, SpellTimer, TimerTable)
						break
					end
				end
			end
		end

		-- Rendered once here, after the sweep loop above has finished building the full
		-- GraphicalTimer list for this tick (2026-08-24 fix -- see the comment in
		-- Holyward_DisplayTimer for why it used to run once per active timer instead of once total).
		if HolywardConfig.Graphical then
			HolywardAfficheTimer(GraphicalTimer, TimerTable)
		end

		-- Master switch (2026-09-02) added in front of the pre-existing ShowSpellTimers/Graphical
		-- OR: without it, HolywardSpellTimerButton stayed visible whenever Graphical was true
		-- (the default) no matter what ShowSpellTimers said -- TimersEnabled now overrides both and
		-- is the one condition that reliably forces the else-branch HideUIPanel below.
		if HolywardConfig.TimersEnabled and (HolywardConfig.ShowSpellTimers or HolywardConfig.Graphical) then
			if not HolywardConfig.Graphical then
				textTimersDisplay = Holyward_MsgAddColor(textTimersDisplay)
				HolywardListSpells:SetText(textTimersDisplay)
			else
				HolywardListSpells:SetText("")
			end
			for i = 4, table.getn(SpellGroup.Name) do
				SpellGroup.Visible[i] = false
			end
		else
			if HolywardSpellTimerButton:IsVisible() then
				HolywardListSpells:SetText("")
				HideUIPanel(HolywardSpellTimerButton)
			end
		end
		UpdateStage = 0
	end
end

function Holyward_OnEvent(event)
	if (not Loaded) or UnitClass("player") ~= HOLYWARD_UNIT_PRIEST then
		return
	end

	if event == "UNIT_SPELLCAST_SUCCEEDED" and arg1 == "player" then
		SpellCast.Name = arg4
		-- SuperWoW extends UnitExists with a real GUID as the 2nd return; nil when SuperWoW isn't
		-- loaded, in which case Holyward_TargetsMatch just falls back to the name+level heuristic.
		local exists, guid = UnitExists("target")
		if exists then
			SpellCast.TargetUnit = "target"
			SpellCast.TargetGUID = guid
			SpellCast.TargetName = UnitName("target")
			SpellCast.TargetLevel = UnitLevel("target") or ""
		else
			SpellCast.TargetUnit = nil
			SpellCast.TargetGUID = nil
			SpellCast.TargetName = ""
			SpellCast.TargetLevel = ""
		end
		Holyward_SpellManagement()
	elseif event == "LEARNED_SPELL_IN_TAB" then
		Holyward_SpellSetup()
		Holyward_CreateMenu()
	elseif event == "BAG_UPDATE" then
		ManaPotionCache.dirty = true
	elseif event == "CHAT_MSG_WHISPER" then
		if HolywardConfig.AutoInvite and arg1 and arg2 then
			-- Trim leading/trailing whitespace, then match the whole (lowercased) message against
			-- the keyword list -- an exact match, not "contains", so a real sentence that happens to
			-- include one of these words ("I'm invited to...") doesn't trigger an invite by accident.
			local trimmed = string.gsub(string.lower(arg1), "^%s*(.-)%s*$", "%1")
			if HOLYWARD_AUTOINVITE_KEYWORDS[trimmed] then
				InviteByName(arg2)
			end
		end
	elseif event == "PLAYER_REGEN_ENABLED" then
		SpellGroup, SpellTimer, TimerTable = Holyward_RetraitTimerCombat(SpellGroup, SpellTimer, TimerTable)
	end
end

------------------------------------------------------------------------------------------------------
-- MAIN SPHERE
------------------------------------------------------------------------------------------------------

-- Left-click casts a fixed signature spell (Fade); any other click toggles the config window.
function Holyward_Toggle(button)
	if button == "LeftButton" then
		Holyward_ToggleSatellites()
		return
	elseif Holyward_IsOptionsVisible() then
		Holyward_HideOptions()
		return
	else
		if HolywardConfig.SM then
			Holyward_Msg("!!! Short Messages : <brightGreen>On", "USER")
		end
		Holyward_ShowOptions()
		return
	end
end

function Holyward_OnDragStart(button)
	-- Every draggable Holyward frame funnels through here, so the master lock lives in one place.
	if HolywardConfig and HolywardConfig.Locked then
		return
	end
	button:StartMoving()
end

function Holyward_OnDragStop(button)
	button:StopMovingOrSizing()
end

------------------------------------------------------------------------------------------------------
-- ITEM USE (Hearthstone, Mount, and the Consumables button's live bag scan)
------------------------------------------------------------------------------------------------------

function Holyward_UseItem(type, button)
	if type == "Hearthstone" and button == "RightButton" then
		if C_Container and C_Container.PlayerHasHearthstone and C_Container.UseHearthstone then
			if C_Container.PlayerHasHearthstone() then
				C_Container.UseHearthstone()
			else
				Holyward_Msg("No Hearthstone found in bags.", "USER")
			end
			return
		end
		-- Fallback when ClassicAPI isn't loaded
		for bag = 0, 4, 1 do
			for slot = 1, GetContainerNumSlots(bag), 1 do
				local link = GetContainerItemLink(bag, slot)
				if link and string.find(link, "Hearthstone") then
					UseContainerItem(bag, slot)
					return
				end
			end
		end
		Holyward_Msg("No Hearthstone found in bags.", "USER")
	end
end

-- Scans all bags for the highest-index (best) name match against an ordered { "Item Name", ... }
-- list, or against a list of { Name = "Item Name", ... } records (HOLYWARD_DRINK's shape).
-- No caching: re-scanned on demand at click time, which is cheap enough for a once-in-a-while click.
-- Defensive against a nil/holed entry either way -- explicit type() check rather than relying on
-- string-metatable-index-returns-nil, since that's the one thing that was actually crashing.
-- GLOBAL (not local): Holyward_UpdateAbilityTracker (defined earlier in this file, for the Mana
-- Potion item-cooldown slot) calls this. A local here would resolve as a global-nil upvalue at that
-- earlier call site, same lexical-ordering trap as elsewhere in this file.
function Holyward_ScanBagsForNames(names)
	local bestIndex, bestBag, bestSlot = 0, nil, nil
	if not names then
		return nil, nil, 0
	end
	for bag = 0, 4, 1 do
		for slot = 1, GetContainerNumSlots(bag), 1 do
			local link = GetContainerItemLink(bag, slot)
			if link then
				for i = 1, table.getn(names), 1 do
					local entry = names[i]
					if entry then
						local entryName = entry
						if type(entry) == "table" then
							entryName = entry.Name
						end
						if entryName and i > bestIndex and string.find(link, entryName, 1, true) then
							bestIndex, bestBag, bestSlot = i, bag, slot
						end
					end
				end
			end
		end
	end
	return bestBag, bestSlot, bestIndex
end

-- Finds the first bag item whose link contains `substring` (plain match) -- used for Elixir/Flask,
-- where there are too many named variants to enumerate an ordered tier list.
local function Holyward_ScanBagsForSubstring(substring)
	for bag = 0, 4, 1 do
		for slot = 1, GetContainerNumSlots(bag), 1 do
			local link = GetContainerItemLink(bag, slot)
			if link and string.find(link, substring, 1, true) then
				return bag, slot
			end
		end
	end
	return nil, nil
end

function Holyward_UseMount(button)
	if button == "RightButton" then
		Holyward_UseItem("Hearthstone", "RightButton")
		return
	end
	-- Some races/TWoW mounts are a learned spell (e.g. Tauren's Riding Turtle) rather than a bag item.
	if HOLYWARD_SPELL_TABLE[22].ID then
		CastSpell(HOLYWARD_SPELL_TABLE[22].ID, "spell")
		return
	end
	local bag, slot = Holyward_ScanBagsForNames(HOLYWARD_MOUNT)
	if bag then
		UseContainerItem(bag, slot)
	else
		Holyward_Msg("No mount found (checked spellbook and bags).", "USER")
	end
end

------------------------------------------------------------------------------------------------------
-- CONSUMABLES MENU (dynamic: rebuilt from current bag contents each time it's opened, unlike the
-- Buff/Utility menus which are built once from known spells)
------------------------------------------------------------------------------------------------------

-- Slot order 1-7. Names = ordered tier list (best-in-bag wins); Substring = plain-text search
-- instead (Elixir/Flask have too many named variants to enumerate). Label is the fallback tooltip
-- text for a category with nothing found, and the row label in Options -> General.
local HOLYWARD_CONSUMABLE_CATEGORY = {
	{ Names = HOLYWARD_DRINK, Icon = "Interface\\AddOns\\Holyward\\UI\\Water12-01", Label = "Water" },
	{ Names = HOLYWARD_FOOD, Icon = "Interface\\Icons\\INV_Misc_Food_11", Label = "Food" },
	{ Names = HOLYWARD_HEALING_POTION, Icon = "Interface\\Icons\\INV_Potion_54", Label = "Healing Potion" },
	{ Names = HOLYWARD_MANA_POTION, Icon = "Interface\\Icons\\INV_Potion_76", Label = "Mana Potion" },
	{ Substring = "Elixir", Icon = "Interface\\Icons\\INV_Potion_92", Label = "Elixir" },
	{ Substring = "Flask", Icon = "Interface\\Icons\\INV_Potion_62", Label = "Flask" },
	{ Names = HOLYWARD_BANDAGE, Icon = "Interface\\Icons\\INV_Misc_Bandage_08", Label = "Bandage" },
}

-- Global accessors so the Options tab (a separate file) can read a category's icon/label for its
-- checkbox row without needing HOLYWARD_CONSUMABLE_CATEGORY itself to be global.
function Holyward_GetConsumableCategoryIcon(i)
	return HOLYWARD_CONSUMABLE_CATEGORY[i] and HOLYWARD_CONSUMABLE_CATEGORY[i].Icon
end

function Holyward_GetConsumableCategoryLabel(i)
	return HOLYWARD_CONSUMABLE_CATEGORY[i] and HOLYWARD_CONSUMABLE_CATEGORY[i].Label
end

-- Every distinct item in the bags matching this category, not just the single best one --
-- { name, icon, bag, slot } per match. Backs the expanded per-category popup list.
-- Two stacks of the same item (e.g. water split across two bags) collapse into a single match
-- with a summed count instead of showing twice (confirmed 2026-08-24) -- deduped by the item link
-- itself, which is identical for two stacks of the same item since consumables never carry
-- per-stack enchant/suffix data. The first stack found is kept as the bag/slot to use; once it's
-- used up, the next menu rebuild picks up whatever's left in the other stack.
local function Holyward_CollectConsumableMatches(category)
	local matches = {}
	local byLink = {}
	for bag = 0, 4, 1 do
		for slot = 1, GetContainerNumSlots(bag), 1 do
			local link = GetContainerItemLink(bag, slot)
			if link then
				local matched = false
				if category.Substring then
					matched = string.find(link, category.Substring, 1, true) ~= nil
				elseif category.Names then
					for i = 1, table.getn(category.Names), 1 do
						local entry = category.Names[i]
						local entryName = type(entry) == "table" and entry.Name or entry
						if entryName and string.find(link, entryName, 1, true) then
							matched = true
							break
						end
					end
				end
				if matched then
					local itemTexture, itemCount = GetContainerItemInfo(bag, slot)
					itemCount = itemCount or 1
					local existing = byLink[link]
					if existing then
						existing.count = existing.count + itemCount
					else
						local match = { name = link, icon = itemTexture, bag = bag, slot = slot, count = itemCount }
						byLink[link] = match
						table.insert(matches, match)
					end
				end
			end
		end
	end
	return matches
end

local ConsumablesGroupExpanded = {}
local ConsumablesGroupExpireAt = {}
local ConsumablesGroupPopups = {}
local HOLYWARD_CONSUMABLES_POPUP_MAX = 12
-- Popup icons are 30px; spacing must be >= that or consecutive icons overlap -- confirmed the real
-- bug behind the "too cramped" screenshot (2026-08-24): the previous value (26) was smaller than
-- the icon itself, a 4px overlap every step. Separate from HOLYWARD_CONSUMABLES_POPUP_GAP below,
-- which is the (much smaller) gap from the category button to the first popup only -- the user's
-- follow-up made clear those two distances should NOT move together.
local HOLYWARD_CONSUMABLES_POPUP_GAP = 0
local HOLYWARD_CONSUMABLES_POPUP_SPACING = 33
-- Auto-collapse an expanded category list after this many seconds with no further toggle (per the
-- user, 2026-08-24). Checked once a second via Holyward_CheckConsumablesAutoCollapse below.
local HOLYWARD_CONSUMABLES_EXPAND_TIMEOUT = 6

-- Real bag-item tooltip (name, stats, flavor text -- the same one you'd see hovering it in your
-- actual bags) for an expanded popup icon; bag/slot are stashed on the frame by the update
-- function below since the same pooled popup frame is reused for a different item each rebuild.
-- Always shows something on hover (per the user, 2026-08-24): falls back to the category's generic
-- label on the rare frame where bag/slot haven't been set yet instead of showing nothing.
function Holyward_ConsumablesPopup_OnEnter(frame)
	if not frame then
		return
	end
	GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
	if frame.serenityBag and frame.serenitySlot then
		GameTooltip:SetBagItem(frame.serenityBag, frame.serenitySlot)
	else
		local category = frame.serenityCategorySlot and HOLYWARD_CONSUMABLE_CATEGORY[frame.serenityCategorySlot]
		GameTooltip:AddLine(category and category.Label or "", 1.0, 1.0, 1.0)
	end
	GameTooltip:Show()
end

function Holyward_ConsumablesPopup_OnClick(frame)
	if frame and frame.serenityBag and frame.serenitySlot then
		UseContainerItem(frame.serenityBag, frame.serenitySlot)
	end
end

-- Anchors the j-th popup for `slot` off its category button, stacking further in
-- HolywardConfig.ConsumablesExpandDirection with each index -- created lazily, one small pool per
-- category slot, and parked in the TOOLTIP strata so the expanded list always renders above every
-- other Holyward window (per the user's request, 2026-08-24).
local function Holyward_GetConsumablesGroupPopup(slot, j)
	if not ConsumablesGroupPopups[slot] then
		ConsumablesGroupPopups[slot] = {}
	end
	if not ConsumablesGroupPopups[slot][j] then
		local slotFrame = getglobal("HolywardConsumablesMenu" .. slot)
		if not slotFrame then
			return nil
		end
		local popup = CreateFrame("Button", nil, slotFrame)
		popup:SetWidth(30)
		popup:SetHeight(30)
		popup:SetFrameStrata("TOOLTIP")
		popup:EnableMouse(true)
		popup:RegisterForClicks("LeftButtonUp")
		local tex = popup:CreateTexture(nil, "ARTWORK")
		tex:SetAllPoints(popup)
		popup.serenityIcon = tex
		local countText = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		countText:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -1, 1)
		popup.serenityCount = countText
		popup.serenityCategorySlot = slot
		popup:SetScript("OnEnter", function()
			Holyward_ConsumablesPopup_OnEnter(this)
		end)
		popup:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
		popup:SetScript("OnClick", function()
			Holyward_ConsumablesPopup_OnClick(this)
		end)
		popup:Hide()
		ConsumablesGroupPopups[slot][j] = popup
	end
	return ConsumablesGroupPopups[slot][j]
end

local function Holyward_UpdateConsumablesGroupPopup(slot, matches)
	local shown = 0
	if ConsumablesGroupExpanded[slot] and matches then
		shown = table.getn(matches)
		if shown > HOLYWARD_CONSUMABLES_POPUP_MAX then
			shown = HOLYWARD_CONSUMABLES_POPUP_MAX
		end
	end
	local direction = HolywardConfig.ConsumablesExpandDirection or "UP"
	local slotFrame = Holyward_CachedGlobal("HolywardConsumablesMenu" .. slot)
	for j = 1, HOLYWARD_CONSUMABLES_POPUP_MAX, 1 do
		local popup = Holyward_GetConsumablesGroupPopup(slot, j)
		if popup then
			if j <= shown then
				local match = matches[j]
				popup.serenityIcon:SetTexture(match.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
				popup.serenityBag = match.bag
				popup.serenitySlot = match.slot
				-- Only show a number for an actual stack (2+) -- a single item doesn't need "1" on it.
				popup.serenityCount:SetText(match.count > 1 and match.count or "")
				popup:ClearAllPoints()
				-- j=1 sits right against the category button (HOLYWARD_CONSUMABLES_POPUP_GAP); every
				-- later item is a full HOLYWARD_CONSUMABLES_POPUP_SPACING pitch further out. Kept as
				-- two separate constants per the user's explicit follow-up (2026-08-24): the gap to
				-- the button should shrink, but the pitch between items themselves needs room to NOT
				-- overlap, not less.
				local offset = HOLYWARD_CONSUMABLES_POPUP_GAP + (j - 1) * HOLYWARD_CONSUMABLES_POPUP_SPACING
				if direction == "DOWN" then
					popup:SetPoint("TOP", slotFrame, "BOTTOM", 0, -offset)
				elseif direction == "LEFT" then
					popup:SetPoint("RIGHT", slotFrame, "LEFT", -offset, 0)
				elseif direction == "RIGHT" then
					popup:SetPoint("LEFT", slotFrame, "RIGHT", offset, 0)
				else
					popup:SetPoint("BOTTOM", slotFrame, "TOP", 0, offset)
				end
				popup:Show()
			else
				popup.serenityBag = nil
				popup.serenitySlot = nil
				popup:Hide()
			end
		end
	end
end

-- Collapses every category's expanded popup list -- called when the whole Consumables menu closes,
-- so nothing is left floating once the trigger button's own menu is gone.
local function Holyward_CollapseAllConsumablesGroups()
	for slot = 1, table.getn(HOLYWARD_CONSUMABLE_CATEGORY), 1 do
		if ConsumablesGroupExpanded[slot] then
			ConsumablesGroupExpanded[slot] = nil
			ConsumablesGroupExpireAt[slot] = nil
			Holyward_UpdateConsumablesGroupPopup(slot, nil)
		end
	end
end

-- Called once a second from Holyward_PollCooldowns (see Holyward_OnUpdate's stage machine) --
-- auto-collapses any expanded category list that's been sitting open past its timeout (per the
-- user, 2026-08-24), same behavior as the Buff Tracker's own group popups.
function Holyward_CheckConsumablesAutoCollapse()
	local now = GetTime()
	for slot = 1, table.getn(HOLYWARD_CONSUMABLE_CATEGORY), 1 do
		if ConsumablesGroupExpanded[slot] and ConsumablesGroupExpireAt[slot] and now >= ConsumablesGroupExpireAt[slot] then
			ConsumablesGroupExpanded[slot] = nil
			ConsumablesGroupExpireAt[slot] = nil
			Holyward_UpdateConsumablesGroupPopup(slot, nil)
		end
	end
end

-- Both left and right click toggle the same thing now (2026-08-24): expand/collapse everything in
-- that category. Use a specific item by clicking its icon in the expanded list instead.
function Holyward_ConsumablesCategoryClick(slot)
	local category = HOLYWARD_CONSUMABLE_CATEGORY[slot]
	if not category then
		return
	end
	ConsumablesGroupExpanded[slot] = not ConsumablesGroupExpanded[slot]
	ConsumablesGroupExpireAt[slot] = ConsumablesGroupExpanded[slot] and (GetTime() + HOLYWARD_CONSUMABLES_EXPAND_TIMEOUT) or nil
	local matches = ConsumablesGroupExpanded[slot] and Holyward_CollectConsumableMatches(category) or nil
	Holyward_UpdateConsumablesGroupPopup(slot, matches)
end

-- Real tooltip for the category's main icon: the best-found item's own tooltip when something is
-- in bags, otherwise just the category name (nothing to show a real tooltip for).
function Holyward_ConsumablesCategoryTooltip(button)
	local slot = button and button.serenityConsumableSlot
	local category = slot and HOLYWARD_CONSUMABLE_CATEGORY[slot]
	if not category then
		return
	end
	local found = ConsumablesFound[slot]
	if found then
		GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
		GameTooltip:SetBagItem(found.Bag, found.Slot)
		GameTooltip:Show()
	else
		Holyward_BuildTooltip(button, "ConsumablesItem", "ANCHOR_RIGHT", nil, category.Label)
	end
end

-- Unlike the Buff/Utility menus (which hide a slot entirely until the spell is known), enabled
-- categories always show here -- greyed out when that category isn't currently in your bags, full
-- color when it is. Same "always visible, gray vs color" convention as the Buff Tracker, since bag
-- contents are a constantly-changing situational state, not a permanent unlock like a talent/spell.
-- Categories turned off in Options -> General are skipped entirely (hidden, not just greyed).
local function Holyward_BuildConsumablesMenu()
	ConsumablesMenuCreate = {}
	ConsumablesFound = {}

	local position = nil
	for slot = 1, table.getn(HOLYWARD_CONSUMABLE_CATEGORY), 1 do
		local category = HOLYWARD_CONSUMABLE_CATEGORY[slot]
		local button = getglobal("HolywardConsumablesMenu" .. slot)
		if not (HolywardConfig.ConsumablesEnabled and HolywardConfig.ConsumablesEnabled[slot] == false) then
			local bag, itemSlot
			if category.Substring then
				bag, itemSlot = Holyward_ScanBagsForSubstring(category.Substring)
			else
				bag, itemSlot = Holyward_ScanBagsForNames(category.Names)
			end

			button.serenityConsumableSlot = slot
			button:SetNormalTexture(category.Icon)
			-- SetVertexColor is a Texture method, not a Button one -- has to go on the NormalTexture
			-- object itself, which is what threw "attempt to call method 'SetVertexColor' (a nil value)".
			local buttonTexture = button:GetNormalTexture()
			if bag then
				ConsumablesFound[slot] = { Bag = bag, Slot = itemSlot }
				if buttonTexture then
					buttonTexture:SetVertexColor(1, 1, 1)
				end
			else
				if buttonTexture then
					buttonTexture:SetVertexColor(0.35, 0.35, 0.35)
				end
			end

			button:ClearAllPoints()
			if position == nil then
				button:SetPoint("CENTER", "HolywardConsumablesButton", "CENTER", 3000, 3000)
			else
				button:SetPoint(
					"CENTER",
					"HolywardConsumablesMenu" .. position,
					"CENTER",
					(36 / HolywardConfig.ConsumablesMenuPos) * 31,
					0
				)
			end
			position = slot
			table.insert(ConsumablesMenuCreate, button)
		else
			if ConsumablesGroupExpanded[slot] then
				ConsumablesGroupExpanded[slot] = nil
				ConsumablesGroupExpireAt[slot] = nil
				Holyward_UpdateConsumablesGroupPopup(slot, nil)
			end
			button:Hide()
		end
	end

	for i = 1, table.getn(ConsumablesMenuCreate), 1 do
		ShowUIPanel(ConsumablesMenuCreate[i])
	end
end

-- Left-click: open/close the dynamic menu (rescanning bags on each open). Right-click: drink the
-- best water immediately, bypassing the menu.
function Holyward_ConsumablesButtonClick(button)
	if button == "RightButton" then
		local bag, slot = Holyward_ScanBagsForNames(HOLYWARD_DRINK)
		if bag then
			UseContainerItem(bag, slot)
		else
			Holyward_Msg("No drink found in bags.", "USER")
		end
		return
	end

	MenuState.ConsumablesMenuShow = not MenuState.ConsumablesMenuShow
	if not MenuState.ConsumablesMenuShow then
		MenuState.ConsumablesShow = false
		Holyward_CollapseAllConsumablesGroups()
		if table.getn(ConsumablesMenuCreate) > 0 then
			ConsumablesMenuCreate[1]:ClearAllPoints()
			ConsumablesMenuCreate[1]:SetPoint("CENTER", "HolywardConsumablesButton", "CENTER", 3000, 3000)
		end
		MenuState.AlphaConsumablesMenu = 1
	else
		Holyward_BuildConsumablesMenu()
		MenuState.ConsumablesShow = true
		for i = 1, table.getn(ConsumablesMenuCreate), 1 do
			ConsumablesMenuCreate[i]:SetAlpha(1)
		end
		if table.getn(ConsumablesMenuCreate) > 0 then
			ConsumablesMenuCreate[1]:ClearAllPoints()
			-- Straight right of the trigger icon, not diagonal (unlike Buff/Utility menus which open
			-- up-and-over) -- this one wasn't asked to angle.
			ConsumablesMenuCreate[1]:SetPoint(
				"CENTER",
				"HolywardConsumablesButton",
				"CENTER",
				(36 / HolywardConfig.ConsumablesMenuPos) * 31,
				0
			)
		end
		MenuState.AlphaConsumablesVar = GetTime() + 6
	end
end

------------------------------------------------------------------------------------------------------
-- PROFESSIONS MENU (dynamic: rebuilt from the current spellbook each time it's opened, like the
-- Consumables Menu is rebuilt from bag contents)
------------------------------------------------------------------------------------------------------

-- Confirmed via user screenshots 2026-08-22: on this client every profession/secondary-skill
-- quick-use button (Find Minerals, Find Trees, Smelting, Engineering, Survival, plus passives like
-- Dodge) lives inside the "General" tab itself -- NOT in a dedicated per-profession tab the way
-- stock vanilla organizes it. A dedicated profession tab, when one exists, instead lists every
-- individual crafting recipe as its own spellbook entry (e.g. repeated "Bronze Bar" icons from a
-- Blacksmithing/Engineering recipe list) -- clutter, not a quick-menu, so those tabs are skipped
-- entirely rather than scanned. Looked up by name rather than assumed to be tab index 1, in case
-- tab order ever differs.
local HOLYWARD_PROFESSIONS_MAX = 8

-- Custom art for specific known entries (user-provided, confirmed 2026-08-22) -- anything not
-- listed here keeps its plain spellbook icon from GetSpellTexture.
local HOLYWARD_PROFESSION_ICON_OVERRIDE = {
	["Find Minerals"] = "Interface\\AddOns\\Holyward\\UI\\ProfessionFindMinerals-01",
	["Mining"] = "Interface\\AddOns\\Holyward\\UI\\ProfessionMining-01",
	["Engineering"] = "Interface\\AddOns\\Holyward\\UI\\ProfessionEngineering-01",
	["Smelting"] = "Interface\\AddOns\\Holyward\\UI\\ProfessionSmelting-01",
	["Find Trees"] = "Interface\\AddOns\\Holyward\\UI\\ProfessionFindTrees-01",
	["Survival"] = "Interface\\AddOns\\Holyward\\UI\\ProfessionSurvival-01",
}

-- Explicit allowlist rather than "everything in the General tab" -- General also holds Attack,
-- Shoot Wand, and the character's racial (e.g. Berserking), none of which are professions/skills,
-- and got shown as menu icons before this (confirmed by the user 2026-08-22). Covers every standard
-- vanilla primary/secondary profession, their gathering "Find X" tracking spells, and the
-- TurtleWoW-custom entries confirmed via the user's own screenshots (Survival, Smelting, Find Trees).
-- If another profession-related spell is still missing, add its exact name here.
local HOLYWARD_PROFESSION_NAMES = {
	["Alchemy"] = true, ["Blacksmithing"] = true, ["Enchanting"] = true, ["Engineering"] = true,
	["Leatherworking"] = true, ["Tailoring"] = true, ["Mining"] = true,
	["Cooking"] = true, ["First Aid"] = true, ["Fishing"] = true, ["Survival"] = true,
	["Smelting"] = true, ["Find Minerals"] = true, ["Find Herbs"] = true, ["Find Trees"] = true,
	["Find Fish"] = true,
}

-- Scans the "General" spellbook tab and returns an ordered list of { Name, Slot, Icon }. Slot is
-- the real spellbook slot (not a HOLYWARD_SPELL_TABLE index -- professions aren't in that table at
-- all, there's no fixed list to key off since which professions exist is per-character).
local function Holyward_ScanProfessionSpells()
	local found = {}
	local numTabs = GetNumSpellTabs()
	for tab = 1, numTabs, 1 do
		local tabName, _, offset, numSpells = GetSpellTabInfo(tab)
		if tabName == "General" and offset and numSpells then
			for i = 1, numSpells, 1 do
				local slot = offset + i
				local spellName = GetSpellName(slot, BOOKTYPE_SPELL)
				if spellName and HOLYWARD_PROFESSION_NAMES[spellName] then
					table.insert(found, {
						Name = spellName,
						Slot = slot,
						Icon = HOLYWARD_PROFESSION_ICON_OVERRIDE[spellName] or GetSpellTexture(slot, BOOKTYPE_SPELL),
					})
				end
			end
			break
		end
	end
	return found
end

-- Square icons with the UI-Quickslot2 border throughout, same as every other menu in Holyward
-- (Buff/Utility/Consumables) -- individual entries render whatever HOLYWARD_PROFESSION_ICON_OVERRIDE
-- (above) or the plain spellbook icon provides; the border framing itself is unchanged.
local function Holyward_BuildProfessionsMenu()
	ProfessionsMenuCreate = {}
	ProfessionsFound = Holyward_ScanProfessionSpells()

	local position = nil
	for slot = 1, HOLYWARD_PROFESSIONS_MAX, 1 do
		local button = getglobal("HolywardProfessionsMenu" .. slot)
		local entry = ProfessionsFound[slot]
		if button and entry then
			-- Both textures must be set -- the XML's HighlightTexture is a hardcoded QuestionMark
			-- placeholder, so leaving it untouched showed that (ADD-blended, right under the cursor)
			-- on hover instead of the real icon (looked like a broken square+"?" glued to the mouse).
			button:SetNormalTexture(entry.Icon or "Interface\\Icons\\INV_Misc_QuestionMark")
			button:SetHighlightTexture(entry.Icon or "Interface\\Icons\\INV_Misc_QuestionMark")
			button.holywardSpellSlot = entry.Slot
			button.holywardName = entry.Name
			button:ClearAllPoints()
			if position == nil then
				button:SetPoint("CENTER", "HolywardProfessionsButton", "CENTER", 3000, 3000)
			else
				button:SetPoint(
					"CENTER",
					"HolywardProfessionsMenu" .. position,
					"CENTER",
					(36 / HolywardConfig.ProfessionsMenuPos) * 31,
					0
				)
			end
			position = slot
			button:Show()
			table.insert(ProfessionsMenuCreate, button)
		elseif button then
			button:Hide()
		end
	end

	for i = 1, table.getn(ProfessionsMenuCreate), 1 do
		ShowUIPanel(ProfessionsMenuCreate[i])
	end
end

-- Left-click only: opens/closes the dynamic menu (rescanning the spellbook on each open). No
-- right/middle-click behavior -- unlike Consumables' "drink water" shortcut, there's no obvious
-- single profession to fast-cast.
function Holyward_ProfessionsButtonClick(button)
	MenuState.ProfessionsMenuShow = not MenuState.ProfessionsMenuShow
	if not MenuState.ProfessionsMenuShow then
		MenuState.ProfessionsShow = false
		if table.getn(ProfessionsMenuCreate) > 0 then
			ProfessionsMenuCreate[1]:ClearAllPoints()
			ProfessionsMenuCreate[1]:SetPoint("CENTER", "HolywardProfessionsButton", "CENTER", 3000, 3000)
		end
		MenuState.AlphaProfessionsMenu = 1
		return
	end

	Holyward_BuildProfessionsMenu()
	if table.getn(ProfessionsMenuCreate) == 0 then
		MenuState.ProfessionsMenuShow = false
		Holyward_Msg("No known professions found in your spellbook.", "USER")
		return
	end
	MenuState.ProfessionsShow = true
	for i = 1, table.getn(ProfessionsMenuCreate), 1 do
		ProfessionsMenuCreate[i]:SetAlpha(1)
	end
	ProfessionsMenuCreate[1]:ClearAllPoints()
	ProfessionsMenuCreate[1]:SetPoint(
		"CENTER",
		"HolywardProfessionsButton",
		"CENTER",
		(36 / HolywardConfig.ProfessionsMenuPos) * 31,
		0
	)
	MenuState.AlphaProfessionsVar = GetTime() + 6
end

function Holyward_ProfessionsCast(slot)
	local entry = ProfessionsFound[slot]
	-- Second guard against casting a passive (crashed the client once already, see the scan-time
	-- filter above) -- belt and suspenders in case a stale/edge-case entry ever slips through.
	if entry and entry.Slot and not IsPassiveSpell(entry.Slot, BOOKTYPE_SPELL) then
		CastSpell(entry.Slot, "spell")
	end
	MenuState.AlphaProfessionsMenu = 1
	MenuState.AlphaProfessionsVar = GetTime() + 3
end

-- Real spell tooltip (name, description, cast time...) via the native SetSpell -- richer than the
-- plain-name AddLine used elsewhere, and the only option here since the spellbook slot is the only
-- identity a profession entry has (no HOLYWARD_SPELL_TABLE index to look a fixed name up from).
-- Plain name via Holyward_BuildTooltip, same as every other menu in Holyward -- GameTooltip:SetSpell
-- (tried first) rendered as a bare square with a "?" on hover for some entries (2026-08-22), so this
-- avoids it entirely rather than chase why.
function Holyward_ProfessionsTooltip(button)
	if button and button.holywardName then
		Holyward_BuildTooltip(button, "ProfessionsItem", "ANCHOR_RIGHT", nil, button.holywardName)
	end
end

------------------------------------------------------------------------------------------------------
-- BUFF MENU
------------------------------------------------------------------------------------------------------

-- Index into HOLYWARD_SPELL_TABLE for each of the buff-menu slots, in display order. Inner Focus
-- (index 4) removed from the menu per user request -- still in the spell table, just not listed
-- here, so HolywardBuffMenu5/6's XML art was reassigned to Shadowform/Enlighten and the old
-- HolywardBuffMenu7 button (now unused) was deleted.
local HOLYWARD_BUFF_MENU_SPELL = { 9, 11, 13, 15, 16, 23 }
-- Right-click alternate ("Prayer of ...") for the ranked group buffs; nil = no alternate.
local HOLYWARD_BUFF_MENU_ALT = { [9] = 10, [11] = 12, [13] = 14 }

-- Index into HOLYWARD_SPELL_TABLE for each of the 6 utility-menu slots: Fear Ward, Mind Soothe,
-- Levitate, Lightwell, Resurrection, Mind Vision.
local HOLYWARD_UTILITY_MENU_SPELL = { 2, 18, 19, 20, 21, 32 }

-- These spell-table indices already carry hand-drawn Holyward art (Interface\AddOns\Holyward\UI\*,
-- baked into each button's XML NormalTexture/HighlightTexture, pre-bordered to match the addon's
-- visual identity) -- never clobber that with the raw square icon the spellbook reports. Only
-- spells with no matching Holyward asset (currently just Enlighten, a TWoW-only addition) fall
-- through to the live server icon below.
local HOLYWARD_MENU_CUSTOM_ART = {
	[9] = true, -- Fortitude
	[11] = true, -- Divine Spirit
	[13] = true, -- Shadow Protection
	[15] = true, -- Inner Fire
	[4] = true, -- Inner Focus
	[16] = true, -- Shadowform
	[2] = true, -- Fear Ward
	[18] = true, -- Mind Soothe
	[19] = true, -- Levitate
	[20] = true, -- Lightwell
	[21] = true, -- Resurrection
	[32] = true, -- Mind Vision
	[23] = true, -- Enlighten
}

-- Shared by both consolidated menus: builds a {trigger, chain-of-N-icons} popup from a fixed
-- ordered spell-index list, skipping unknown spells (their icon stays parked off-screen) and
-- chain-anchoring each known icon to the previous known one so there are never gaps.
local function Holyward_BuildMenuChain(spellList, iconPrefix, triggerName, posConfig)
	local created = {}
	local position = nil
	for slot = 1, table.getn(spellList), 1 do
		local spellIndex = spellList[slot]
		if HOLYWARD_SPELL_TABLE[spellIndex].ID then
			local button = getglobal(iconPrefix .. slot)
			-- Use the real icon the spellbook reports for this exact server (set by Holyward_SpellSetup
			-- via GetSpellTexture) only for slots without curated Holyward art.
			if HOLYWARD_SPELL_TABLE[spellIndex].Icon and not HOLYWARD_MENU_CUSTOM_ART[spellIndex] then
				button:SetNormalTexture(HOLYWARD_SPELL_TABLE[spellIndex].Icon)
				button:SetHighlightTexture(HOLYWARD_SPELL_TABLE[spellIndex].Icon)
			end
			button:ClearAllPoints()
			if position == nil then
				button:SetPoint("CENTER", triggerName, "CENTER", 3000, 3000)
			else
				button:SetPoint("CENTER", iconPrefix .. position, "CENTER", (36 / posConfig) * 31, 0)
			end
			position = slot
			table.insert(created, button)
		end
	end
	for i = 1, table.getn(created), 1 do
		ShowUIPanel(created[i])
	end
	if table.getn(created) > 0 then
		ShowUIPanel(getglobal(triggerName))
	end
	return created
end

-- Grays out a known menu icon while its spell is on cooldown, full color once it's available again
-- -- no swipe/countdown, just an at-a-glance available-or-not state (matching the Buff Tracker's
-- plain color read instead of the Model+CooldownFrameTemplate swipe, which is fragile on this
-- client and not what the user wants on quick-cast buttons anyway).
local function Holyward_UpdateCooldownIcons(spellList, iconPrefix)
	for slot = 1, table.getn(spellList), 1 do
		local id = HOLYWARD_SPELL_TABLE[spellList[slot]].ID
		if id then
			local button = Holyward_CachedGlobal(iconPrefix .. slot)
			local icon = button and button:GetNormalTexture()
			if icon then
				local start, duration = GetSpellCooldown(id, BOOKTYPE_SPELL)
				if start and start > 0 and duration and duration > 1.5 then
					icon:SetVertexColor(0.35, 0.35, 0.35)
				else
					icon:SetVertexColor(1, 1, 1)
				end
			end
		end
	end
end

function Holyward_UpdateMenuCooldowns()
	Holyward_UpdateCooldownIcons(HOLYWARD_BUFF_MENU_SPELL, "HolywardBuffMenu")
	Holyward_UpdateCooldownIcons(HOLYWARD_UTILITY_MENU_SPELL, "HolywardUtilityMenu")
end

function Holyward_CreateMenu()
	BuffMenuCreate =
		Holyward_BuildMenuChain(HOLYWARD_BUFF_MENU_SPELL, "HolywardBuffMenu", "HolywardBuffMenuButton", HolywardConfig.BuffMenuPos)
	UtilityMenuCreate = Holyward_BuildMenuChain(
		HOLYWARD_UTILITY_MENU_SPELL,
		"HolywardUtilityMenu",
		"HolywardUtilityMenuButton",
		HolywardConfig.UtilityMenuPos
	)
end

function Holyward_BuffMenu(button)
	if button == "MiddleButton" and MenuState.LastBuff ~= 0 then
		Holyward_BuffCast(MenuState.LastBuff)
		return
	end
	MenuState.BuffMenuShow = not MenuState.BuffMenuShow
	if not MenuState.BuffMenuShow then
		MenuState.BuffShow = false
		MenuState.BuffVisible = false
		if table.getn(BuffMenuCreate) > 0 then
			BuffMenuCreate[1]:ClearAllPoints()
			BuffMenuCreate[1]:SetPoint("CENTER", "HolywardBuffMenuButton", "CENTER", 3000, 3000)
		end
		MenuState.AlphaBuffMenu = 1
	else
		MenuState.BuffShow = true
		if button == "RightButton" then
			MenuState.BuffVisible = true
		end
		if table.getn(BuffMenuCreate) == 0 then
			return
		end
		for i = 1, table.getn(BuffMenuCreate), 1 do
			BuffMenuCreate[i]:SetAlpha(1)
		end
		BuffMenuCreate[1]:ClearAllPoints()
		-- Straight right, not diagonal (2026-08-22: the diagonal opening overlapped the Professions
		-- button, which sits up-and-right of the sphere at the same angle this used to open toward).
		BuffMenuCreate[1]:SetPoint("CENTER", "HolywardBuffMenuButton", "CENTER", (36 / HolywardConfig.BuffMenuPos) * 31, 0)
		MenuState.AlphaBuffVar = GetTime() + 6
	end
end

function Holyward_BuffCast(type, click)
	if click == "RightButton" and HOLYWARD_BUFF_MENU_ALT[type] and HOLYWARD_SPELL_TABLE[HOLYWARD_BUFF_MENU_ALT[type]].ID then
		type = HOLYWARD_BUFF_MENU_ALT[type]
	end
	if not HOLYWARD_SPELL_TABLE[type].ID then
		return
	end
	CastSpell(HOLYWARD_SPELL_TABLE[type].ID, "spell")
	MenuState.LastBuff = type
	MenuState.AlphaBuffMenu = 1
	MenuState.AlphaBuffVar = GetTime() + 3
end

------------------------------------------------------------------------------------------------------
-- UTILITY MENU (Fear Ward, Mind Soothe, Levitate, Lightwell, Resurrection)
------------------------------------------------------------------------------------------------------

function Holyward_UtilityMenu(button)
	if button == "MiddleButton" and MenuState.LastUtility ~= 0 then
		Holyward_UtilityCast(MenuState.LastUtility)
		return
	end
	MenuState.UtilityMenuShow = not MenuState.UtilityMenuShow
	if not MenuState.UtilityMenuShow then
		MenuState.UtilityShow = false
		MenuState.UtilityVisible = false
		if table.getn(UtilityMenuCreate) > 0 then
			UtilityMenuCreate[1]:ClearAllPoints()
			UtilityMenuCreate[1]:SetPoint("CENTER", "HolywardUtilityMenuButton", "CENTER", 3000, 3000)
		end
		MenuState.AlphaUtilityMenu = 1
	else
		MenuState.UtilityShow = true
		if button == "RightButton" then
			MenuState.UtilityVisible = true
		end
		if table.getn(UtilityMenuCreate) == 0 then
			return
		end
		for i = 1, table.getn(UtilityMenuCreate), 1 do
			UtilityMenuCreate[i]:SetAlpha(1)
		end
		UtilityMenuCreate[1]:ClearAllPoints()
		UtilityMenuCreate[1]:SetPoint(
			"CENTER",
			"HolywardUtilityMenuButton",
			"CENTER",
			(36 / HolywardConfig.UtilityMenuPos) * 31,
			26
		)
		MenuState.AlphaUtilityVar = GetTime() + 6
	end
end

function Holyward_UtilityCast(type)
	if not HOLYWARD_SPELL_TABLE[type].ID then
		return
	end
	CastSpell(HOLYWARD_SPELL_TABLE[type].ID, "spell")
	MenuState.LastUtility = type
	MenuState.AlphaUtilityMenu = 1
	MenuState.AlphaUtilityVar = GetTime() + 3
end

------------------------------------------------------------------------------------------------------
-- TOOLTIP
------------------------------------------------------------------------------------------------------

function Holyward_BuildTooltip(button, tooltipType, anchor, spellIndex, extraText)
	GameTooltip:SetOwner(button, anchor)
	if tooltipType == "Main" then
		GameTooltip:AddLine(HolywardData.Label, 1.0, 1.0, 1.0)
		GameTooltip:AddLine("Left-click to show/hide the satellite buttons", 0.7, 0.7, 0.7)
		GameTooltip:AddLine("Right-click for settings", 0.7, 0.7, 0.7)
	elseif tooltipType == "BuffMenu" then
		GameTooltip:AddLine("Buffs", 1.0, 1.0, 1.0)
	elseif tooltipType == "Buff" and spellIndex then
		GameTooltip:AddLine(HOLYWARD_SPELL_TABLE[spellIndex].Name, 1.0, 1.0, 1.0)
		if HOLYWARD_BUFF_MENU_ALT[spellIndex] and HOLYWARD_SPELL_TABLE[HOLYWARD_BUFF_MENU_ALT[spellIndex]].ID then
			GameTooltip:AddLine("Right-click: " .. HOLYWARD_SPELL_TABLE[HOLYWARD_BUFF_MENU_ALT[spellIndex]].Name, 0.7, 0.7, 0.7)
		end
	elseif tooltipType == "SpellTimer" then
		GameTooltip:AddLine("Active timers", 1.0, 1.0, 1.0)
		GameTooltip:AddLine("Right-click for Hearthstone", 0.7, 0.7, 0.7)
	elseif tooltipType == "UtilityMenu" then
		GameTooltip:AddLine("Utility", 1.0, 1.0, 1.0)
	elseif tooltipType == "Utility" and spellIndex then
		GameTooltip:AddLine(HOLYWARD_SPELL_TABLE[spellIndex].Name, 1.0, 1.0, 1.0)
	elseif tooltipType == "Mount" then
		GameTooltip:AddLine("Mount", 1.0, 1.0, 1.0)
		GameTooltip:AddLine("Right-click for Hearthstone", 0.7, 0.7, 0.7)
	elseif tooltipType == "Consumables" then
		GameTooltip:AddLine("Consumables", 1.0, 1.0, 1.0)
		GameTooltip:AddLine("Left-click: open menu", 0.7, 0.7, 0.7)
		GameTooltip:AddLine("Right-click: drink water", 0.7, 0.7, 0.7)
	elseif tooltipType == "ConsumablesItem" and extraText then
		GameTooltip:AddLine(extraText, 1.0, 1.0, 1.0)
	elseif tooltipType == "Professions" then
		GameTooltip:AddLine("Professions", 1.0, 1.0, 1.0)
		GameTooltip:AddLine("Every profession/secondary skill in your spellbook", 0.7, 0.7, 0.7)
	elseif tooltipType == "ProfessionsItem" and extraText then
		GameTooltip:AddLine(extraText, 1.0, 1.0, 1.0)
	end
	GameTooltip:Show()
end

