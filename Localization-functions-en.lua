------------------------------------------------------------------------------------------------------
-- Holyward TurtleWoW
------------------------------------------------------------------------------------------------------

HOLYWARD_UNIT_PRIEST = "Priest"

-- Indices are load-bearing: Holyward.lua's buff menu and signature-spell click both reference
-- these by number. Durations/cooldowns verified against Classic WoW references where possible
-- (see plan file); TWoW-specific values (Pain Spike, Shackle base) per the wiki context in-session.
function Holyward_ResetSpellTable()
	HOLYWARD_SPELL_TABLE = {
		[1] = { ID = nil, Rank = nil, CastTime = nil, Mana = nil, Name = "Fade", Length = 30, Type = 3 },
		[2] = { ID = nil, Rank = nil, CastTime = nil, Mana = nil, Name = "Fear Ward", Length = 180, Type = 3 },
		[3] = { ID = nil, Rank = nil, CastTime = nil, Mana = nil, Name = "Power Infusion", Length = 180, Type = 3 },
		[4] = { ID = nil, Rank = nil, CastTime = nil, Mana = nil, Name = "Inner Focus", Length = 180, Type = 3 },
		[5] = { ID = nil, Rank = nil, CastTime = nil, Mana = nil, Name = "Pain Spike", Length = 40, Type = 3 },
		[6] = { ID = nil, Rank = nil, CastTime = nil, Mana = nil, Name = "Devouring Plague", Length = 24, Type = 5 },
		-- Type 0: only Weakened Soul (below) gets tracked as a timer, not the shield's own 30s
		-- absorb duration -- the user only wants the "when can I re-shield" info, not a second bar.
		[7] = { ID = nil, Rank = nil, CastTime = nil, Mana = nil, Name = "Power Word: Shield", Length = 30, Type = 0 },
		[8] = { ID = nil, Rank = nil, CastTime = nil, Mana = nil, Name = "Shackle Undead", Length = 50, Type = 4 },
		[9] = { ID = nil, Rank = nil, CastTime = nil, Mana = nil, Name = "Power Word: Fortitude", Length = 0, Type = 0 },
		[10] = { ID = nil, Rank = nil, CastTime = nil, Mana = nil, Name = "Prayer of Fortitude", Length = 0, Type = 0 },
		[11] = { ID = nil, Rank = nil, CastTime = nil, Mana = nil, Name = "Divine Spirit", Length = 0, Type = 0 },
		[12] = { ID = nil, Rank = nil, CastTime = nil, Mana = nil, Name = "Prayer of Spirit", Length = 0, Type = 0 },
		[13] = { ID = nil, Rank = nil, CastTime = nil, Mana = nil, Name = "Shadow Protection", Length = 0, Type = 0 },
		[14] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Prayer of Shadow Protection",
			Length = 0,
			Type = 0,
		},
		-- AuraTrack opts this Type-0 (no-timer) entry into the Ability Tracker's live-aura presence
		-- read (Holyward.lua) without turning it into a Type 6 proc -- Type stays 0 so the Buff Menu
		-- cast button and SpellManagement's cast-detection loop treat it exactly as before.
		[15] = { ID = nil, Rank = nil, CastTime = nil, Mana = nil, Name = "Inner Fire", Length = 0, Type = 0, AuraTrack = true },
		[16] = { ID = nil, Rank = nil, CastTime = nil, Mana = nil, Name = "Shadowform", Length = 0, Type = 0 },
		-- Applied automatically by Power Word: Shield, not itself castable, so .ID is never set by
		-- the spellbook scan; inserted directly by Holyward_SpellManagement's PW:Shield special-case.
		-- Length confirmed 15s from the in-game tooltip on TWoW (2026-08-21, rank 5: "cannot be
		-- shielded again for 15 sec"). PW:Shield's own 4s recast cooldown (same tooltip) is
		-- deliberately not tracked separately: it always expires well before Weakened Soul does, so
		-- it would never be the binding constraint and would just add a redundant timer bar.
		[17] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Weakened Soul",
			Length = 15,
			Type = 4,
			Icon = "Interface\\Icons\\Spell_Holy_PowerWordShield",
		},
		-- Utility Menu spells
		[18] = { ID = nil, Rank = nil, CastTime = nil, Mana = nil, Name = "Mind Soothe", Length = 0, Type = 0 },
		[19] = { ID = nil, Rank = nil, CastTime = nil, Mana = nil, Name = "Levitate", Length = 0, Type = 0 },
		[20] = { ID = nil, Rank = nil, CastTime = nil, Mana = nil, Name = "Lightwell", Length = 0, Type = 0 },
		[21] = { ID = nil, Rank = nil, CastTime = nil, Mana = nil, Name = "Resurrection", Length = 0, Type = 0 },
		-- TWoW mounts some races get as a learned spell rather than a bag item (e.g. Tauren's
		-- "Riding Turtle") -- Holyward_UseMount checks this before falling back to bag scanning.
		[22] = { ID = nil, Rank = nil, CastTime = nil, Mana = nil, Name = "Riding Turtle", Length = 0, Type = 0 },
		-- TWoW Discipline 5th-row keystone talent (confirmed via in-game tooltip 2026-08-21: 1 min
		-- cooldown). Type 3 entries self-correct from the live GetSpellCooldown poll, so the exact
		-- Length here barely matters -- it's only a fallback before the first live read.
		[23] = { ID = nil, Rank = nil, CastTime = nil, Mana = nil, Name = "Enlighten", Length = 60, Type = 3 },
		-- Psychic Scream (AoE fear) -- tracked as a plain cooldown (like Necrosis does for Howl of
		-- Terror) rather than target-nominative, since it hits everything nearby at once.
		[24] = { ID = nil, Rank = nil, CastTime = nil, Mana = nil, Name = "Psychic Scream", Length = 30, Type = 3 },
		-- Discipline instant utility spell -- confirmed via in-game tooltip 2026-08-22 (SpellID
		-- 51478): 40s CD, instant, 25yd, 43 mana. Supersedes the earlier 30s figure from forum data.
		-- Type 3 self-corrects from the live cooldown poll regardless.
		[25] = { ID = nil, Rank = nil, CastTime = nil, Mana = nil, Name = "Chastise", Length = 40, Type = 3 },
		-- Holy row-7 capstone -- replaced the old "Holy Champion" system entirely. Confirmed via
		-- in-game tooltip 2026-08-21, re-confirmed 2026-08-22 (SpellID 52962): Rank 0/1, requires
		-- 1pt Spirit of Redemption + 30pts Holy, 252 mana, instant, 5 min CD. Purges CC and empowers
		-- healing on self for 30s; allies you heal gain Apotheosis, +15% healing received, 10s.
		-- Tracked as a plain Type 3 cooldown like Chastise/Pain Spike -- no dedicated menu button,
		-- same as this addon's other big solo CDs.
		[26] = { ID = nil, Rank = nil, CastTime = nil, Mana = nil, Name = "Ascendance", Length = 300, Type = 3 },
		-- Standard vanilla DoT duration, unchanged across every classic-era patch -- Type 4
		-- target-nominative like Shackle Undead, so it shows/refreshes per current target.
		[27] = { ID = nil, Rank = nil, CastTime = nil, Mana = nil, Name = "Shadow Word: Pain", Length = 18, Type = 4 },
		-- Holy Fire's burn DoT shares its exact name with the direct-damage spell itself (standard
		-- vanilla/classic behavior, 10 sec tick duration) -- Type 4 target-nominative like SW:Pain.
		[28] = { ID = nil, Rank = nil, CastTime = nil, Mana = nil, Name = "Holy Fire", Length = 10, Type = 4 },
		-- The Enlighten talent's proc buff -- confirmed via in-game tooltip 2026-08-21: named
		-- "Enlightened" (not "Enlighten"), Magic school, +15% spell damage and +15% healing done.
		-- No exact duration shown in the tooltip; 8s is the forum-reported figure (see Enlighten's
		-- own entry above) and only matters as a fallback since Type 6 reads the real expiration
		-- live off the player's own aura, same as the Buff Tracker. Not a castable spell (it's a
		-- proc), so .ID never gets set by the spellbook scan -- the icon is hardcoded like Weakened
		-- Soul's, since Blizzard's spellbook lookup that fills .Icon elsewhere doesn't apply here.
		-- Square, matching every other Ability Tracker slot (2026-08-22: reverted the round custom
		-- art -- the user only wanted round icons on the satellite buttons, not inside the trackers).
		[29] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Enlightened",
			Length = 8,
			Type = 6,
			Icon = "Interface\\Icons\\Spell_Holy_PowerInfusion",
		},
		-- Searing Light -- confirmed via in-game tooltip 2026-08-21: "Reduces the cast time by 100%
		-- and mana cost by 60% of your next Smite," Magic school, 10 sec. Proc, not a cast, so read
		-- live off the player's own aura like Enlightened. Icon confirmed by the user.
		[30] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Searing Light",
			Length = 10,
			Type = 6,
			Icon = "Interface\\Icons\\Spell_Holy_SearingLightPriest",
		},
		-- Purifying Flames -- confirmed via in-game tooltip 2026-08-21: "Increases holy damage done
		-- by 12%," Magic school, 10 sec. This is Holy Fire's actual proc buff, not the burn DoT it
		-- also leaves on the target (index 28) -- the user asked to prioritize tracking this over
		-- that DoT, so it took Holy Fire's old slot in HOLYWARD_ABILITY_TRACKER (Holyward.lua). Its
		-- .Icon is left nil here and synced from Holy Fire's live spellbook icon in Holyward_SpellSetup
		-- (Holyward.lua) instead -- the user confirmed the two share the same icon in-game, and Holy
		-- Fire's icon is already captured accurately there rather than guessed.
		[31] = { ID = nil, Rank = nil, CastTime = nil, Mana = nil, Name = "Purifying Flames", Length = 10, Type = 6 },
		-- Utility Menu slot 6 -- no timer, just a quick-cast button like Mind Soothe/Levitate.
		[32] = { ID = nil, Rank = nil, CastTime = nil, Mana = nil, Name = "Mind Vision", Length = 0, Type = 0 },
		-- Mana Potion -- not a spell, so .ID stays nil forever; the Ability Tracker's Type 3 branch
		-- reads .Item instead and pulls the cooldown off whichever mana potion tier is currently in
		-- bags via GetContainerItemCooldown (all potions share vanilla's single 120s "Potion" cooldown
		-- category, so any tier reports the same timer). HOLYWARD_MANA_POTION is defined further down
		-- this same file but assigned at load time, before this function is ever called, so the
		-- forward reference resolves fine.
		[33] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Mana Potion",
			Length = 120,
			Type = 3,
			Item = HOLYWARD_MANA_POTION,
			Icon = "Interface\\Icons\\INV_Potion_76",
		},
	}
