------------------------------------------------------------------------------------------------------
-- Holyward TurtleWoW
------------------------------------------------------------------------------------------------------

function Holyward_Msg(msg, msgType)
	if msg and msgType then
		if msgType == "USER" then
			msg = Holyward_MsgAddColor(msg)
			-- Same per-letter gradient as the .toc Title (white -> gold across "Holyward"), so the
			-- addon reads identically in chat as it does in the addon list.
			local Intro =
				"|CFFFFFFFFH|CFFFFF7DEo|CFFFFEFBEl|CFFFFE79Dy|CFFFFDF7Dw|CFFFFD75Ca|CFFFFD700r|CFFFFD700d|CFFFFFFFF: "
			if HolywardConfig.ChatType then
				ChatFrame1:AddMessage(Intro .. msg, 1.0, 0.7, 1.0, 1.0, UIERRORS_HOLD_TIME)
			else
				UIErrorsFrame:AddMessage(Intro .. msg, 1.0, 0.7, 1.0, 1.0, UIERRORS_HOLD_TIME)
			end
		elseif msgType == "WORLD" then
			if GetNumRaidMembers() > 0 then
				SendChatMessage(msg, "RAID")
			elseif GetNumPartyMembers() > 0 then
				SendChatMessage(msg, "PARTY")
			else
				SendChatMessage(msg, "SAY")
			end
		elseif msgType == "PARTY" then
			SendChatMessage(msg, "PARTY")
		elseif msgType == "RAID" then
			SendChatMessage(msg, "RAID")
		elseif msgType == "SAY" then
			SendChatMessage(msg, "SAY")
		end
	end
end

-- PERFORMANCE (2026-09-10, per the user's pfDebug report -- HolywardButton:OnUpdate() was the
-- single highest memory consumer of every addon installed, 17244 kB): this used to be 20 CHAINED
-- string.gsub calls, each one scanning and copying the ENTIRE string top to bottom regardless of
-- whether it actually found anything to replace -- string.gsub always builds and returns a new
-- string via its internal buffer, even on zero matches. Called once a second from the timer sweep
-- (Holyward_OnUpdate's UpdateStage 4, via Holyward_DisplayTimer's output) for as long as the
-- session runs, that's up to 20 full-string copies every single second, forever -- a real, sustained
-- memory-churn source, not a one-off cost. A single gsub with a lookup TABLE as the replacement
-- (standard Lua string library behavior: the matched substring is used as a key into the table: a
-- present, truthy value replaces the match, nil/false leaves it unchanged) does the exact same
-- substitutions in ONE pass over the string instead of 20. `<%a+%d?>` matches every tag this table
-- actually defines (one or more letters, optionally followed by a single trailing digit, e.g.
-- "lightGreen2") and nothing else that wasn't already being left alone before.
local HOLYWARD_COLOR_TAGS = {
	["<white>"] = "|CFFFFFFFF",
	["<lightBlue>"] = "|CFF99CCFF",
	["<brightGreen>"] = "|CFF00FF00",
	["<lightGreen2>"] = "|CFF66FF66",
	["<lightGreen1>"] = "|CFF99FF66",
	["<yellowGreen>"] = "|CFFCCFF66",
	["<lightYellow>"] = "|CFFFFFF66",
	["<darkYellow>"] = "|CFFFFCC00",
	["<lightOrange>"] = "|CFFFFCC66",
	["<dirtyOrange>"] = "|CFFFF9933",
	["<darkOrange>"] = "|CFFFF6600",
	["<redOrange>"] = "|CFFFF3300",
	["<red>"] = "|CFFFF0000",
	["<lightRed>"] = "|CFFFF5555",
	["<lightPurple1>"] = "|CFFFFC4FF",
	["<lightPurple2>"] = "|CFFFF99FF",
	["<purple>"] = "|CFFFF50FF",
	["<darkPurple1>"] = "|CFFFF00FF",
	["<darkPurple2>"] = "|CFFB700B7",
	["<close>"] = "|r",
}

function Holyward_MsgAddColor(msg)
	-- Wrapped in parens to keep only gsub's first return value (the string) -- it also returns the
	-- match count as a second value, which callers here never expect.
	return (string.gsub(msg, "<%a+%d?>", HOLYWARD_COLOR_TAGS))
end

function HolywardTimerColor(percent)
	local color = "<brightGreen>"
	if percent < 10 then
		color = "<red>"
	elseif percent < 20 then
		color = "<redOrange>"
	elseif percent < 30 then
		color = "<darkOrange>"
	elseif percent < 40 then
		color = "<dirtyOrange>"
	elseif percent < 50 then
		color = "<darkYellow>"
	elseif percent < 60 then
		color = "<lightYellow>"
	elseif percent < 70 then
		color = "<yellowGreen>"
	elseif percent < 80 then
		color = "<lightGreen1>"
	elseif percent < 90 then
		color = "<lightGreen2>"
	end
	return color
end

function Holyward_MsgReplace(msg, target)
	msg = string.gsub(msg, "<player>", UnitName("player"))
	if target then
		msg = string.gsub(msg, "<target>", target)
	end
	return msg
end
