------------------------------------------------------------------------------------------------------
-- Holyward TurtleWoW
--
-- Priest addon in the style of Necrosis LdC, ported/adapted for TurtleWoW/OctoWoW.
------------------------------------------------------------------------------------------------------

HolywardData = {}
HolywardData.Version = GetAddOnMetadata("Holyward", "version")
HolywardData.AppName = "Holyward"
-- Same per-letter gradient as the .toc Title -- only used by the sphere's own tooltip (its one and
-- only reader), so embedding the color codes directly here is safe.
HolywardData.Label = "|CFFFFFFFFH|CFFFFF7DEo|CFFFFEFBEl|CFFFFE79Dy|CFFFFDF7Dw|CFFFFD75Ca|CFFFFD700r|CFFFFD700d|CFFFFFFFF "
	.. HolywardData.Version
