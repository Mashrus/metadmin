timer.Simple(1,function()
	local pr = ulx.command(metadmin.category, "ulx pr", metadmin.profile, "!pr")
	pr:defaultAccess(ULib.ACCESS_ALL)
	pr:addParam{ type=ULib.cmds.StringArg, hint="Игрок", ULib.cmds.takeRestOfLine, ULib.cmds.optional }
	pr:help("Профиль игрока.")

	local st = ulx.command(metadmin.category, "ulx setrank", metadmin.setrank, "!setrank")
	st:defaultAccess( ULib.ACCESS_SUPERADMIN )
	st:addParam{ type=ULib.cmds.StringArg, hint="PLAYER"}
	st:addParam{ type=ULib.cmds.StringArg, hint="RANK"}
	st:help("Установка ранга.")
end)