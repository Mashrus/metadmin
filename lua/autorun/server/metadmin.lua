--Говно-код присутствует
local path = "providers/" .. metadmin.provider .. ".lua"
if not file.Exists(path, "LUA") then
	error("Не найдено. " .. path)
	return
end
include(path)
metadmin.players = metadmin.players or {}
util.AddNetworkString("metadmin.profile")
util.AddNetworkString("metadmin.violations")
util.AddNetworkString("metadmin.questions")
util.AddNetworkString("metadmin.answers")
util.AddNetworkString("metadmin.viewanswers")
util.AddNetworkString("metadmin.action")
util.AddNetworkString("metadmin.qaction")
util.AddNetworkString("metadmin.questionstab")
util.AddNetworkString("metadmin.notify")
util.AddNetworkString("metadmin.order")

for k,v in pairs(metadmin.pogona) do
	resource.AddFile(v)
end

local questionstab = {}
hook.Add( "InitPostEntity", "init", function()
	ULib.ucl.registerAccess("ma.pl", ULib.ACCESS_SUPERADMIN, "Возможность открывать меню с игроками.",metadmin.category)
	ULib.ucl.registerAccess("ma.questionsmenu", ULib.ACCESS_SUPERADMIN, "Возможность открывать меню вопросов.",metadmin.category)
	for k, v in pairs(metadmin.prom) do
		ULib.ucl.registerAccess("ma.prom"..v, ULib.ACCESS_SUPERADMIN, "Доступ к выдаче ранга '"..metadmin.ranks[v]..".",metadmin.category)
	end
	ULib.ucl.registerAccess("ma.questionscreate", ULib.ACCESS_SUPERADMIN, "Создание шаблона с вопросами.",metadmin.category)
	ULib.ucl.registerAccess("ma.questionsedit", ULib.ACCESS_SUPERADMIN, "Редактирование шаблона с вопросами'.",metadmin.category)
	ULib.ucl.registerAccess("ma.questionsremove", ULib.ACCESS_SUPERADMIN, "Удаление шаблона с вопросами.",metadmin.category)
	ULib.ucl.registerAccess("ma.questionsimn", ULib.ACCESS_SUPERADMIN, "Добавление/удаление шаблона из меню.",metadmin.category)
	ULib.ucl.registerAccess("ma.starttest", ULib.ACCESS_SUPERADMIN, "Доступ к 'Начать тест'.",metadmin.category)
	ULib.ucl.registerAccess("ma.viewresults", ULib.ACCESS_SUPERADMIN, "Просмотр рельзутатов теста.",metadmin.category)
	ULib.ucl.registerAccess("ma.promote", ULib.ACCESS_SUPERADMIN, "Повышение ранга игрока.",metadmin.category)
	ULib.ucl.registerAccess("ma.demote", ULib.ACCESS_SUPERADMIN, "Понижение ранга игрока.",metadmin.category)
	ULib.ucl.registerAccess("ma.examinfo", ULib.ACCESS_SUPERADMIN, "Просмотр информации о экзаменах.",metadmin.category)
	ULib.ucl.registerAccess("ma.violationgive", ULib.ACCESS_SUPERADMIN, "Выдача нарушения игроку.",metadmin.category)
	ULib.ucl.registerAccess("ma.violationremove", ULib.ACCESS_SUPERADMIN, "Удаление нарушения игроку.",metadmin.category)
	ULib.ucl.registerAccess("ma.viewviolations", ULib.ACCESS_SUPERADMIN, "Просмотр нарушений игрока.",metadmin.category)
	ULib.ucl.registerAccess("ma.settalon", ULib.ACCESS_SUPERADMIN, "Установка талона.",metadmin.category)
	ULib.ucl.registerAccess("ma.viewtalon", ULib.ACCESS_SUPERADMIN, "Просмотр талона.",metadmin.category)
	ULib.ucl.registerAccess("ma.setstattest", ULib.ACCESS_SUPERADMIN, "Установка статуса теста.",metadmin.category)
	ULib.ucl.registerAccess("ma.order", ULib.ACCESS_SUPERADMIN, "Доступ к приказам.",metadmin.category)
	timer.Simple(2.5, function()
		GetQuestions(
			function(data)
				for k, v in pairs(data) do
					id = tonumber(v.id)
					questionstab[id] = {}
					questionstab[id].name = v.name
					questionstab[id].questions = util.JSONToTable(v.questions)
					questionstab[id].enabled = tonumber(v.enabled)
				end
			end
		)
	end)
end)
hook.Add('MetrostroiPlombBroken', 'plomb', function(train,but,drv)
	local ply = train:GetDriver()
	if ply.plombs[but] then
		ply.plombs[but] = nil
	else
		but = metadmin.plombs and metadmin.plombs[but] or but
		net.Start("metadmin.notify")
			net.WriteString(ply:Nick().." cорвал пломбу с "..but.." без разрешения диспетчера.")
		net.Broadcast()
		AddViolation(ply:SteamID(),nil,"Cорвал пломбу с "..but.." без разрешения диспетчера.")
		GetViolations(ply:SteamID(), function(data)
			metadmin.players[ply:SteamID()].violations = data
		end)
	end
end)
local function spawn(ply)
	if ULib.ucl.query(ply,"ma.pl") then
		net.Start("metadmin.questionstab")
			net.WriteTable(questionstab)
		net.Send(ply)
	end
