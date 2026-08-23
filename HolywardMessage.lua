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

function Holyward_MsgAddColor(msg)
	msg = string.gsub(msg, "<white>", "|CFFFFFFFF")
	msg = string.gsub(msg, "<lightBlue>", "|CFF99CCFF")
	msg = string.gsub(msg, "<brightGreen>", "|CFF00FF00")
	msg = string.gsub(msg, "<lightGreen2>", "|CFF66FF66")
	msg = string.gsub(msg, "<lightGreen1>", "|CFF99FF66")
	msg = string.gsub(msg, "<yellowGreen>", "|CFFCCFF66")
	msg = string.gsub(msg, "<lightYellow>", "|CFFFFFF66")
	msg = string.gsub(msg, "<darkYellow>", "|CFFFFCC00")
	msg = string.gsub(msg, "<lightOrange>", "|CFFFFCC66")
	msg = string.gsub(msg, "<dirtyOrange>", "|CFFFF9933")
	msg = string.gsub(msg, "<darkOrange>", "|CFFFF6600")
	msg = string.gsub(msg, "<redOrange>", "|CFFFF3300")
	msg = string.gsub(msg, "<red>", "|CFFFF0000")
	msg = string.gsub(msg, "<lightRed>", "|CFFFF5555")
	msg = string.gsub(msg, "<lightPurple1>", "|CFFFFC4FF")
	msg = string.gsub(msg, "<lightPurple2>", "|CFFFF99FF")
	msg = string.gsub(msg, "<purple>", "|CFFFF50FF")
	msg = string.gsub(msg, "<darkPurple1>", "|CFFFF00FF")
	msg = string.gsub(msg, "<darkPurple2>", "|CFFB700B7")
	msg = string.gsub(msg, "<close>", "|r")
	return msg
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
