require('mysqloo')

local db = mysqloo.connect('localhost', 'root', '', '', 3306) -- Хост,юзер,пароль,название бд, порт

function db:onConnected()
	local utf8 = db:query("SET names 'utf8'")
	utf8:start()
    MsgN('MySQL: Подключено!')
end

function db:onConnectionFailed(err)
    MsgN('MySQL: Ошибка: ' .. err)
end

db:connect()
metadmin.players = metadmin.players or {}

function GetData(sid,cb)
    local q = db:query("SELECT * FROM players WHERE SID='"..db:escape(sid).."'")
    q.onSuccess = function(self, data)
		cb(data)
    end
	 
  q.onError = function(err, sql)
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            db:connect()
            db:wait()
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            ErrorNoHalt("Переподключение не удалось.")
            return
            end
        end
        MsgN('MySQL: Ошибка запроса: ' .. err .. ' (' .. sql .. ')')
        q:start()
    end
     
    q:start()
end

function SaveData(sid)
	if not metadmin.players[sid] then return end
	local rank = metadmin.players[sid].rank or "user"
	local status = util.TableToJSON(metadmin.players[sid].status)
    local q = db:query("UPDATE `players` SET `group` = '"..rank.."',`status` = '"..status.."' WHERE `SID`='"..db:escape(sid).."'")
     
    function q:onSuccess()
		print("Saved")
    end
	 
    function q:onError(err, sql)
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            db:connect()
            db:wait()
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            ErrorNoHalt("Переподключение не удалось.")
            return
            end
        end
        MsgN('MySQL: Ошибка запроса: ' .. err .. ' (' .. sql .. ')')
        q:start()
    end
     
    q:start()
end

function CreateData(sid)
	local status = "{\"date\":"..os.time()..",\"nom\":1,\"admin\":\"\"}"
	local group = "user"
    local q = db:query("INSERT INTO `players` (`SID`,`group`,`status`) VALUES ('"..sid.."','"..group.."','"..status.."')")
	local group = "user"
	local ply = player.GetBySteamID(sid)
	if ply then
		if metadmin.groupwrite then
			group = ply:GetUserGroup()
		else
			local userInfo = ULib.ucl.authed[ply:UniqueID()]
			local id = ULib.ucl.getUserRegisteredID(ply)
			if not id then id = ply:SteamID() end
			ULib.ucl.addUser(id,userInfo.allow,userInfo.deny,group)
		end
	end
	metadmin.players[sid] = {}
	metadmin.players[sid].rank = group
	metadmin.players[sid].status = {}
	metadmin.players[sid].status.nom = 1
	metadmin.players[sid].status.admin = ""
	metadmin.players[sid].status.date = 0
    function q:onError(err, sql)
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            db:connect()
            db:wait()
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            ErrorNoHalt("Переподключение не удалось.")
            return
            end
        end
        MsgN('MySQL: Ошибка запроса: ' .. err .. ' (' .. sql .. ')')
        q:start()
    end
     
    q:start()
end

function GetQuestions(cb)
    local q = db:query("SELECT * FROM questions")
    q.onSuccess = function(self, data)
		cb(data)
    end
	 
  q.onError = function(err, sql)
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            db:connect()
            db:wait()
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            ErrorNoHalt("Переподключение не удалось.")
            return
            end
        end
        MsgN('MySQL: Ошибка запроса: ' .. err .. ' (' .. sql .. ')')
        q:start()
    end
     
    q:start()
end

function SaveQuestion(id,questions,inmenu)
	local table = ""
	if questions then
		table = "`questions` = '"..questions.."'"
	end
	local inm = ""
	if inmenu then
		inm = "`inmenu` = '"..inmenu.."'"
		if questions then questions = questions.."," end
	end
   local q = db:query("UPDATE `questions` SET "..table..inm.." WHERE `id`='"..id.."'")
  q.onError = function(err, sql)
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            db:connect()
            db:wait()
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            ErrorNoHalt("Переподключение не удалось.")
            return
            end
        end
        MsgN('MySQL: Ошибка запроса: ' .. err .. ' (' .. sql .. ')')
        q:start()
    end
     
    q:start()
