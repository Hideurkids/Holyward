------------------------------------------------------------------------------------------------------
-- Holyward TurtleWoW
--
-- Settings window, cloned from Questie-Octo's proven architecture (UI/Options.lua there): a
-- declarative AceConfig options table fed through AceConfigDialog into a standalone AceGUI Frame,
-- plus Questie's ShaguTweaks-style dark pass over the resulting widget tree. All libraries are
-- vendored in Libs/ from Questie-Octo's own copies (Ace3 license, Libs/Ace3-LICENSE.txt), with
-- their LibStub major names renamed QuestieOcto-* -> Holyward-* so both addons can coexist.
--
-- Earlier attempts hand-built this window (XML chrome, then raw AceGUI TabGroup calls) and each
-- came out broken in a different way; this file deliberately deviates from Questie's Options.lua
-- as little as possible.
------------------------------------------------------------------------------------------------------

local APP_NAME = "Holyward"

local HolywardOptions = {
	configFrame = nil,
	initialized = false,
}

------------------------------------------------------------------------------------------------------
-- DARK THEME (ported from Questie-Octo UI/Options.lua, always on -- no toggle)
------------------------------------------------------------------------------------------------------

local SHELL_R, SHELL_G, SHELL_B, SHELL_A = 0.30, 0.30, 0.30, 0.90
local INNER_R, INNER_G, INNER_B, INNER_A = 0.035, 0.035, 0.035, 0.84
local INNER_BORDER_R, INNER_BORDER_G, INNER_BORDER_B, INNER_BORDER_A = 0.20, 0.20, 0.20, 0.95
local TAB_R, TAB_G, TAB_B, TAB_A = 0.28, 0.28, 0.28, 1.0

local function ShouldSkipShellTexture(region)
	if not region or not region.GetTexture then
		return true
	end
	local texture = region:GetTexture()
	if not texture then
		return true
	end

	local name = region.GetName and region:GetName() or nil
	if name then
		if string.find(name, "Button", 1, true) or string.find(name, "Icon", 1, true) then
			return true
		end
	end

	if type(texture) == "string" then
		if
			string.find(texture, "Button", 1, true)
			or string.find(texture, "Icon", 1, true)
			or string.find(texture, "WHITE8X8", 1, true)
			or string.find(texture, "StatusBar", 1, true)
			or string.find(texture, "BarFill", 1, true)
			or string.find(texture, "Portrait", 1, true)
		then
			return true
		end
	end

	if region.GetBlendMode and region:GetBlendMode() == "ADD" then
		return true
	end
	return false
end

-- Only tint the physical AceGUI Frame itself -- its DialogFrame textures need vertex tinting,
-- while AceConfig's content containers look better with dark backdrops (below).
local function DarkenOuterShell(frame)
	if not frame then
		return
	end

	if frame.SetBackdropBorderColor then
		frame:SetBackdropBorderColor(SHELL_R, SHELL_G, SHELL_B, SHELL_A)
	end

	if frame.GetRegions then
		local regions = { frame:GetRegions() }
		for _, region in pairs(regions) do
			if
				region
				and region.GetObjectType
				and region:GetObjectType() == "Texture"
				and region.SetVertexColor
				and not ShouldSkipShellTexture(region)
			then
				region:SetVertexColor(SHELL_R, SHELL_G, SHELL_B, SHELL_A)
			end
		end
	end
end

local function IsTabTexture(region)
	if not region or not region.GetTexture then
		return false
	end
	local texture = region:GetTexture()
	return type(texture) == "string" and string.find(texture, "ChatFrameTab", 1, true) and true or false
end

-- AceGUI's ScrollFrame places a UIPanelScrollBarTemplate just outside the scrolling viewport (the
-- widget names it AceConfigDialogScrollFrame<N>ScrollBar regardless of which addon feeds it).
-- Keep that native Vanilla control above the dark content panels and never recolor it.
local function IsAceConfigScrollbar(frame)
	if not frame or not frame.GetName then
		return false
	end
	local name = frame:GetName()
	return name
		and string.find(name, "AceConfigDialogScrollFrame", 1, true)
		and string.find(name, "ScrollBar", 1, true)
		and true
		or false
end