end

------------------------------------------------------------------------------------------------------
-- CONSUMABLE / MOUNT DATA
-- Ascending order = ascending tier; the bag scanner keeps the highest-index (best) match found.
-- Water/Mount names are the real vanilla item names Holyward's own bag-scanner used; Bandage/Food
-- are a smaller best-effort list (less critical to get every tier exactly right).
------------------------------------------------------------------------------------------------------

HOLYWARD_DRINK = {
	{ Name = "Refreshing Spring Water", Level = 1 },
	{ Name = "Conjured Water", Level = 1 },
	{ Name = "Blended Bean Brew", Level = 5 },
	{ Name = "Ice Cold Milk", Level = 5 },
	{ Name = "Conjured Fresh Water", Level = 5 },
	{ Name = "Melon Juice", Level = 15 },
	{ Name = "Fizzy Faire Drink", Level = 15 },
	{ Name = "Bubbling Water", Level = 15 },
	{ Name = "Conjured Purified Water", Level = 15 },
	{ Name = "Sweet Nectar", Level = 25 },
	{ Name = "Goldthorn Tea", Level = 25 },
	{ Name = "Enchanted Water", Level = 25 },
	{ Name = "Green Garden Tea", Level = 25 },
	{ Name = "Conjured Spring Water", Level = 25 },
	{ Name = "Moonberry Juice", Level = 35 },
	{ Name = "Bottled Winterspring Water", Level = 35 },
	{ Name = "Conjured Mineral Water", Level = 35 },
	{ Name = "Morning Glory Dew", Level = 45 },
	{ Name = "Freshly-Squeezed Lemonade", Level = 45 },
	{ Name = "Conjured Sparkling Water", Level = 45 },
	{ Name = "Blessed Sunfruit Juice", Level = 45 },
	{ Name = "Bottled Alterac Spring Water", Level = 55 },
	{ Name = "Conjured Crystal Water", Level = 55 },
}

