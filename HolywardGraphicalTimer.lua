------------------------------------------------------------------------------------------------------
-- Holyward TurtleWoW
--
-- Renders the pooled timer-icon frames defined in HolywardTimer.xml and manages the 50-slot pool.
-- Each active timer is a spell icon with the native radial cooldown swipe (the same widget action
-- bars use) plus a countdown label -- not a colored progress bar.
------------------------------------------------------------------------------------------------------

-- tableau is shaped:
-- { texte = "mob or spell name", TimeMax = "spell TimeMax", Time = "spell Time",
--   titre = "true if this row is a group header", temps = "formatted countdown text",
--   Gtimer = "pooled frame index (1-50)", icon = "spell icon texture path" }
function HolywardAfficheTimer(tableau, pointeur)
	if tableau == nil then
		return
	end

	local TimerTarget = 0
	local yPosition = HolywardConfig.SensListe * 5

	local PositionTitre = {}
	if HolywardConfig.SensListe > 0 then
		PositionTitre = { 11, 13 }
	else
		PositionTitre = { -13, -11 }
	end

	local justInverse = "LEFT"
	if HolywardConfig.SpellTimerJust == "LEFT" then
		justInverse = "RIGHT"
	end

	for index = 1, table.getn(tableau.texte), 1 do
		if tableau.titre[index] then
			TimerTarget = TimerTarget + 1
			if TimerTarget ~= 1 then
				yPosition = yPosition - PositionTitre[1]
			end
			if TimerTarget == 11 then
				TimerTarget = 1
			end
			local frameItem = Holyward_CachedGlobal("HolywardTarget" .. TimerTarget .. "Text")
			frameItem:ClearAllPoints()
			frameItem:SetPoint(
				HolywardConfig.SpellTimerJust,
				"HolywardSpellTimerButton",
				"CENTER",
				HolywardConfig.SpellTimerPos * 23,
				yPosition
			)
			yPosition = yPosition - PositionTitre[2]
			frameItem:SetText(tableau.texte[index])
			if not frameItem:IsShown() then
				frameItem:Show()
			end
		else
			local frameIcon = Holyward_CachedGlobal("HolywardTimer" .. tableau.Gtimer[index] .. "Icon")
			local frameCooldown =
				Holyward_GetOrCreateCooldown("HolywardTimer" .. tableau.Gtimer[index], HolywardBarTimers, 24)
			local frameText = Holyward_CachedGlobal("HolywardTimer" .. tableau.Gtimer[index] .. "Text")

			if frameIcon and frameCooldown and frameText then
				frameIcon:ClearAllPoints()
				frameIcon:SetPoint(
					HolywardConfig.SpellTimerJust,
					"HolywardSpellTimerButton",
					"CENTER",
					HolywardConfig.SpellTimerPos * 23,
					yPosition
				)
				if tableau.icon[index] and tableau.icon[index] ~= "" then
					frameIcon:SetTexture(tableau.icon[index])
				end

				frameCooldown:Show()
				frameCooldown:ClearAllPoints()
				-- Both corners, not just TOPLEFT -- a single anchor leaves the frame at its
				-- inherited/default size instead of matching the icon, which is why the swipe was
				-- rendering oversized and offset below the icon instead of on top of it.
				frameCooldown:SetPoint("TOPLEFT", frameIcon, "TOPLEFT", 0, 0)
				frameCooldown:SetPoint("BOTTOMRIGHT", frameIcon, "BOTTOMRIGHT", 0, 0)
				if CooldownFrame_SetTimer then
					CooldownFrame_SetTimer(
						frameCooldown,
						tableau.TimeMax[index] - tableau.Time[index],
						tableau.Time[index],
						1
					)
				end

				frameText:ClearAllPoints()
				if HolywardConfig.Yellow then
					frameText:SetTextColor(1, 0.82, 0)
				else
					frameText:SetTextColor(1, 1, 1)
				end
				if justInverse == "RIGHT" then
					frameText:SetPoint("LEFT", frameIcon, "RIGHT", 4, 0)
					frameText:SetJustifyH("LEFT")
				else
					frameText:SetPoint("RIGHT", frameIcon, "LEFT", -4, 0)
					frameText:SetJustifyH("RIGHT")
				end
				frameText:SetText(tableau.temps[index])
			end

			yPosition = yPosition - HolywardConfig.SensListe * 26
		end
	end

	if TimerTarget < 10 then
		for i = TimerTarget + 1, 10, 1 do
			local frameItem = Holyward_CachedGlobal("HolywardTarget" .. i .. "Text")
			if frameItem:IsShown() then
				frameItem:Hide()
			end
		end
	end
end

function Holyward_AddFrame(SpellTimer, TimerTable)
	for i = 1, table.getn(TimerTable), 1 do
		if not TimerTable[i] then
			TimerTable[i] = true
			SpellTimer[table.getn(SpellTimer)].Gtimer = i
			if HolywardConfig.Graphical then
				local elements = { "Text", "Icon" }
				for j = 1, 2, 1 do
					local frame = getglobal("HolywardTimer" .. i .. elements[j])
					if frame then
						frame:Show()
					end
				end
				-- Cooldown is Lua-created (not an XML element on this client), created lazily by
				-- HolywardAfficheTimer the first time this slot renders; nothing to show yet here.
			end
			break
		end
	end
	return SpellTimer, TimerTable
end

function Holyward_RemoveFrame(Gtime, TimerTable)
	local elements = { "Text", "Icon" }
	for j = 1, 2, 1 do
		local frame = getglobal("HolywardTimer" .. Gtime .. elements[j])
		if frame then
			frame:Hide()
		end
	end
	local cooldown = HolywardCooldownFrames and HolywardCooldownFrames["HolywardTimer" .. Gtime]
	if cooldown then
		cooldown:Hide()
	end
	TimerTable[Gtime] = false
	return TimerTable
end