local function RaiseScrollbar(frame)
	if not frame then
		return
	end

	if IsAceConfigScrollbar(frame) then
		local parent = frame.GetParent and frame:GetParent() or nil
		local base = (parent and parent.GetFrameLevel and parent:GetFrameLevel()) or 0
		if frame.SetFrameLevel then
			frame:SetFrameLevel(base + 20)
		end

		-- Vanilla's UIPanelScrollBarTemplate thumb artwork is wider than the 16px Slider frame
		-- AceGUI uses; give the slider its native visual width so the full thumb renders.
		if frame.SetWidth and not frame.holywardFullThumbWidth then
			frame:SetWidth(20)
			frame.holywardFullThumbWidth = true
		end

		if frame.GetChildren then
			local children = { frame:GetChildren() }
			for _, child in pairs(children) do
				if child and child.SetFrameLevel then
					child:SetFrameLevel(base + 21)
				end
			end
		end
		return
	end

	if frame.GetChildren then
		local children = { frame:GetChildren() }
		for _, child in pairs(children) do
			RaiseScrollbar(child)
		end
	end
end

-- Dark panels come from coloring frame backdrops (ShaguTweaks-style) rather than painting a gray
-- vertex wash over every child region -- backdrop-less controls (checkboxes, sliders, icons) keep
-- their crisp native artwork.
local function DarkenInnerContent(frame)
	if not frame then
		return
	end

	if IsAceConfigScrollbar(frame) then
		return
	end

	if frame.SetBackdropColor then
		frame:SetBackdropColor(INNER_R, INNER_G, INNER_B, INNER_A)
	end
	if frame.SetBackdropBorderColor then
		frame:SetBackdropBorderColor(INNER_BORDER_R, INNER_BORDER_G, INNER_BORDER_B, INNER_BORDER_A)
	end

	-- The top tabs use ChatFrameTab textures instead of a backdrop -- tint only those.
	if frame.GetRegions then
		local regions = { frame:GetRegions() }
		for _, region in pairs(regions) do
			if
				region
				and region.GetObjectType
				and region:GetObjectType() == "Texture"
				and region.SetVertexColor
				and IsTabTexture(region)
			then
				region:SetVertexColor(TAB_R, TAB_G, TAB_B, TAB_A)
			end
		end
	end

	if frame.GetChildren then
		local children = { frame:GetChildren() }
		for _, child in pairs(children) do
			DarkenInnerContent(child)
		end
	end
end

-- Global on purpose: the vendored AceConfigDialog re-invokes this after every widget refresh
-- (tab switches recreate all child widgets), mirroring Questie's own hook there.
function Holyward_ApplyOptionsDarkTheme()
	local configFrame = HolywardOptions.configFrame
	if not configFrame or not configFrame.frame then
		return
	end

	local shell = configFrame.frame
	DarkenOuterShell(shell)
	if shell.GetChildren then
		local children = { shell:GetChildren() }
		for _, child in pairs(children) do
			DarkenInnerContent(child)
		end
	end
	RaiseScrollbar(shell)
end

------------------------------------------------------------------------------------------------------
-- OPTIONS TABLE
------------------------------------------------------------------------------------------------------