end
hook.Add("PlayerInitialSpawn", "questions", function(ply) spawn(ply) ply.plombs = {} end)

function refreshquestions()
	questionstab = {}
	GetQuestions(
		function(data)
			for k, v in pairs(data) do
				id = tonumber(v.id)
				questionstab[id] = {}
				questionstab[id].name = v.name
				questionstab[id].questions = util.JSONToTable(v.questions)
				questionstab[id].enabled = tonumber(v.enabled)
			end
			for k, v in pairs(player.GetAll()) do
				spawn(v)
			end
		end
	)
end

local function GetNick(sid,def)
	return (ULib.ucl.users[sid] and ULib.ucl.users[sid].name) or def
end

net.Receive( "metadmin.action", function(len, ply)
	if not ULib.ucl.query(ply,"ma.pl") then return end
	local sid = net.ReadString()
	local action = net.ReadInt(5)
	local str = net.ReadString()
	if action == 1 and ULib.ucl.query(ply,"ma.promote") then
		promotion(ply,sid,str)
	elseif action == 2 and ULib.ucl.query(ply,"ma.demote") then
		demotion(ply,sid,str)
	elseif action == 3 and ULib.ucl.query(ply,"ma.starttest") then
		questions(ply,sid,tonumber(str))
	elseif action == 4 and ULib.ucl.query(ply,"ma.viewresults") then
		view_answers(ply,sid,tonumber(str))
	elseif action == 5 and ULib.ucl.query(ply,"ma.setstattest") then
		SetStatusTest(str,net.ReadInt(4))
		GetTests(sid, function(data)
			metadmin.players[sid].exam_answers = data
		end)
		ply:ChatPrint("Статус изменен")
	elseif action == 7 and ULib.ucl.query(ply,"ma.settalon") then
		settalon(ply,sid,1)
	elseif action == 8 and ULib.ucl.query(ply,"ma.settalon") then
		settalon(ply,sid,2)
	end
end)

net.Receive( "metadmin.order", function(len, ply)
	if not ULib.ucl.query(ply,"ma.order") then return end
	local tar = net.ReadEntity()
	local plomb = net.ReadString()
	if not metadmin.plombs[plomb] then return end
	tar.plombs[plomb] = true
	net.Start("metadmin.notify")
		net.WriteString(ply:Nick().." разрешил "..tar:Nick().." сорвать пломбу с "..metadmin.plombs[plomb])
	net.Broadcast()
end)

function settalon(ply,sid,type)
	if metadmin.players[sid] then
		if type == 2 then
			if metadmin.players[sid].status.nom + 1 <= 3 then
				metadmin.players[sid].status.nom = metadmin.players[sid].status.nom + 1
				metadmin.players[sid].status.date = os.time()
				metadmin.players[sid].status.admin = ply:SteamID()
				ply:ChatPrint("Вы успешно отобрали талон.")
				SaveData(sid)
			end
		else
			if metadmin.players[sid].status.nom - 1 > 0 then
				metadmin.players[sid].status.nom = metadmin.players[sid].status.nom - 1
				metadmin.players[sid].status.date = os.time()
				metadmin.players[sid].status.admin = ply:SteamID()
				ply:ChatPrint("Вы успешно вернули талон.")
				SaveData(sid)
			end
		end
	else
		GetDataSID(sid,function() settalon(ply,sid,type) end)
	end
end

net.Receive( "metadmin.violations", function(len, ply)
	if not ULib.ucl.query(ply,"ma.viewviolations") then return end
	local action = net.ReadInt(3)
	local sid = net.ReadString()
	local str = net.ReadString()
	if action == 1 and ULib.ucl.query(ply,"ma.violationgive") then
		violationgive(ply,sid,str)
	elseif action == 2 and ULib.ucl.query(ply,"ma.violationremove") then
		violationremove(ply,sid,str)
	end
end)

function violationgive(call,sid,str)
	AddViolation(sid,call:SteamID(),str)
	call:ChatPrint("Нарушение добавлено.")
	GetViolations(sid, function(data)
		metadmin.players[sid].violations = data
	end)
end