end

function RemoveQuestion(id)
  local q = db:query("DELETE FROM `questions` WHERE `id`='"..id.."'")
  q.onError = function(err, sql)
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            db:connect()
            db:wait()
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            ErrorNoHalt("Переподключение не удалось.")
            return
            end
        end
        MsgN('MySQL: Ошибка запроса: ' .. err .. ' (' .. sql .. ')')
        q:start()
    end
     
    q:start()
end

function AddQuestion(name)
    local q = db:query("INSERT INTO `questions` (`name`,`questions`,`inmenu`) VALUES ('"..db:escape(name).."','{}','0')")
  q.onError = function(err, sql)
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            db:connect()
            db:wait()
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            ErrorNoHalt("Переподключение не удалось.")
            return
            end
        end
        MsgN('MySQL: Ошибка запроса: ' .. err .. ' (' .. sql .. ')')
        q:start()
    end
     
    q:start()
end

function GetTests(sid,cb)
    local q = db:query("SELECT * FROM answers WHERE SID='"..db:escape(sid).."' ORDER BY id DESC")
    q.onSuccess = function(self, data)
		cb(data)
    end
	q.onError = function(err, sql)
		if db:status() ~= mysqloo.DATABASE_CONNECTED then
			db:connect()
			db:wait()
			if db:status() ~= mysqloo.DATABASE_CONNECTED then
				ErrorNoHalt("Переподключение не удалось.")
				return
			end
		end
		MsgN('MySQL: Ошибка запроса: ' .. err .. ' (' .. sql .. ')')
		q:start()
	end

	q:start()
end

function AddTest(sid,ques,ans)
    local q = db:query("INSERT INTO `answers` (`sid`,`date`,`questions`,`answers`) VALUES ('"..db:escape(sid).."','"..os.time().."','"..tonumber(ques).."','"..db:escape(ans).."')")
  q.onError = function(err, sql)
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            db:connect()
            db:wait()
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            ErrorNoHalt("Переподключение не удалось.")
            return
            end
        end
        MsgN('MySQL: Ошибка запроса: ' .. err .. ' (' .. sql .. ')')
        q:start()
    end
     
    q:start()
end

function SetStatusTest(id,status)
    local q = db:query("UPDATE `answers` SET `status` = '"..tonumber(status).."' WHERE `id`='"..tonumber(id).."'")
  q.onError = function(err, sql)
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            db:connect()
            db:wait()
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            ErrorNoHalt("Переподключение не удалось.")
            return
            end
        end
        MsgN('MySQL: Ошибка запроса: ' .. err .. ' (' .. sql .. ')')
        q:start()
    end
     
    q:start()
end

function GetViolations(sid,cb)
	local q = db:query("SELECT * FROM  `violations` WHERE SID='"..db:escape(sid).."' ORDER BY id DESC")
	q.onSuccess = function(self, data)
		cb(data)
	end
	q.onError = function(err, sql)
		if db:status() ~= mysqloo.DATABASE_CONNECTED then
			db:connect()
			db:wait()
			if db:status() ~= mysqloo.DATABASE_CONNECTED then
				ErrorNoHalt("Переподключение не удалось.")
				return
			end
		end
		MsgN('MySQL: Ошибка запроса: ' .. err .. ' (' .. sql .. ')')
		q:start()
	end
	q:start()
end

function AddViolation(sid,adminsid,violation)
	if not adminsid then adminsid = "CONSOLE" end
	local q = db:query("INSERT INTO `violations` (`SID`,`date`,`admin`,`server`,`violation`) VALUES ('"..db:escape(sid).."','"..os.time().."','"..adminsid.."','"..db:escape(metadmin.server).."','"..db:escape(violation).."')")
	q.onError = function(err, sql)
		if db:status() ~= mysqloo.DATABASE_CONNECTED then
			db:connect()
			db:wait()
			if db:status() ~= mysqloo.DATABASE_CONNECTED then
				ErrorNoHalt("Переподключение не удалось.")
				return
			end
		end
		MsgN('MySQL: Ошибка запроса: ' .. err .. ' (' .. sql .. ')')
		q:start()
	end
	q:start()