-- The Ability Tracker's config flags are positional (slot 1..16 of HOLYWARD_ABILITY_TRACKER); the
-- timer list's are keyed by HOLYWARD_SPELL_TABLE index directly. Each row carries both its label
-- and the spell-table index used for the live icon.
-- Base slot 9 is the merged Enlighten slot: it tracks the "Enlightened" proc (spell-table index 29,
-- whose icon is synced to Enlighten's) rather than the talent's own cooldown.
local ABILITY_TRACKER_ROWS = {
	{ "Fade", 1 }, { "Fear Ward", 2 }, { "Power Infusion", 3 }, { "Inner Focus", 4 },
	{ "Pain Spike", 5 }, { "Psychic Scream", 24 }, { "Chastise", 25 }, { "Ascendance", 26 },
	{ "Enlighten", 29 }, { "Shackle Undead", 8 }, { "Weakened Soul", 17 }, { "Devouring Plague", 6 },
	{ "Shadow Word: Pain", 27 }, { "Purifying Flames", 31 }, { "Searing Light", 30 }, { "Mana Potion", 33 },
	{ "Inner Fire", 15 },
}

local SPELL_TIMER_ROWS = {
	{ "Fade", 1 }, { "Fear Ward", 2 }, { "Power Infusion", 3 }, { "Inner Focus", 4 },
	{ "Pain Spike", 5 }, { "Psychic Scream", 24 }, { "Chastise", 25 }, { "Ascendance", 26 },
	{ "Enlighten", 23 }, { "Shackle Undead", 8 }, { "Weakened Soul", 17 }, { "Devouring Plague", 6 },
	{ "Shadow Word: Pain", 27 }, { "Holy Fire", 28 },
}

-- Order must match HOLYWARD_CONSUMABLE_CATEGORY in Holyward.lua exactly.
local CONSUMABLES_CATEGORY_ROWS = { "Water", "Food", "Healing Potion", "Mana Potion", "Elixir", "Flask", "Bandage" }

-- Appended at the end (slot 14), not inserted among the existing 13 -- inserting would shift every
-- later slot's index and silently reassign any user's already-saved per-slot enable/disable state
-- (HolywardConfig.BuffTrackerEnabled, indexed positionally) to the wrong buff.
local BUFF_TRACKER_ROWS = {
	"Well Fed", "Flask", "Elixirs (grouped)", "Weapon Buff",
	"Kreeg's Stout Beatdown", "Fortitude", "Divine Spirit", "Arcane Intellect", "Mark of the Wild",
	"Battle Shout", "Blessings (grouped)", "Thorns", "Inner Fire", "Shadow Protection",
}


local function SpellIconGetter(spellIndex)
	return function()
		local entry = HOLYWARD_SPELL_TABLE and HOLYWARD_SPELL_TABLE[spellIndex]
		return entry and entry.Icon or "Interface\\Icons\\INV_Misc_QuestionMark"
	end
end

local function CreateGeneralTab()
	local args = {
			interface_header = { type = "header", order = 1, name = "Interface" },
			locked = {
				type = "toggle", order = 1.5, width = "full",
				name = "Lock windows",
				desc = "Freezes the sphere, satellite buttons, timer anchor, and both trackers in place, and disables drag-to-reorder -- nothing shifts by accident.",
				image = "Interface\\Icons\\INV_Misc_Key_04",
				get = function()
					return HolywardConfig.Locked
				end,
				set = function(info, value)
					HolywardConfig.Locked = value
				end,
			},
			chatType = {
				type = "toggle", order = 2, width = "full",
				name = "Show messages in the chat window",
				desc = "When off, Holyward messages use the floating error text instead.",
				get = function()
					return HolywardConfig.ChatType
				end,
				set = function(info, value)
					HolywardConfig.ChatType = value
				end,
			},
			mouseoverCast = {
				type = "toggle", order = 2.5, width = "full",
				name = "Mouseover casting (all spells)",
				desc = "Every spell or item you use from ANY action bar targets whatever unit is under your mouse cursor instead of your current target. Your real target is restored right after the cast, so it never actually changes.",
				image = "Interface\\Icons\\Spell_Nature_NullifyDisease",
				get = function()
					return HolywardConfig.MouseoverCast
				end,
				set = function(info, value)
					HolywardConfig.MouseoverCast = value
				end,
			},
			autoInvite = {
				type = "toggle", order = 2.6, width = "full",
				name = "Auto-invite on whisper",
				desc = "Automatically invites anyone who whispers you exactly \"inv\", \"invite\", or \"123\" (case-insensitive, whole message only -- a real sentence containing one of those words won't trigger it).",
				image = "Interface\\Icons\\Spell_Holy_SealOfSalvation",
				get = function()
					return HolywardConfig.AutoInvite
				end,
				set = function(info, value)
					HolywardConfig.AutoInvite = value
				end,
			},
			sphereSize = {
				type = "range", order = 2.7, width = "full",
				name = "Sphere size",
				desc = "Edge length of the main sphere, in pixels. Satellite buttons keep their own distance from its center, so a much bigger sphere can start to overlap them.",
				min = 40, max = 100, step = 2,
				get = function()
					return HolywardConfig.SphereSize
				end,
				set = function(info, value)
					HolywardConfig.SphereSize = value
					Holyward_ApplySphereSize()
				end,
			},
			windows_header = { type = "header", order = 10, name = "Windows" },
			recenter_text = {
				type = "description", order = 11, fontSize = "medium",
				name = "Windows drifted off-screen or on top of each other?",
			},
			recenter = {
				type = "execute", order = 12, name = "Recenter windows",
				desc = "Move the sphere, timer anchor, and both tracker windows back to the screen center.",
				func = function()
					Holyward_RecenterWindows()
				end,
			},
	}
	return { name = "General", type = "group", order = 1, args = args }
end

local function CreateConsumablesTab()
	local args = {
		direction_header = { type = "header", order = 1, name = "Expanded List" },
		consumablesDirection = {
			type = "select", order = 2, width = "full",
			name = "Expand direction",
			desc = "Which way the full list opens when you click a Consumables category.",
			values = { UP = "Up", DOWN = "Down", LEFT = "Left", RIGHT = "Right" },
			get = function()
				return HolywardConfig.ConsumablesExpandDirection
			end,
			set = function(info, value)
				HolywardConfig.ConsumablesExpandDirection = value
			end,
		},
		categories_header = { type = "header", order = 10, name = "Categories" },
	}
	for i = 1, table.getn(CONSUMABLES_CATEGORY_ROWS), 1 do
		local slot = i
		args["consumeCat" .. i] = {
			type = "toggle", order = 10 + i, name = CONSUMABLES_CATEGORY_ROWS[i],
			image = function()
				return Holyward_GetConsumableCategoryIcon(slot)
			end,
			get = function()
				return HolywardConfig.ConsumablesEnabled[slot]
			end,
			set = function(info, value)
				HolywardConfig.ConsumablesEnabled[slot] = value
			end,
		}
	end
	return { name = "Consumables", type = "group", order = 2, args = args }
end

local function CreateTrackingTab()
	local args = {
		windows_header = { type = "header", order = 1, name = "Windows" },
		showBuffTracker = {
			type = "toggle", order = 2, width = "full",
			name = "Buff Tracker window",
			desc = "Consumables, weapon buff, and class buffs at a glance.",
			get = function()
				return HolywardConfig.ShowBuffTracker
			end,
			set = function(info, value)
				HolywardConfig.ShowBuffTracker = value
				Holyward_ApplyTrackerVisibility()
			end,
		},
		showAbilityTracker = {
			type = "toggle", order = 3, width = "full",
			name = "Ability Tracker window",
			desc = "Cooldowns, target debuffs, and procs, WeakAuras-style.",
			get = function()
				return HolywardConfig.ShowAbilityTracker
			end,
			set = function(info, value)
				HolywardConfig.ShowAbilityTracker = value
				Holyward_ApplyTrackerVisibility()
			end,
		},
		showAbilityBackground = {
			type = "toggle", order = 4, width = "full",
			name = "Ability Tracker dark background",
			desc = "The translucent dark panel behind the icons. Off = icons float directly on the world.",
			get = function()
				return HolywardConfig.AbilityTrackerBackground
			end,
			set = function(info, value)
				HolywardConfig.AbilityTrackerBackground = value
				Holyward_ApplyTrackerBackgrounds()
			end,
		},
		slots_header = { type = "header", order = 10, name = "Ability Tracker slots" },
		reorder_hint = {
			type = "description", order = 10.01, fontSize = "medium",
			name = "To reorder: drag an icon over another one in the tracker itself. To change how many fit per row: drag the corner grip. (Both disabled while locked.)",
		},
		appearance_header = { type = "header", order = 89, name = "Icon size and spacing" },
		iconSize = {
			type = "range", order = 90, width = "double",
			name = "Icon size",
			desc = "Edge length of each Ability Tracker icon, in pixels.",
			min = 16, max = 48, step = 1,
			get = function()
				return HolywardConfig.AbilityTrackerIconSize
			end,
			set = function(info, value)
				HolywardConfig.AbilityTrackerIconSize = value
				Holyward_LayoutAbilityTracker()
			end,
		},
		spacingX = {
			type = "range", order = 91, width = "double",
			name = "Horizontal spacing",
			desc = "Gap between columns, in pixels.",
			min = 0, max = 20, step = 1,
			get = function()
				return HolywardConfig.AbilityTrackerSpacingX
			end,
			set = function(info, value)
				HolywardConfig.AbilityTrackerSpacingX = value
				Holyward_LayoutAbilityTracker()
			end,
		},
		spacingY = {
			type = "range", order = 92, width = "double",
			name = "Vertical spacing",
			desc = "Gap between rows, in pixels. The countdown text sits inside this gap -- values below ~12 start overlapping it.",
			min = 0, max = 30, step = 1,
			get = function()
				return HolywardConfig.AbilityTrackerSpacingY
			end,
			set = function(info, value)
				HolywardConfig.AbilityTrackerSpacingY = value
				Holyward_LayoutAbilityTracker()
			end,
		},
	}
	-- Rows are listed in DISPLAY order (position k shows base slot order[k]); the enable flag is
	-- keyed by the base slot, its fixed identity, so it follows the ability when it's dragged around.
	local order = HolywardConfig.AbilityTrackerOrder or {}
	local total = table.getn(ABILITY_TRACKER_ROWS)
	for k = 1, total, 1 do
		local base = order[k] or k
		local row = ABILITY_TRACKER_ROWS[base]
		if row then
			local label = row[1]
			local spellIndex = row[2]
			args["slot" .. k] = {
				type = "toggle", order = 10 + k * 0.1, name = label,
				image = SpellIconGetter(spellIndex),
				get = function()
					return HolywardConfig.AbilityTrackerEnabled[base]
				end,
				set = function(info, value)
					HolywardConfig.AbilityTrackerEnabled[base] = value
				end,
			}
		end
	end
	return { name = "Tracking", type = "group", order = 3, args = args }
end

local function CreateTimersTab()
	local args = {
		list_header = { type = "header", order = 1, name = "Timer List" },
		-- Master switch (2026-09-02, per the user): turns off spell/cooldown tracking entirely AND
		-- hides HolywardSpellTimerButton (the timer anchor button) -- for someone who doesn't want
		-- to see the timer feature at all. Distinct from "showTimers" below, which only controls the
		-- text-list DISPLAY MODE of an already-enabled tracker (and, before this switch existed,
		-- couldn't actually hide the button on its own whenever Graphical was also on). Applied
		-- immediately in `set` rather than waiting for the next once-a-second update tick, so the
		-- button visibly shows/hides the instant the checkbox is toggled.
		timersEnabled = {
			type = "toggle", order = 1.5, width = "full",
			name = "Enable timer tracking",
			desc = "Master switch for the whole timer feature -- turns off spell/cooldown tracking and hides the timer button entirely. Turn this off if you don't want to see it.",
			get = function()
				return HolywardConfig.TimersEnabled
			end,
			set = function(info, value)
				HolywardConfig.TimersEnabled = value
				if value then
					if HolywardSpellTimerButton and not HolywardSpellTimerButton:IsVisible() then
						ShowUIPanel(HolywardSpellTimerButton)
					end
				else
					if HolywardSpellTimerButton and HolywardSpellTimerButton:IsVisible() then
						HideUIPanel(HolywardSpellTimerButton)
					end
				end
			end,
		},
		showTimers = {
			type = "toggle", order = 2, width = "full",
			name = "Show the active timer list",
			get = function()
				return HolywardConfig.ShowSpellTimers
			end,
			set = function(info, value)
				HolywardConfig.ShowSpellTimers = value
			end,
		},
		yellow = {
			type = "toggle", order = 3, width = "full",
			name = "Yellow countdown text",
			desc = "When off, countdown text is white.",
			get = function()
				return HolywardConfig.Yellow
			end,
			set = function(info, value)
				HolywardConfig.Yellow = value
			end,
		},
		growUp = {
			type = "toggle", order = 4, width = "full",
			name = "List grows upward",
			desc = "When off, the list grows downward.",
			get = function()
				return HolywardConfig.SensListe == -1
			end,
			set = function(info, value)
				HolywardConfig.SensListe = value and -1 or 1
			end,
		},
		extendLeft = {
			type = "toggle", order = 5, width = "full",
			name = "List extends left of the anchor",
			desc = "When off, the list extends to the right.",
			get = function()
				return HolywardConfig.SpellTimerJust == "LEFT"
			end,
			set = function(info, value)
				HolywardConfig.SpellTimerJust = value and "LEFT" or "RIGHT"
			end,
		},
		spells_header = { type = "header", order = 10, name = "Which spells may appear in the list" },
	}
	for i = 1, table.getn(SPELL_TIMER_ROWS), 1 do
		local label = SPELL_TIMER_ROWS[i][1]
		local spellIndex = SPELL_TIMER_ROWS[i][2]
		args["spell" .. i] = {
			type = "toggle", order = 10 + i, name = label, image = SpellIconGetter(spellIndex),
			get = function()
				return HolywardConfig.SpellTimerEnabled[spellIndex]
			end,
			set = function(info, value)
				HolywardConfig.SpellTimerEnabled[spellIndex] = value
			end,
		}
	end
	return { name = "Timers", type = "group", order = 4, args = args }
end

local function CreateBuffsTab()
	local args = {
		background_header = { type = "header", order = 0.5, name = "Appearance" },
		showBuffBackground = {
			type = "toggle", order = 0.6, width = "full",
			name = "Buff Tracker dark background",
			desc = "The translucent dark panel behind the icons. Off = icons float directly on the world.",
			get = function()
				return HolywardConfig.BuffTrackerBackground
			end,
			set = function(info, value)
				HolywardConfig.BuffTrackerBackground = value
				Holyward_ApplyTrackerBackgrounds()
			end,
		},
		-- Category toggles below use order = 1+i for i=1..14 (orders 2..15) -- this header/select
		-- must sit above 15, or it collides with the last category's own order and the two sections
		-- interleave unpredictably (confirmed 2026-08-24: Shadow Protection's checkbox, order 15,
		-- was landing INSIDE this section instead of completing the category grid, because it tied
		-- with direction_header's own order at the time).
		categories_header = { type = "header", order = 1, name = "Buff Tracker categories" },
		direction_header = { type = "header", order = 30, name = "Elixir / Blessing expand list" },
		buffTrackerDirection = {
			type = "select", order = 31, width = "full",
			name = "Expand direction",
			desc = "Which way the Elixir/Blessing group's full buff list opens when you click it.",
			values = { UP = "Up", DOWN = "Down", LEFT = "Left", RIGHT = "Right" },
			get = function()
				return HolywardConfig.BuffTrackerExpandDirection
			end,
			set = function(info, value)
				HolywardConfig.BuffTrackerExpandDirection = value
			end,
		},
		appearance2_header = { type = "header", order = 49, name = "Icon size and spacing" },
		iconSize = {
			type = "range", order = 50, width = "double",
			name = "Icon size",
			desc = "Edge length of each Buff Tracker icon, in pixels.",
			min = 16, max = 48, step = 1,
			get = function()
				return HolywardConfig.BuffTrackerIconSize
			end,
			set = function(info, value)
				HolywardConfig.BuffTrackerIconSize = value
				Holyward_LayoutBuffTracker()
			end,
		},
		spacingX = {
			type = "range", order = 51, width = "double",
			name = "Horizontal spacing",
			desc = "Gap between columns, in pixels.",
			min = 0, max = 20, step = 1,
			get = function()
				return HolywardConfig.BuffTrackerSpacingX
			end,
			set = function(info, value)
				HolywardConfig.BuffTrackerSpacingX = value
				Holyward_LayoutBuffTracker()
			end,
		},
		spacingY = {
			type = "range", order = 52, width = "double",
			name = "Vertical spacing",
			desc = "Gap between rows, in pixels. The countdown text sits inside this gap -- values below ~12 start overlapping it.",
			min = 0, max = 30, step = 1,
			get = function()
				return HolywardConfig.BuffTrackerSpacingY
			end,
			set = function(info, value)
				HolywardConfig.BuffTrackerSpacingY = value
				Holyward_LayoutBuffTracker()
			end,
		},
	}
	for i = 1, table.getn(BUFF_TRACKER_ROWS), 1 do
		local slot = i
		args["cat" .. i] = {
			type = "toggle", order = 1 + i, name = BUFF_TRACKER_ROWS[i],
			image = function()
				return Holyward_GetBuffTrackerIcon(slot) or "Interface\\Icons\\INV_Misc_QuestionMark"
			end,
			get = function()
				return HolywardConfig.BuffTrackerEnabled[slot]
			end,
			set = function(info, value)
				HolywardConfig.BuffTrackerEnabled[slot] = value
			end,
		}
	end
	return { name = "Buffs", type = "group", order = 5, args = args }
end

-- Same per-letter gradient as the .toc Title, not applied to the tab headers or any button tooltip
-- per the user's explicit scope (2026-08-22) -- just this one window title.
local HOLYWARD_TITLE_GRADIENT =
	"|CFFFFFFFFH|CFFFFF7DEo|CFFFFEFBEl|CFFFFE79Dy|CFFFFDF7Dw|CFFFFD75Ca|CFFFFD700r|CFFFFD700d|CFFFFFFFF Options"

local function CreateOptionsTable()
	return {
		name = HOLYWARD_TITLE_GRADIENT,
		type = "group",
		childGroups = "tab",
		args = {
			general_tab = CreateGeneralTab(),
			consumables_tab = CreateConsumablesTab(),
			tracking_tab = CreateTrackingTab(),
			timers_tab = CreateTimersTab(),
			buffs_tab = CreateBuffsTab(),
		},
	}
end

-- Rebuilds and re-registers the whole options table (the Tracking tab bakes the current display
-- order into its rows), then pokes the open dialog to redraw. Global: the tracker's drag-to-reorder
-- (Holyward.lua) calls it when a drag finishes so this window's list re-sorts to match.
function Holyward_RefreshOptions()
	if not HolywardOptions.initialized then
		return
	end
	local Registry = LibStub and LibStub("Holyward-AceConfigRegistry-3.0", true)
	if not Registry then
		return
	end
	Registry:RegisterOptionsTable(APP_NAME, CreateOptionsTable())
	if Registry.NotifyChange then
		Registry:NotifyChange(APP_NAME)
	end
end

------------------------------------------------------------------------------------------------------
-- FRAME LIFECYCLE (mirrors Questie-Octo's O:Initialize/Show/Hide/Toggle)
------------------------------------------------------------------------------------------------------

local function ClearSavedConfigPosition()
	local Dialog = LibStub and LibStub("Holyward-AceConfigDialog-3.0", true)
	if not Dialog or not Dialog.GetStatusTable then
		return
	end
	local status = Dialog:GetStatusTable(APP_NAME)
	if status then
		status.top = nil
		status.left = nil
	end
end

local function HolywardOptions_Initialize()
	if HolywardOptions.initialized then
		return true
	end

	local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
	local Registry = LibStub and LibStub("Holyward-AceConfigRegistry-3.0", true)
	local Dialog = LibStub and LibStub("Holyward-AceConfigDialog-3.0", true)
	if not AceGUI or not Registry or not Dialog then
		Holyward_Msg("<red>Options UI libraries failed to load.", "USER")
		return false
	end

	Registry:RegisterOptionsTable(APP_NAME, CreateOptionsTable())

	local configFrame = AceGUI:Create("Frame")
	configFrame:Hide()

	Dialog:SetDefaultSize(APP_NAME, 625, 700)
	Dialog:Open(APP_NAME, configFrame)
	configFrame:SetLayout("Fill")

	-- AceConfigDialog calls SetStatusTable() on this custom root frame after every option
	-- activation, and AceGUI Frame's SetStatusTable immediately re-runs frame geometry, which can
	-- visibly jump the window on this 1.12 client (Questie hit and neutralized the same thing).
	-- Keep the status table for Ace3 semantics but skip the geometry re-apply.
	if configFrame.SetStatusTable then
		configFrame.SetStatusTable = function(self, status)
			if status then
				status.top = nil
				status.left = nil
				self.status = status
			end
		end
	end

	if configFrame.EnableResize then
		configFrame:EnableResize(false)
	end

	configFrame:Hide()
	HolywardOptions.configFrame = configFrame

	-- ESC closes the window: the AceGUI widget table exposes IsShown()/Hide(), which is all
	-- UISpecialFrames needs on this client (same registration Questie uses).
	HolywardConfigFrame = configFrame
	local registered = false
	for _, name in pairs(UISpecialFrames or {}) do
		if name == "HolywardConfigFrame" then
			registered = true
			break
		end
	end
	if not registered then
		table.insert(UISpecialFrames, "HolywardConfigFrame")
	end

	HolywardOptions.initialized = true
	return true
end

local function RecenterConfigFrame(configFrame)
	ClearSavedConfigPosition()
	if not configFrame or not configFrame.frame then
		return
	end
	local frame = configFrame.frame
	if frame.ClearAllPoints then
		frame:ClearAllPoints()
	end
	if frame.SetPoint then
		frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	end
end

function Holyward_ShowOptions()
	if not HolywardOptions_Initialize() then
		return
	end
	local Dialog = LibStub("Holyward-AceConfigDialog-3.0")
	Dialog:Open(APP_NAME, HolywardOptions.configFrame)
	RecenterConfigFrame(HolywardOptions.configFrame)
	if HolywardOptions.configFrame.SetStatusText then
		HolywardOptions.configFrame:SetStatusText(nil)
	end
	Holyward_ApplyOptionsDarkTheme()
end

function Holyward_HideOptions()
	if HolywardOptions.configFrame and HolywardOptions.configFrame:IsShown() then
		HolywardOptions.configFrame:Hide()
	end
end

function Holyward_IsOptionsVisible()
	return HolywardOptions.configFrame ~= nil and HolywardOptions.configFrame:IsShown()
end