function violationremove(call,sid,id)
	id = tonumber(id)
	if IsValid(call) then
		call:ChatPrint("Нарушение удалено.")
	end
	GetViolations(sid, function(data)
		metadmin.players[sid].violations = data
	end)
	RemoveViolation(id)
end

function metadmin.profile(call,sid)
	if sid == "" then sid = call:SteamID() end
	if not string.match( sid,"(STEAM_[0-5]:[01]:%d+)") then
		for k, v in pairs(player.GetAll()) do
			if string.find(string.lower(v:Nick()),string.lower(sid)) then
				sid = v:SteamID()
			end
		end 
	end
	if not string.match( sid,"(STEAM_[0-5]:[01]:%d+)") then return end
	if metadmin.players[sid] then
		local tab = {}
		local target = player.GetBySteamID(sid)
		if target == call or ULib.ucl.query(call,"ma.viewviolations") then
			tab.violations = metadmin.players[sid].violations
			for k,v in pairs(tab.violations) do
				tab.violations[k].admin = GetNick(v.admin,v.admin)
			end
		end
		if target == call or ULib.ucl.query(call,"ma.examinfo") then
			tab.exam = metadmin.players[sid].exam
			for k,v in pairs(tab.exam) do
				tab.exam[k].examiner = GetNick(v.examiner,v.examiner)
			end
		end
		if target == call or ULib.ucl.query(call,"ma.viewtalon") then
			tab.status = metadmin.players[sid].status
			tab.status.admin = GetNick(tab.status.admin,tab.status.admin)
		end
		if ULib.ucl.query(call,"ma.viewresults") then
			tab.exam_answers = metadmin.players[sid].exam_answers
		end
		tab.rank = metadmin.players[sid].rank
		tab.SID = sid
		tab.Nick = GetNick(sid,"UNKNOWN")
		tab.badpl = metadmin.players[sid].badpl
		tab.nvio = #metadmin.players[sid].violations
		net.Start("metadmin.profile")
			net.WriteTable(tab)
		net.Send(call)
	else
		GetDataSID(sid,function() profile(call,sid) end,true)
	end
end

function metadmin.setrank(call,sid,rank)
	if not string.match( sid,"(STEAM_[0-5]:[01]:%d+)") then
		for k, v in pairs(player.GetAll()) do
			if string.find(string.lower(v:Nick()),string.lower(sid)) then
				sid = v:SteamID()
			end
		end 
	end
	if not string.match( sid,"(STEAM_[0-5]:[01]:%d+)") then return end
	if metadmin.players[sid] then
		if metadmin.ranks[rank] then
			if metadmin.players[sid].rank == rank then return end
			metadmin.players[sid].rank = rank
			SaveData(sid)
			local target = player.GetBySteamID(sid)
			if target then
				local userInfo = ULib.ucl.authed[target:UniqueID()]
				local id = ULib.ucl.getUserRegisteredID(target)
				if not id then id = sid end
				ULib.ucl.addUser( id, userInfo.allow, userInfo.deny, rank )
				spawn(target)
			end
			local nick = IsValid(call) and call:Nick() or "CONSOLE"
			local steamid = IsValid(call) and call:SteamID() or "CONSOLE"
			net.Start("metadmin.notify")
				net.WriteString(nick.." установил ранг игроку "..GetNick(sid,sid).."|"..metadmin.ranks[rank])
			net.Broadcast()
			AddExamInfo(sid,rank,steamid,"Установка ранга через команду.",3)
			timer.Simple(1,function()
				GetExamInfo(sid, function(data)
					metadmin.players[sid].exam = data
				end)
			end)
		end
	else
		GetDataSID(sid,function() metadmin.setrank(call,sid,rank) end,true)
	end
end

function promotion(call,sid,note)
	if not ULib.ucl.query(call,"ma.promote") then return end
	if metadmin.players[sid] then
		local group = metadmin.players[sid].rank
		local newgroup = metadmin.prom[group]
		if not newgroup then return end
		if not ULib.ucl.query(call,"ma.prom"..newgroup) then return end
		local target = player.GetBySteamID(sid)
		if target then
			local userInfo = ULib.ucl.authed[target:UniqueID()]
			local id = ULib.ucl.getUserRegisteredID(target)
			if not id then id = sid end
			ULib.ucl.addUser(id, userInfo.allow, userInfo.deny, newgroup)
		end
		local nick = GetNick(sid,sid)
		net.Start("metadmin.notify")
			net.WriteString("Игрок "..nick.." был повышен. Теперь он "..metadmin.ranks[newgroup])
		net.Broadcast()
		AddExamInfo(sid,newgroup,call:SteamID(),note,1)
		metadmin.players[sid].rank = newgroup
		SaveData(sid)
		GetExamInfo(sid, function(data)
			metadmin.players[sid].exam = data
		end)
	else
		GetDataSID(sid,function() promotion(call,sid,note) end)
	end