HOLYWARD_FOOD = {
	"Tough Jerky",
	"Haunch of Meat",
	"Cured Ham Steak",
	"Homemade Cherry Pie",
	"Conjured Bread",
	"Conjured Muffin",
	"Alterac Swiss",
	"Dalaran Sharp",
	"Conjured Croissant",
	"Mulgore Spice Bread",
	"Conjured Sourdough",
	"Wild Hog Shank",
	"Warpstone Ration",
}

HOLYWARD_MANA_POTION = {
	{ Name = "Minor Mana Potion", Level = 5 },
	{ Name = "Lesser Mana Potion", Level = 14 },
	{ Name = "Mana Potion", Level = 14 },
	{ Name = "Greater Mana Potion", Level = 31 },
	{ Name = "Combat Mana Potion", Level = 41 },
	{ Name = "Superior Mana Potion", Level = 41 },
	{ Name = "Major Mana Potion", Level = 49 },
}

HOLYWARD_HEALING_POTION = {
	{ Name = "Minor Healing Potion", Level = 1 },
	{ Name = "Lesser Healing Potion", Level = 3 },
	{ Name = "Discolored Healing Potion", Level = 5 },
	{ Name = "Healing Potion", Level = 12 },
	{ Name = "Greater Healing Potion", Level = 21 },
	{ Name = "Combat Healing Potion", Level = 35 },
	{ Name = "Superior Healing Potion", Level = 35 },
	{ Name = "Major Healing Potion", Level = 45 },
}

