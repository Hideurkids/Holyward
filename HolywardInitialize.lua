------------------------------------------------------------------------------------------------------
-- Holyward TurtleWoW
------------------------------------------------------------------------------------------------------

function Holyward_DeepMerge(source, target)
	for k, v in pairs(source) do
		if target[k] == nil then
			target[k] = v
		elseif type(v) == "table" and type(target[k]) == "table" then
			Holyward_DeepMerge(v, target[k])
		end
	end
end

function Holyward_Initialize()
	Holyward_Localization_Dialog_En()

	if UnitClass("player") ~= HOLYWARD_UNIT_PRIEST then
		HideUIPanel(HolywardButton)
		return
	end

	-- One-time migration for the user's own upgrade from the old "Serenity" addon name -- carries
	-- existing settings into the new config key instead of resetting to defaults. Only works if
	-- the old Serenity folder is still installed alongside this one when Holyward first loads
	-- (its SavedVariables have to actually be loaded for this global to exist); harmless no-op
	-- otherwise.
	if HolywardConfig == nil and SerenityConfig ~= nil then
		HolywardConfig = SerenityConfig
	end

	if HolywardConfig == nil then
		HolywardConfig = Default_HolywardConfig
		Holyward_Msg(HOLYWARD_MESSAGE.Interface.DefaultConfig, "USER")
		HolywardButton:ClearAllPoints()
		HolywardButton:SetPoint("CENTER", "UIParent", "CENTER", 0, -100)
	else
		Holyward_DeepMerge(Default_HolywardConfig, HolywardConfig)

		if HolywardConfig.Version ~= Default_HolywardConfig.Version then
			HolywardConfig.Version = Default_HolywardConfig.Version
		end

		Holyward_Msg(HOLYWARD_MESSAGE.Interface.UserConfig, "USER")
	end

	Holyward_Msg(HOLYWARD_MESSAGE.Interface.Welcome, "USER")

	Holyward_SpellSetup()
	Holyward_CreateMenu()
	-- DEFERRED (2026-09-02): calling Holyward_ApplySatelliteState() synchronously here -- confirmed
	-- the likely cause of the user's "sometimes on /reload the satellite buttons collapse to the
	-- center" report. It calls Holyward_CaptureSatelliteOffsets(), which reads each satellite
	-- button's live on-screen GetCenter() to compute its offset from the sphere -- but at this exact
	-- point in the login/reload sequence, WoW hasn't necessarily run a first layout pass on these
	-- frames yet, so GetCenter() can return a stale/wrong position (the frame not yet moved off
	-- whatever it defaulted to) instead of the real XML-anchored one. That bad reading then gets
	-- cached as holywardRestX/RestY and used for the rest of the session, at the sphere's own
	-- center. Deferring to the first real OnUpdate tick (same pattern already proven for this exact
	-- category of "too early" bug elsewhere) gives the client at least one full frame to finish
	-- laying out before anything reads a position back.
	Holyward_NeedsSatelliteStateApply = true
	Holyward_ApplySphereSize()
	Holyward_ApplyTrackerVisibility()
	Holyward_NormalizeAbilityOrder()
	Holyward_SetupBuffGroupSlots()
	Holyward_SetupAbilityDrag()
	Holyward_SetupTrackerResize()
	Holyward_ApplyTrackerBackgrounds()
	Holyward_LayoutBuffTracker()
	Holyward_LayoutAbilityTracker()

	ShowUIPanel(HolywardButton)
end

function Holyward_SlashHandler(arg1)
	if UnitClass("player") ~= HOLYWARD_UNIT_PRIEST then
		return
	end

	if string.find(string.lower(arg1), "recall") then
		Holyward_RecenterWindows()
	else
		if HOLYWARD_MESSAGE.Help ~= nil then
			for i = 1, table.getn(HOLYWARD_MESSAGE.Help), 1 do
				Holyward_Msg(HOLYWARD_MESSAGE.Help[i], "USER")
			end
		end
		Holyward_Toggle("RightButton")
	end
end