end
function demotion(call,sid,note)
	if not ULib.ucl.query(call,"ma.demote") then return end
	if metadmin.players[sid] then
		local group = metadmin.players[sid].rank
		local newgroup = metadmin.dem[group]
		if not newgroup then return end
		local target = player.GetBySteamID(sid)
		if target then
			local userInfo = ULib.ucl.authed[target:UniqueID()]
			local id = ULib.ucl.getUserRegisteredID( target )
			if not id then id = target:SteamID() end
			ULib.ucl.addUser( id, userInfo.allow, userInfo.deny, newgroup )
		end
		local nick = GetNick(sid,sid)
		net.Start("metadmin.notify")
			net.WriteString("Игрок "..nick.." был понижен. Теперь он "..metadmin.ranks[newgroup])
		net.Broadcast()
		AddExamInfo(sid,newgroup,call:SteamID(),note,2)
		metadmin.players[sid].rank = newgroup
		SaveData(sid)
		GetExamInfo(sid, function(data)
			metadmin.players[sid].exam = data
		end)
	else
		GetDataSID(sid,function() demotion(call,sid,note) end)
	end
end

net.Receive( "metadmin.qaction", function(len, ply)
	if not ULib.ucl.query(ply,"ma.questionsmenu") then return end
	local action = net.ReadInt(5)
	local id = net.ReadInt(32)
	if action == 1 and questionstab[id] and ULib.ucl.query(ply,"ma.questionsimn") then
		if questionstab[id].enabled == 1 then action = "отключен" else action = "включен" end
		ply:ChatPrint("Шаблон "..questionstab[id].name.." успешно "..action)
		SaveQuestion(id,nil,questionstab[id].enabled == 1 and 0 or 1)
		refreshquestions()
	elseif action == 2 and questionstab[id] and ULib.ucl.query(ply,"ma.questionsremove") then
		ply:ChatPrint("Шаблон "..questionstab[id].name.." успешно удален")
		RemoveQuestion(id)
		refreshquestions()
	elseif action == 3 and questionstab[id] and ULib.ucl.query(ply,"ma.questionsedit") then
		local tab = net.ReadTable()
		SaveQuestion(id,util.TableToJSON(tab))
		ply:ChatPrint("Шаблон "..questionstab[id].name.." успешно изменен")
		refreshquestions()
	elseif action == 4 and ULib.ucl.query(ply,"ma.questionscreate") then
		local name = net.ReadString()
		AddQuestion(name)
		ply:ChatPrint("Шаблон "..name.." успешно добавлен")
		refreshquestions()
	else return end
end)

function questions(call,sid,id)
	local target = player.GetBySteamID(sid)
	if target then
		if target:GetNWBool("anstoques",false) then call:ChatPrint("Игрок еще не ответил на предыдущий тест!") return end
		if not questionstab[id] then return call:ChatPrint("Такого шаблона нет!") end
		if questionstab[id].enabled == 0 then return call:ChatPrint("Этот шаблон отключен!") end
		net.Start("metadmin.questions")
			net.WriteTable({questions = questionstab[id].questions,name = questionstab[id].name,id = id})
		net.Send(target)
		target:SetNWBool("anstoques",true)
		call:ChatPrint("Вопросы("..questionstab[id].name..") отправленны игроку "..target:Nick())
	end
end
function view_answers(call,sid,id)
	if metadmin.players[sid] then
		local tab = {}
		for k,v in pairs(metadmin.players[sid].exam_answers) do
			if tonumber(v.id) == id then
				tab.answerstab = v
				tab.answers = util.JSONToTable(v.answers)
			end
		end
		if not tab then return end
		tab.nick = GetNick(sid,"UNKNOWN")
		tab.sid = sid
		tab.questions = questionstab[tonumber(tab.answerstab.questions)].questions
		net.Start("metadmin.viewanswers")
			net.WriteTable(tab)
		net.Send(call)
	else
		GetDataSID(sid,function() view_answers(call,sid,id) end)
	end
end
net.Receive( "metadmin.answers", function(len, ply)
	if not ply:GetNWBool("anstoques",false) then return end
	local tab = net.ReadTable()
	if questionstab[tab.id].enabled == 0 then return end
	net.Start("metadmin.notify")
		net.WriteString("Игрок "..ply:Nick().." ответил на вопросы теста. Его результат записан и вскоре будет проверен.")
	net.Broadcast()
	ply:SetNWBool("anstoques",false)
	AddTest(ply:SteamID(),tab.id,util.TableToJSON(tab.ans))
	GetTests(ply:SteamID(), function(data)
		metadmin.players[ply:SteamID()].exam_answers = data
	end)
end)