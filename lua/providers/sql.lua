-- Первый раз работаю с sql, возможен пиздец
metadmin.players = metadmin.players or {}

local function Start()
	if not sql.TableExists("answers") then
		sql.Query([[CREATE TABLE `answers` (
		`id` INTEGER PRIMARY KEY AUTOINCREMENT,
		`sid` text NOT NULL,
		`date` text NOT NULL,
		`questions` text NOT NULL,
		`answers` text NOT NULL,
		`status` int(11) NOT NULL DEFAULT '0'
		)]])
	end
	if not sql.TableExists("examinfo") then
		sql.Query([[CREATE TABLE `examinfo` (
		`id` INTEGER PRIMARY KEY AUTOINCREMENT,
		`SID` text NOT NULL,
		`date` text NOT NULL,
		`rank` text NOT NULL,
		`examiner` text NOT NULL,
		`note` text NOT NULL,
		`type` int(11) NOT NULL,
		`server` text NOT NULL
		)]])
	end
	if not sql.TableExists("players") then
		sql.Query([[CREATE TABLE `players` (
		`id` INTEGER PRIMARY KEY AUTOINCREMENT,
		`SID` text NOT NULL,
		`group` text NOT NULL,
		`status` text NOT NULL
		)]])
	end
	if not sql.TableExists("questions") then
		sql.Query([[CREATE TABLE `questions` (
		`id` INTEGER PRIMARY KEY AUTOINCREMENT,
		`name` text NOT NULL,
		`questions` text NOT NULL,
		`answers` text,
		`enabled` int(1) NOT NULL
		)]])
	end
	if not sql.TableExists("violations") then
		sql.Query([[CREATE TABLE `violations` (
		`id` INTEGER PRIMARY KEY AUTOINCREMENT,
		`SID` text NOT NULL,
		`date` text NOT NULL,
		`admin` text NOT NULL,
		`server` text NOT NULL,
		`violation` text NOT NULL
		)]])
	end
end
Start()
function GetData(sid,cb)
    local result = sql.Query("SELECT * FROM players WHERE SID='"..sid.."'")
	cb(result)
end

function SaveData(sid)
	if not metadmin.players[sid] then return end
	local rank = metadmin.players[sid].rank or "user"
	local status = util.TableToJSON(metadmin.players[sid].status)
	sql.Query("UPDATE `players` SET `group` = '"..rank.."',`status` = '"..status.."' WHERE `SID`="..sql.SQLStr(sid))
end

function CreateData(sid)
	local status = "{\"date\":"..os.time()..",\"nom\":1,\"admin\":\"\"}"
	result = sql.Query("INSERT INTO `players` (`id`,`SID`,`group`,`status`) VALUES (NULL,'"..sid.."','user','"..status.."')")
	local ply = player.GetBySteamID(sid)
	if ply then
		local userInfo = ULib.ucl.authed[ply:UniqueID()]
		local id = ULib.ucl.getUserRegisteredID(ply )
		if not id then id = ply:SteamID() end
		ULib.ucl.addUser(id,userInfo.allow,userInfo.deny,"user")
	end
	metadmin.players[sid] = {}
	metadmin.players[sid].rank = "user"
	metadmin.players[sid].status = {}
	metadmin.players[sid].status.nom = 1
	metadmin.players[sid].status.admin = ""
	metadmin.players[sid].status.date = 0
end

function GetQuestions(cb)
    local result = sql.Query("SELECT * FROM questions")
	if not result then result = {} end
	cb(result)
end

function SaveQuestion(id,questions,enabled)
	local table = ""
	if questions then
		table = "`questions` = '"..questions.."'"
	end
	local enbl = ""
	if enabled then
		enbl = "`enabled` = '"..enabled.."'"
		if questions then questions = questions.."," end
	end
   sql.Query("UPDATE `questions` SET "..table..enbl.." WHERE `id`="..tonumber(id))
end

function RemoveQuestion(id)
  sql.Query("DELETE FROM `questions` WHERE `id`='"..id.."'")
end

function AddQuestion(name)
    sql.Query("INSERT INTO `questions` (`id`,`name`,`questions`,`enabled`) VALUES (NULL,"..sql.SQLStr(name)..",'{}','0')")
end

function GetTests(sid,cb)
	local result = sql.Query("SELECT * FROM answers WHERE SID="..sql.SQLStr(sid).." ORDER BY id DESC")
	if not result then result = {} else
		for k,v in pairs(result) do
			result[k].status = tonumber(result[k].status) 
		end
	end
	cb(result)
end

function AddTest(sid,ques,ans)
	sql.Query("INSERT INTO `answers` (`id`,`sid`,`date`,`questions`,`answers`) VALUES (NULL,'"..sid.."','"..os.time().."','"..tonumber(ques).."',"..sql.SQLStr(ans)..")")
end

function SetStatusTest(id,status)
	sql.Query("UPDATE `answers` SET `status` = '"..status.."' WHERE `id`='"..tonumber(id).."'")
end

function GetViolations(sid,cb)
	local result = sql.Query("SELECT * FROM `violations` WHERE SID="..sql.SQLStr(sid).." ORDER BY id DESC")
	if not result then result = {} end
	cb(result)
end

function AddViolation(sid,adminsid,violation)
	if not adminsid then adminsid = "CONSOLE" end
	result = sql.Query("INSERT INTO `violations` (`id`,`SID`,`date`,`admin`,`server`,`violation`) VALUES (NULL,'"..sid.."','"..os.time().."','"..adminsid.."','"..metadmin.server.."',"..sql.SQLStr(violation)..")")
end

function RemoveViolation(id)
	sql.Query("DELETE FROM `violations` WHERE `id`="..id)
end

function GetExamInfo(sid,cb)
	local result = sql.Query("SELECT * FROM  `examinfo` WHERE SID="..sql.SQLStr(sid).." ORDER BY id DESC")
	if not result then result = {} end
	cb(result)
end
function AddExamInfo(sid,rank,adminsid,note,type)
	sql.Query("INSERT INTO `examinfo` (`SID`,`date`,`rank`,`examiner`,`note`,`type`,`server`) VALUES ('"..sid.."','"..os.time().."','"..rank.."','"..adminsid.."',"..sql.SQLStr(note)..",'"..type.."','"..metadmin.server.."')")
end

local badpl = true
function GetDataSID(sid,cb,nocreate)
	GetData(sid, function(data)
		if data and data[1] then
			metadmin.players[sid] = {}
			metadmin.players[sid].rank = data[1].group
			metadmin.players[sid].status = util.JSONToTable(data[1].status)
			if badpl then
				http.Fetch( "http://metrostroi.net/badpl.php?sid="..sid,function(body,len,headers,code) metadmin.players[sid].badpl = body != "" and body or false end)
			end
			local target = player.GetBySteamID(sid)
			if target then
				if target:GetUserGroup() != data[1].group then
					local userInfo = ULib.ucl.authed[target:UniqueID()]
					local id = ULib.ucl.getUserRegisteredID(target)
					if not id then id = sid end
					ULib.ucl.addUser(id,userInfo.allow,userInfo.deny,data[1].group)
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
hook.Add( "PlayerInitialSpawn", "sql", function(ply) GetDataSID(ply:SteamID()) end )