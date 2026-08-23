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
	Holyward_ApplySatelliteState()
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
