------------------------------------------------------------------------------------------------------
-- Holyward TurtleWoW
--
-- SpellTimer array CRUD: insert/remove/sort/group/format. Ported from Necrosis's timer engine,
-- with the Warlock-specific stone-sharing branches dropped (Priest has no equivalent).
------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------
-- INSERTION
------------------------------------------------------------------------------------------------------

function Holyward_InsertTimerParTable(IndexTable, Target, LevelTarget, SpellGroup, SpellTimer, TimerTable)
	table.insert(SpellTimer, {
		Name = HOLYWARD_SPELL_TABLE[IndexTable].Name,
		Time = HOLYWARD_SPELL_TABLE[IndexTable].Length,
		TimeMax = floor(GetTime() + HOLYWARD_SPELL_TABLE[IndexTable].Length),
		Type = HOLYWARD_SPELL_TABLE[IndexTable].Type,
		Target = Target,
		TargetLevel = LevelTarget,
		Group = 0,
		Gtimer = nil,
		Icon = HOLYWARD_SPELL_TABLE[IndexTable].Icon or "Interface\\Icons\\INV_Misc_QuestionMark",
	})

	SpellTimer, TimerTable = Holyward_AddFrame(SpellTimer, TimerTable)
	Holyward_Tri(SpellTimer, "Type")
	SpellGroup, SpellTimer = Holyward_Parsing(SpellGroup, SpellTimer)

	return SpellGroup, SpellTimer, TimerTable
end

-- Ad-hoc custom timer, not sourced from HOLYWARD_SPELL_TABLE.
function HolywardTimerX(nom, duree, spellType, Target, LevelTarget, SpellGroup, SpellTimer, TimerTable)
	table.insert(SpellTimer, {
		Name = nom,
		Time = duree,
		TimeMax = floor(GetTime() + duree),
		Type = spellType,
		Target = Target,
		TargetLevel = LevelTarget,
		Group = 0,
		Gtimer = nil,
	})

	SpellTimer, TimerTable = Holyward_AddFrame(SpellTimer, TimerTable)
	Holyward_Tri(SpellTimer, "Type")
	SpellGroup, SpellTimer = Holyward_Parsing(SpellGroup, SpellTimer)

	return SpellGroup, SpellTimer, TimerTable
end

------------------------------------------------------------------------------------------------------
-- REMOVAL
------------------------------------------------------------------------------------------------------

function Holyward_RetraitTimerParIndex(index, SpellTimer, TimerTable)
	local Gtime = SpellTimer[index].Gtimer
	TimerTable = Holyward_RemoveFrame(Gtime, TimerTable)
	table.remove(SpellTimer, index)
	return SpellTimer, TimerTable
end

function Holyward_RetraitTimerParNom(name, SpellTimer, TimerTable)
	for index = 1, table.getn(SpellTimer), 1 do
		if SpellTimer[index].Name == name then
			SpellTimer, TimerTable = Holyward_RetraitTimerParIndex(index, SpellTimer, TimerTable)
			break
		end
	end
	return SpellTimer, TimerTable
end

-- Strips combat-only timers (Type 4/5) and clears nominative target on cooldowns (Type 3) on
-- leaving combat.
function Holyward_RetraitTimerCombat(SpellGroup, SpellTimer, TimerTable)
	for index = 1, table.getn(SpellTimer), 1 do
		if SpellTimer[index] then
			if SpellTimer[index].Type == 3 then
				SpellTimer[index].Target = ""
				SpellTimer[index].TargetLevel = ""
			end
			if SpellTimer[index].Type == 4 or SpellTimer[index].Type == 5 then
				SpellTimer, TimerTable = Holyward_RetraitTimerParIndex(index, SpellTimer, TimerTable)
			end
		end
	end

	if table.getn(SpellGroup.Name) >= 4 then
		for index = 4, table.getn(SpellGroup.Name), 1 do
			table.remove(SpellGroup.Name)
			table.remove(SpellGroup.SubName)
			table.remove(SpellGroup.Visible)
		end
	end
	return SpellGroup, SpellTimer, TimerTable
end

------------------------------------------------------------------------------------------------------
-- BOOLEAN HELPERS
------------------------------------------------------------------------------------------------------

function Holyward_TimerExisteDeja(Nom, SpellTimer)
	for index = 1, table.getn(SpellTimer), 1 do
		if SpellTimer[index].Name == Nom then
			return true
		end
	end
	return false
end

------------------------------------------------------------------------------------------------------
-- SORTING / GROUPING
------------------------------------------------------------------------------------------------------

function Holyward_Parsing(SpellGroup, SpellTimer)
	for index = 1, table.getn(SpellTimer), 1 do
		local GroupeOK = false
		for i = 1, table.getn(SpellGroup.Name), 1 do
			if
				(SpellTimer[index].Type == i and i <= 3)
				or (
					SpellTimer[index].Target == SpellGroup.Name[i]
					and SpellTimer[index].TargetLevel == SpellGroup.SubName[i]
				)
			then
				GroupeOK = true
				SpellTimer[index].Group = i
				break
			end
		end
		if not GroupeOK then
			table.insert(SpellGroup.Name, SpellTimer[index].Target)
			table.insert(SpellGroup.SubName, SpellTimer[index].TargetLevel)
			table.insert(SpellGroup.Visible, false)
			SpellTimer[index].Group = table.getn(SpellGroup.Name)
		end
	end

	Holyward_Tri(SpellTimer, "Group")
	return SpellGroup, SpellTimer