end

function RemoveViolation(id)
	local q = db:query("DELETE FROM `violations` WHERE `id`='"..id.."'")
	q.onError = function(err, sql)
		if db:status() ~= mysqloo.DATABASE_CONNECTED then
			db:connect()
			db:wait()
			if db:status() ~= mysqloo.DATABASE_CONNECTED then
				ErrorNoHalt("Переподключение не удалось.")
				return
			end
		end
		MsgN('MySQL: Ошибка запроса: ' .. err .. ' (' .. sql .. ')')
		q:start()
	end
	q:start()
end

function GetExamInfo(sid,cb)
	local q = db:query("SELECT * FROM  `examinfo` WHERE SID='"..db:escape(sid).."' ORDER BY id DESC")
	q.onSuccess = function(self, data)
		cb(data)
	end
	q.onError = function(err, sql)
		if db:status() ~= mysqloo.DATABASE_CONNECTED then
			db:connect()
			db:wait()
			if db:status() ~= mysqloo.DATABASE_CONNECTED then
				ErrorNoHalt("Переподключение не удалось.")
				return
			end
		end
		MsgN('MySQL: Ошибка запроса: ' .. err .. ' (' .. sql .. ')')
		q:start()
	end
	q:start()
end
function AddExamInfo(sid,rank,adminsid,note,type)
	local q = db:query("INSERT INTO `examinfo` (`SID`,`date`,`rank`,`examiner`,`note`,`type`,`server`) VALUES ('"..db:escape(sid).."','"..os.time().."','"..rank.."','"..adminsid.."','"..db:escape(note).."','"..type.."','"..db:escape(metadmin.server).."')")
	q.onError = function(err, sql)
		if db:status() ~= mysqloo.DATABASE_CONNECTED then
			db:connect()
			db:wait()
			if db:status() ~= mysqloo.DATABASE_CONNECTED then
				ErrorNoHalt("Переподключение не удалось.")
				return
			end
		end
		MsgN('MySQL: Ошибка запроса: ' .. err .. ' (' .. sql .. ')')
		q:start()
	end
	q:start()
end

local badpl = true
function GetDataSID(sid,cb,nocreate)
	sid = db:escape(sid)
	GetData(sid, function(data)
		if data[1] then
			metadmin.players[sid] = {}
			metadmin.players[sid].rank = data[1].group
			metadmin.players[sid].status = util.JSONToTable(data[1].status)
			if badpl then
				http.Fetch( "http://metrostroi.net/badpl.php?sid="..sid,function(body,len,headers,code) metadmin.players[sid].badpl = body != "" and body or false end)
			end
			local target = player.GetBySteamID(sid)
			if target then
				if target:GetUserGroup() != data[1].group then
					local userInfo = ULib.ucl.authed[ target:UniqueID() ]
					local id = ULib.ucl.getUserRegisteredID( target )
					if not id then id = sid end
					ULib.ucl.addUser( id, userInfo.allow, userInfo.deny, data[1].group )
				end
			end
		else
			if nocreate then return end
			CreateData(sid)
		end
		GetViolations(sid, function(data)
			metadmin.players[sid].violations = data
		end)
		GetExamInfo(sid, function(data)
			metadmin.players[sid].exam = data
		end)
		GetTests(sid, function(data)
			metadmin.players[sid].exam_answers = data
		end)
		if cb then
			timer.Simple( 0.25, function() cb() end )
		end
	end)
end
hook.Add( "PlayerInitialSpawn", "mysql", function(ply) GetDataSID(ply:SteamID()) end )