HOLYWARD_BANDAGE = {
	"Linen Bandage",
	"Heavy Linen Bandage",
	"Wool Bandage",
	"Heavy Wool Bandage",
	"Silk Bandage",
	"Heavy Silk Bandage",
	"Mageweave Bandage",
	"Heavy Mageweave Bandage",
	"Runecloth Bandage",
	"Heavy Runecloth Bandage",
}

-- Flattened from Holyward's original per-icon grouping; any known mount item works equally well
-- for a single always-use-what-I-have Mount button.
HOLYWARD_MOUNT = {
	"Horn of the Frostwolf Howler",
	"Stormpike Battle Charger", "Black Ram", "Black War Ram", "Brown Ram", "Frost Ram", "Gray Ram",
	"Swift Brown Ram", "Swift Gray Ram", "Swift White Ram", "White Ram",
	"Swift Razzashi Raptor", "Swift Blue Raptor", "Swift Olive Raptor", "Swift Orange Raptor",
	"Whistle of the Black War Raptor", "Whistle of the Emerald Raptor", "Whistle of the Ivory Raptor",
	"Whistle of the Mottled Red Raptor", "Whistle of the Turquoise Raptor", "Whistle of the Violet Raptor",
	"Swift Zulian Tiger",
	"Blue Skeletal Horse", "Blue Skeletal Warhorse", "Deathcharger's Reins", "Brown Skeletal Horse",
	"Green Skeletal Warhorse", "Purple Skeletal Warhorse", "Red Skeletal Horse", "Red Skeletal Warhorse",
	"Black Battlestrider", "Blue Mechanostrider", "Green Mechanostrider", "Icy Blue Mechanostrider Mod A",
	"Red Mechanostrider", "Swift Green Mechanostrider", "Swift White Mechanostrider",
	"Swift Yellow Mechanostrider", "Unpainted Mechanostrider", "White Mechanostrider Mod A",
	"Black Stallion Bridle", "Brown Horse Bridle", "Chestnut Mare Bridle", "Palomino Bridle",
	"Pinto Bridle", "Swift Brown Steed", "Swift Palomino", "Swift White Steed", "White Stallion Bridle",
	"Black War Kodo", "Brown Kodo", "Great Brown Kodo",
	"Black War Steed",
	"Gray Kodo", "Great Gray Kodo", "Great White Kodo",
	"Green Kodo", "Teal Kodo",
	"Horn of the Arctic Wolf", "Horn of the Dire Wolf", "Horn of the Swift Gray Wolf",
	"Horn of the Swift Timber Wolf",
	"Horn of the Black War Wolf", "Horn of the Brown Wolf", "Horn of the Red Wolf",
	"Horn of the Swift Brown Wolf", "Horn of the Timber Wolf",
	"Reins of the Black War Tiger", "Reins of the Striped Nightsaber",
	"Reins of the Frostsaber", "Reins of the Nightsaber", "Reins of the Spotted Frostsaber",
	"Reins of the Striped Frostsaber", "Reins of the Swift Frostsaber", "Reins of the Swift Mistsaber",
	"Reins of the Swift Stormsaber",
	"Reins of the Winterspring Frostsaber",
	"Black Qiraji Resonating Crystal",
}

Holyward_ResetSpellTable()

-- Type 0 = No timer
-- Type 1 = Main permanent timer
-- Type 2 = Permanent timer
-- Type 3 = Cooldown timer
-- Type 4 = Debuff-on-target timer (mutually exclusive per target)
-- Type 5 = Combat timer
-- Type 6 = Proc window (combat-log-detected buff, not a player-initiated cast)

HOLYWARD_TRANSLATION = {
	["Rank"] = "Rank",
	["Cooldown"] = "Cooldown",
}