end

function Holyward_Tri(SpellTimer, clef)
	return table.sort(SpellTimer, function(SubTab1, SubTab2)
		return SubTab1[clef] < SubTab2[clef]
	end)
end

------------------------------------------------------------------------------------------------------
-- DISPLAY STRING BUILDER
------------------------------------------------------------------------------------------------------

-- PERFORMANCE (2026-09-10, per the user's pfDebug report -- HolywardButton:OnUpdate() was the
-- highest memory consumer of every addon installed, 17244 kB): `display` used to be a plain string,
-- rebuilt via `display = display .. x` -- every concatenation copies the WHOLE string accumulated so
-- far into a new string object (Lua strings are immutable), and this function runs once per active
-- timer, every second, for the life of the session. Now takes/returns a TABLE instead
-- (`displayParts`) -- table.insert is O(1) amortized, no re-copying -- and the caller
-- (Holyward_OnUpdate's stage 4) joins it into the final string ONCE with table.concat after the
-- whole sweep loop finishes, not once per timer during it.
function Holyward_DisplayTimer(displayParts, index, SpellGroup, SpellTimer, GraphicalTimer, TimerTable)
	if not SpellTimer then
		return displayParts, SpellGroup
	end

	local minutes = 0
	local seconds = 0
	local affichage

	local percent = (floor(SpellTimer[index].TimeMax - floor(GetTime())) / SpellTimer[index].Time) * 100
	local color = HolywardTimerColor(percent)

	if
		not SpellGroup.Visible[SpellTimer[index].Group]
		and SpellGroup.SubName[SpellTimer[index].Group] ~= nil
		and SpellGroup.Name[SpellTimer[index].Group] ~= nil
	then
		table.insert(
			displayParts,
			"<purple>-------------------------------\n"
				.. SpellGroup.Name[SpellTimer[index].Group]
				.. " "
				.. SpellGroup.SubName[SpellTimer[index].Group]
				.. "\n-------------------------------<close>\n"
		)
		table.insert(
			GraphicalTimer.texte,
			SpellGroup.Name[SpellTimer[index].Group] .. " " .. SpellGroup.SubName[SpellTimer[index].Group]
		)
		table.insert(GraphicalTimer.TimeMax, 0)
		table.insert(GraphicalTimer.Time, 0)
		table.insert(GraphicalTimer.titre, true)
		table.insert(GraphicalTimer.temps, "")
		table.insert(GraphicalTimer.Gtimer, 0)
		table.insert(GraphicalTimer.icon, "")
		SpellGroup.Visible[SpellTimer[index].Group] = true
	end

	seconds = SpellTimer[index].TimeMax - floor(GetTime())
	minutes = floor(seconds / 60)
	if minutes > 0 then
		if minutes > 9 then
			affichage = tostring(minutes) .. ":"
		else
			affichage = "0" .. minutes .. ":"
		end
	else
		affichage = "0:"
	end
	seconds = mod(seconds, 60)
	if seconds > 9 then
		affichage = affichage .. seconds
	else
		affichage = affichage .. "0" .. seconds
	end
	table.insert(displayParts, "<white>" .. affichage .. " - <close>")

	if SpellTimer[index].Type == 1 and SpellTimer[index].Target ~= "" then
		if HolywardConfig.SpellTimerPos == 1 then
			affichage = affichage .. " - " .. SpellTimer[index].Target
		else
			affichage = SpellTimer[index].Target .. " - " .. affichage
		end
	end
	table.insert(GraphicalTimer.texte, SpellTimer[index].Name)
	table.insert(GraphicalTimer.TimeMax, SpellTimer[index].TimeMax)
	table.insert(GraphicalTimer.Time, SpellTimer[index].Time)
	table.insert(GraphicalTimer.titre, false)
	table.insert(GraphicalTimer.temps, affichage)
	table.insert(GraphicalTimer.Gtimer, SpellTimer[index].Gtimer)
	table.insert(GraphicalTimer.icon, SpellTimer[index].Icon)

	table.insert(displayParts, color .. SpellTimer[index].Name .. "<close><white>")
	if SpellTimer[index].Type == 1 and SpellTimer[index].Target ~= "" then
		table.insert(displayParts, " - " .. SpellTimer[index].Target .. "<close>\n")
	else
		table.insert(displayParts, "<close>\n")
	end

	-- HolywardAfficheTimer is NOT called here anymore (2026-08-24 fix): this function runs once PER
	-- active timer inside the sweep loop, and calling the full re-render on every single one of those
	-- calls meant N active timers re-rendered the whole (still-growing) GraphicalTimer list N times a
	-- second -- quadratic work, and each pass does real SetPoint/SetTexture/CooldownFrame_SetTimer
	-- calls per row, not cheap Lua ops. The caller (Holyward_OnUpdate's stage 4) now renders once,
	-- after this loop has finished building the complete list for the tick.

	return displayParts, SpellGroup, GraphicalTimer, TimerTable
end
