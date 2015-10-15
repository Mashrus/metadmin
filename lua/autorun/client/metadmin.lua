net.Receive("metadmin.profile", function()
	metadmin.profile(net.ReadTable())
end)
net.Receive("metadmin.questions", function()
	metadmin.question(net.ReadTable())
end)
net.Receive("metadmin.viewanswers", function()
	metadmin.viewanswers(net.ReadTable())
end)
metadmin.questions = metadmin.questions or {}
net.Receive("metadmin.questionstab", function()
	metadmin.questions = net.ReadTable()
end)
net.Receive("metadmin.notify", function()
  chat.AddText(Color(129,207,224),net.ReadString())
end)
CreateClientConVar( "metadmin_preview", 1, true, false )
local buttonmenu = CreateClientConVar( "metadmin_buttonmenu", "F4", true, false )

local function Access(permis)
	return ULib.ucl.query(LocalPlayer(),permis)
end

function metadmin.menu()
	local Frame = vgui.Create( "DFrame" )
	Frame:SetSize( 800, 260 )
	Frame:SetTitle("Меню")
	Frame:SetDraggable( true )
	Frame.btnMaxim:SetVisible(false)
	Frame.btnMinim:SetVisible(false)
	Frame:MakePopup()
	Frame:Center()
	if Access("ma.questionsmenu") then
		local questlist = vgui.Create("DButton",Frame)
		questlist:SetPos(630,2.5)
		questlist:SetText("Вопросы")
		questlist:SetSize(60,20)
		questlist.DoClick = function() metadmin.questionslist() Frame:Close() end
	end
	local settings = vgui.Create("DButton",Frame)
	settings:SetPos(690,2.5)
	settings:SetText("Настройки")
	settings:SetSize(70,20)
	settings.DoClick = function() metadmin.settings() Frame:Close() end
	local playerslist = vgui.Create("DListView",Frame)
	playerslist:SetPos(10,30)
	playerslist:SetSize(780,220)
	playerslist:SetMultiSelect(false)
	if Access("ma.order") then
		local menu
		playerslist.OnClickLine = function(panel,line)
			if IsValid(menu) then menu:Remove() end
			line:SetSelected(true)
			menu = DermaMenu()
			local header = menu:AddOption(line:GetValue(1))
			header:SetTextInset(10,0)
			header.PaintOver = function() surface.SetDrawColor(0,0,0,50) surface.DrawRect(0,0,header:GetWide(),header:GetTall()) end
		
			local row = menu:AddOption("Профиль", function()
				RunConsoleCommand("ulx","pr",line:GetValue(3))
				Frame:Close()
			end)
			row:SetIcon("icon16/information.png")
		
			local sub, row = menu:AddSubMenu("Приказы")
			row:SetIcon("icon16/application_error.png")
				local sub2, row = sub:AddSubMenu("Пломбы")
				row:SetTextInset(10,0)
					for k,v in pairs(metadmin.plombs) do
						local row = sub2:AddOption(v, function()
							net.Start("metadmin.order")
								net.WriteEntity(line.ply)
								net.WriteString(k)
							net.SendToServer()
							Frame:Close()
						end)
						row:SetTextInset(10,0)
					end
			
			local row = menu:AddOption("Отмена")
			row:SetIcon("icon16/cancel.png")
		
			menu.Remove = function(m)
				if IsValid(line) then
					line:SetSelected(false)
				end
			end
			menu:Open()
		end
	else
		playerslist.DoDoubleClick = function(parent,index,list)
			RunConsoleCommand("ulx","pr",list:GetValue(3))
			Frame:Close()
		end
	end
	playerslist:AddColumn("Ник"):SetFixedWidth(400)
	playerslist:AddColumn("Группа"):SetFixedWidth(180)
	playerslist:AddColumn("SteamID"):SetFixedWidth(200)
	for k,v in pairs(player.GetAll()) do
		local line = playerslist:AddLine(v:Nick(),metadmin.ranks[v:GetUserGroup()],v:SteamID())
		line.ply = v
	end
end

local buttons = {["F2"] = KEY_F2,["F3"] = KEY_F3,["F4"] = KEY_F4}
function metadmin.settings()
	local Frame = vgui.Create("DFrame")
	Frame:SetSize(220,85)
	Frame:SetTitle("Настройки")
	Frame:SetDraggable(true)
	Frame.btnMaxim:SetVisible(false)
	Frame.btnMinim:SetVisible(false)
	Frame:MakePopup()
	Frame:Center()
	local DPanel = vgui.Create("DPanel",Frame)
	DPanel:SetPos(5,30)
	DPanel:SetSize(210,50)
	DLabel:SetDark(1)
	local preview = vgui.Create("DCheckBoxLabel",Frame)
	preview:SetPos(10,35)
	preview:SetText("Предпросмотр (Начать тест)")
	preview:SetConVar("metadmin_preview")
	preview:SizeToContents()
	local buttontext = vgui.Create('DLabel',Frame)
	buttontext:SetPos(10,60)
	buttontext:SetText("Кнопка, открывающая меню:")
	buttontext:SizeToContents()
	local button = vgui.Create( "DComboBox",Frame )
	button:SetPos(165,55)
	button:SetSize(40,20)
	button:SetValue(buttonmenu:GetString())
	for k,v in pairs(buttons) do
		button:AddChoice(k)
	end
	button.OnSelect = function(panel,index,value)
		RunConsoleCommand("metadmin_buttonmenu",value)
	end
end

local opentime = 0
hook.Add("Think","exammenu",function()
	if not Access("ma.pl") then return end
	if CurTime() < opentime then return end
    if input.IsKeyDown(buttons[buttonmenu:GetString()]) then
      metadmin.menu()
	  opentime = CurTime() + 2.5
	end
end)

local menu
function metadmin.playeract(nick,sid,rank,Frame)
	if IsValid(menu) then menu:Remove() end
	menu = DermaMenu()
	local header = menu:AddOption(nick)
	header:SetTextInset(10,0)
	header.PaintOver = function() surface.SetDrawColor(0,0,0,50) surface.DrawRect(0,0,header:GetWide(),header:GetTall()) end
	if Access("ma.violationgive") then
		local row = menu:AddOption("Добавить нарушение", function()
			local frame = vgui.Create("DFrame")
			frame:SetSize(585,140)
			frame:SetTitle("Добавление нарушения")
			frame:SetDraggable(true)
			frame:Center()
			frame:MakePopup()
			frame.btnMaxim:SetVisible(false)
			frame.btnMinim:SetVisible(false)
			local text = vgui.Create("DTextEntry",frame)
			text:SetPos(5,25)
			text:SetSize(575,85)
			text:SetMultiline(true)
			text:SetText("Нарушение")
			local send = vgui.Create("DButton",frame)
			send:SetPos(5,115)
			send:SetText("Отправить")
			send:SetSize(575,20)
			send.DoClick = function()
				net.Start("metadmin.violations")
					net.WriteInt(1,3)
					net.WriteString(sid)
					net.WriteString(text:GetValue())
				net.SendToServer()
				frame:Close()
			end
			Frame:Close()
		end)
		row:SetIcon("icon16/information.png")
	end
	if Access("ma.settalon") then
		row = menu:AddOption("Вернуть талон", function()
			net.Start("metadmin.action")
				net.WriteString(sid)
				net.WriteInt(7,5)
			net.SendToServer()
			Frame:Close()
		end)
		row:SetIcon("icon16/tag_blue_add.png")
		row = menu:AddOption("Забрать талон", function()
			net.Start("metadmin.action")
				net.WriteString(sid)
				net.WriteInt(8,5)
			net.SendToServer()
			Frame:Close()
		end)
		row:SetIcon("icon16/tag_blue_delete.png")
	end
	if Access("ma.promote") and metadmin.prom[rank] then
		row = menu:AddOption("Повысить", function()
			local frame2 = vgui.Create("DFrame")
			frame2:SetSize(400, 60)
			frame2:SetTitle("Примечание")
			frame2:Center()
			frame2.btnMaxim:SetVisible(false)
			frame2.btnMinim:SetVisible(false)
			local text = vgui.Create("DTextEntry",frame2)
			text:StretchToParent(5,29,5,5)
			text.OnEnter = function()
				net.Start("metadmin.action")
					net.WriteString(sid)
					net.WriteInt(1,5)
					net.WriteString(text:GetValue())
				net.SendToServer()
				frame2:Remove()
			end
			text:RequestFocus()
			frame2:MakePopup()
			Frame:Close()
		end)
		row:SetIcon("icon16/arrow_up.png")
	end
	if Access("ma.demote") and metadmin.dem[rank] then
		row = menu:AddOption("Понизить", function()
			local frame2 = vgui.Create("DFrame")
			frame2:SetSize(400,60)
			frame2:SetTitle("Примечание")
			frame2:Center()
			frame2.btnMaxim:SetVisible(false)
			frame2.btnMinim:SetVisible(false)
			local text = vgui.Create("DTextEntry",frame2)
			text:StretchToParent(5,29,5,5)
			text.OnEnter = function()
				net.Start("metadmin.action")
					net.WriteString(sid)
					net.WriteInt(2,5)
					net.WriteString(text:GetValue())
				net.SendToServer()
				frame2:Remove()
			end
			text:RequestFocus()
			frame2:MakePopup()
			Frame:Close()
		end)
		row:SetIcon("icon16/arrow_down.png")
	end
	local target = player.GetBySteamID(sid)
	if target then
		if Access("ma.starttest") then
			local sub, row = menu:AddSubMenu("Начать тест")
			for k,v in pairs(metadmin.questions) do
				if v.enabled == 1 then
					local row = sub:AddOption(v.name, function()
						if GetConVarNumber( "metadmin_preview" ) == 1 then
							metadmin.questions2(k,"view",{nick = nick,sid = sid})
						else
							net.Start("metadmin.action")
								net.WriteString(sid)
								net.WriteInt(3,5)
								net.WriteString(k)
							net.SendToServer()
						end
						Frame:Close()
					end)
					row:SetTextInset(10,0)
				end
			end
			row:SetIcon("icon16/help.png")
		end
	end
	local row = menu:AddOption("Отмена")
	row:SetIcon("icon16/cancel.png")
	menu.Remove = function(m)
		DMenu.Remove(m)
	end
	menu:Open()
end

surface.CreateFont("ma.font1", {
	font = "Trebuchet",
	size = 17,
	weight = 800,
	blursize = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false
})
	
surface.CreateFont("ma.font2", {
	font = "Trebuchet",
	size = 30,
	weight = 800,
	blursize = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false
})

surface.CreateFont("ma.font3", {
	font = "Trebuchet",
	size = 24,
	weight = 800,
	blursize = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false
})

surface.CreateFont("ma.font4", {
	font = "Trebuchet",
	size = 20,
	weight = 800,
	blursize = 0,
	antialias = true,
	underline = false,
	italic = true,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false
})

surface.CreateFont("ma.font5", {
	font = "Trebuchet",
	size = 20,
	weight = 800,
	blursize = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false
})
	
local badplok = {}
function metadmin.profile(tab)
	if tab.badpl and not badplok[tab.SID] then
		local frame = Derma_Message("Этот игрок был отмечен 'плохим' в системе.\nПричина: "..tab.badpl,"Предупреждение","Ок")
		local hided = vgui.Create("DCheckBoxLabel",frame)
		hided:SetSize(100,20)
		hided:SetPos(165,5)
		hided:SetText("Не показывать")
		hided:SetValue(badplok[tab.SID] or 0)
		function hided:OnChange(val)
			badplok[tab.SID] = val
		end
	end
	local creatabs = (tab.violations or tab.exam or tab.exam_answers or tab.status)
	local Frame = vgui.Create("DFrame")
	Frame:SetSize(600,creatabs and 500 or 115)
	Frame:SetTitle("Профиль "..tab.Nick.." ("..tab.SID..")")
	Frame.btnMaxim:SetVisible(false)
	Frame.btnMinim:SetVisible(false)
	Frame:SetDraggable(true)
	Frame:Center()
	Frame:MakePopup()
	local DPanel = vgui.Create("DPanel",Frame)
	DPanel:SetPos(5,30)
	DPanel:SetSize(590,80)
	DLabel:SetDark(1)
	if Access("ma.pl") then
		local DButton = vgui.Create("DButton",Frame)
		DButton:SetPos(504,3)
		DButton:SetText("Действия")
		DButton:SetSize(60,18)
		DButton.DoClick = function()
			metadmin.playeract(tab.Nick,tab.SID,tab.rank,Frame)
		end
	end
	local nick = vgui.Create("DLabel",DPanel)
	nick:SetSize(574,15)
	nick:SetPos(75,5)
	nick:SetText("Ник: "..tab.Nick)
	local steamid = vgui.Create("DLabel",DPanel)
	steamid:SetSize(574,15)
	steamid:SetPos(75,20)
	steamid:SetText("STEAMID: "..tab.SID)
	local rank = vgui.Create("DLabel",DPanel)
	rank:SetSize(574,15)
	rank:SetPos(75,35)
	rank:SetText("Ранг: "..metadmin.ranks[tab.rank])
	local nvoiol = vgui.Create("DLabel",DPanel)
	nvoiol:SetSize(574,15)
	nvoiol:SetPos(75,50)
	nvoiol:SetText("Нарушений: "..tab.nvio)
	local Avatar = vgui.Create("AvatarImage",DPanel)
	Avatar:SetSize(64,64)
	Avatar:SetPos(5,7)
	Avatar:SetSteamID(util.SteamIDTo64(tab.SID),64)
	function Avatar:OnCursorEntered()
		self:SetCursor("hand")
	end
	function Avatar:OnCursorExited()
		self:SetCursor("arrow")
	end
	function Avatar:OnMouseReleased(code)
		if (code == MOUSE_LEFT) then
			gui.OpenURL("http://steamcommunity.com/profiles/"..util.SteamIDTo64(tab.SID))
		end
	end
	if metadmin.pogona[tab.rank] then
		local pogona = vgui.Create("DImage",DPanel)
		pogona:SetImage(metadmin.pogona[tab.rank])
		pogona:SetSize(140,78)
		pogona:SetPos(450,1)
	end
	
	if not creatabs then return end
	local tabs = vgui.Create("DPropertySheet",Frame)
	tabs:SetPos(0,110)
	tabs:SetSize(600,390)
	if tab.violations then
		local violations = vgui.Create("DPanel",tabs)
		violations:SetBackgroundColor(Color(128,128,128))
		violations.PaintOver = function(self,w,h)
			if tab.nvio == 0 then
				draw.SimpleText("Этот игрок еще ничего не нарушил.", "ma.font3", w/2, 20, Color(50,50,50), TEXT_ALIGN_CENTER)
				draw.SimpleText("Пока...", "ma.font1", w/2, 60, Color(50,50,50), TEXT_ALIGN_CENTER)
			end
		end
		local DScrollPanel = vgui.Create("DScrollPanel",violations)
		DScrollPanel:SetSize(600,355)
		DScrollPanel:SetPos(0,0)
		local num = 0
		for k,v in pairs(tab.violations) do
			local DPanel = vgui.Create("DPanel",DScrollPanel)
			DPanel:SetPos( 0,120*num)
			DPanel:SetSize(584,115)
			DLabel:SetDark(1)
			if Access("ma.violationremove") then
				local menu
				function DPanel:OnMouseReleased()
					if IsValid(menu) then menu:Remove() end
					menu = DermaMenu()
					local header = menu:AddOption("№"..k)
					header:SetTextInset(10,0)
					header.PaintOver = function() surface.SetDrawColor(0,0,0,50) surface.DrawRect(0,0,header:GetWide(),header:GetTall()) end
					local row = menu:AddOption("Удалить", function()
						net.Start("metadmin.violations")
							net.WriteInt(2,3)
							net.WriteString(tab.SID)
							net.WriteString(v.id)
						net.SendToServer()
						Frame:Close()
					end)
					row:SetIcon("icon16/table_delete.png")
					local row = menu:AddOption("Отмена")
					row:SetIcon("icon16/cancel.png")
					menu:Open()
				end
			end
			local info = vgui.Create("DLabel",DPanel)
			info:SetSize(574,15)
			info:SetPos(5,5)
			info:SetText("№"..k.." | Дата: "..os.date( "%X - %d/%m/%Y" ,v.date).." | Выдал: "..v.admin.." | Сервер: "..v.server)
			local reason = vgui.Create("DTextEntry",DPanel)
			reason:SetPos(5,25)
			reason:SetSize(574,85)
			reason:SetText(v.violation)
			reason:SetMultiline(true)
			reason:SetEditable(false)
			num = num + 1
		end
		tabs:AddSheet("Нарушения",violations,"icon16/exclamation.png")
	end
	if tab.exam then
		local examinfo = vgui.Create("DPanel",tabs)
		examinfo:SetBackgroundColor(Color(128,128,128))
		examinfo.PaintOver = function(self,w,h)
			if #tab.exam == 0 then
				draw.SimpleText("Этот игрок пока не сдал ни одного экзамена.", "ma.font3", w/2, 20, Color(50,50,50), TEXT_ALIGN_CENTER)
			end
		end
		local DScrollPanel = vgui.Create("DScrollPanel",examinfo)
		DScrollPanel:SetSize(600,355)
		DScrollPanel:SetPos(0,0)
		local num = 0
		for k,v in pairs(tab.exam) do
			local DPanel = vgui.Create("DPanel",DScrollPanel)
			DPanel:SetPos(0,120*num)
			DPanel:SetSize(584,115)
			DLabel:SetDark(1)
			DPanel:SetBackgroundColor(v.type == 1 and Color(46,139,87) or v.type == 2 and Color(250,128,114) or Color(255,255,150))
			local info = vgui.Create("DLabel",DPanel)
			info:SetSize(574,15)
			info:SetPos(5,5)
			info:SetText(metadmin.ranks[v.rank].." | Дата: "..os.date( "%X - %d/%m/%Y" ,v.date).." | Экзаменатор: "..v.examiner.." | Сервер: "..v.server)
			local note = vgui.Create("DTextEntry",DPanel)
			note:SetPos(5,25)
			note:SetSize(574,85)
			note:SetText(v.note)
			note:SetMultiline(true)
			note:SetEditable(false)
			num = num + 1
		end
		tabs:AddSheet("Результаты экзаменов",examinfo,"icon16/layout_edit.png" )
	end
	if tab.exam_answers then
		local answers = vgui.Create("DPanel",tabs)
		answers:SetBackgroundColor(Color(128,128,128))
		answers.PaintOver = function(self,w,h)
			if #tab.exam_answers == 0 then
				draw.SimpleText("Этот игрок пока не сдал ни одного теста.", "ma.font3", w/2, 20, Color(50,50,50), TEXT_ALIGN_CENTER)
			end
		end
		local DScrollPanel = vgui.Create("DScrollPanel",answers)
		DScrollPanel:SetSize(600,355)
		DScrollPanel:SetPos(0,0)
		local num = 0
		for k,v in pairs(tab.exam_answers) do
			local DPanel = vgui.Create("DPanel",DScrollPanel)
			DPanel:SetPos(0,30*num)
			DPanel:SetSize(584,25)
			DLabel:SetDark(1)
			local menu
			function DPanel:OnMouseReleased()
				if IsValid(menu) then menu:Remove() end
				menu = DermaMenu()
				if metadmin.questions[tonumber(v.questions)] then
					local row = menu:AddOption("Просмотреть", function()
						net.Start("metadmin.action")
							net.WriteString(tab.SID)
							net.WriteInt(4,5)
							net.WriteString(v.id)
						net.SendToServer()
						Frame:Close()
					end)
					row:SetIcon("icon16/information.png")
				end
				if Access("ma.setstattest") then
					local sub, row = menu:AddSubMenu("Статус")
					row:SetIcon(v.status == 1 and "icon16/tick.png" or v.status == 2 and "icon16/cross.png" or "icon16/help.png")
					local row = sub:AddOption("Сдал", function()
						net.Start("metadmin.action")
							net.WriteString(tab.SID)
							net.WriteInt(5,5)
							net.WriteString(v.id)
							net.WriteInt(1,4)
						net.SendToServer()
						Frame:Close()
					end)
					row:SetIcon("icon16/tick.png")
					local row = sub:AddOption("Не сдал", function()
						net.Start("metadmin.action")
							net.WriteString(tab.SID)
							net.WriteInt(5,5)
							net.WriteString(v.id)
							net.WriteInt(2,4)
						net.SendToServer()
						Frame:Close()
					end)
					row:SetIcon("icon16/cross.png")
					local row = sub:AddOption("На проверке", function()
						net.Start("metadmin.action")
							net.WriteString(tab.SID)
							net.WriteInt(5,5)
							net.WriteString(v.id)
							net.WriteInt(0,4)
						net.SendToServer()
						Frame:Close()
					end)
					row:SetIcon("icon16/help.png")
				end
				local row = menu:AddOption("Отмена")
				row:SetIcon("icon16/cancel.png")
				menu:Open()
			end
			local img = vgui.Create( "DImage", DPanel )
			img:SetPos(5,5)
			img:SetSize(16,16)
			img:SetImage(v.status == 1 and "icon16/tick.png" or v.status == 2 and "icon16/cross.png" or "icon16/help.png")
			img:SetToolTip(v.status == 1 and "Сдал" or v.status == 2 and "Не сдал" or "На проверке")
			img:SetMouseInputEnabled(true)
			local info = vgui.Create("DLabel",DPanel)
			info:SetSize(574,15)
			info:SetPos(25,5)
			info:SetText("| "..(metadmin.questions[tonumber(v.questions)] and metadmin.questions[tonumber(v.questions)].name) or "Шаблон удален".." | Дата: "..os.date( "%X - %d/%m/%Y" ,v.date))
			num = num + 1
		end
		tabs:AddSheet("Результаты тестов", answers,"icon16/page_edit.png")
	end
	if tab.status then
		local talon = vgui.Create("DPanel",tabs)
		talon:SetBackgroundColor(Color(255,228,181))
		talon.PaintOver = function(self,w,h)
			surface.SetDrawColor(tab.status.nom == 1 and Color(3,111,35) or tab.status.nom == 2 and Color(255,255,0) or Color(178,34,34))
			draw.NoTexture()
			surface.DrawPoly({{ x = 0, y = 0 },{ x = 40, y = 0 },{ x = w, y = h },{ x = w-40, y = h }})
			draw.SimpleText(GetHostName(), "ma.font1", w/2, 20, Color(50,50,50), TEXT_ALIGN_CENTER)
			draw.SimpleText("ТАЛОН ПРЕДУПРЕЖДЕНИЯ №"..tab.status.nom, "ma.font2", w/2, 55, Color(50,50,50), TEXT_ALIGN_CENTER)
			draw.SimpleText("Машиниста, помощника машиниста", "ma.font3", w/2, 90, Color(50,50,50), TEXT_ALIGN_CENTER)
			draw.SimpleText(tab.Nick, "ma.font4", w/2, 120, Color(50,50,50), TEXT_ALIGN_CENTER)
			draw.SimpleText(tab.SID, "ma.font4", w/2, 140, Color(50,50,50), TEXT_ALIGN_CENTER)
			draw.SimpleText("Выдан: "..os.date( "%X - %d/%m/%Y" ,tab.status.date), "ma.font5", w/2, 180, Color(50,50,50), TEXT_ALIGN_CENTER)
			draw.SimpleText(tab.status.admin, "ma.font5", w/2, 200, Color(50,50,50), TEXT_ALIGN_CENTER)
		end
		tabs:AddSheet("Талон",talon,"icon16/vcard.png")
	end
end

function metadmin.questionslist()
	local Frame = vgui.Create("DFrame")
	Frame:SetSize(200,260)
	Frame:SetTitle("Список шаблонов")
	Frame:SetDraggable(true)
	Frame.btnMaxim:SetVisible(false)
	Frame.btnMinim:SetVisible(false)
	Frame:MakePopup()
	Frame:Center()
	if Access("ma.questionscreate") then
		local add = vgui.Create("DButton",Frame)
		add:SetPos(103,2.5)
		add:SetText("Добавить")
		add:SetSize(60,20)
		add.DoClick = function() metadmin.questionsadd() Frame:Close() end
	end
	local questionlist = vgui.Create("DListView",Frame)
	questionlist:SetPos(10,30)
	questionlist:SetSize(180,220)
	questionlist:SetMultiSelect(false)
	local menu
	questionlist.OnClickLine = function( panel, line )
		if IsValid(menu) then menu:Remove() end
		line:SetSelected(true)
		menu = DermaMenu()
		local header = menu:AddOption(line:GetValue(1))
		header:SetTextInset(10,0)
		header.PaintOver = function() surface.SetDrawColor(0,0,0,50) surface.DrawRect(0,0,header:GetWide(),header:GetTall()) end
		
		local row = menu:AddOption("Посмотреть вопросы", function()
			metadmin.questions2(line.id)
			Frame:Close()
		end)
		row:SetIcon("icon16/table.png")
		if Access("ma.questionsedit") then
			local row = menu:AddOption("Редактировать", function()
				metadmin.questions2(line.id,"edit")
				Frame:Close()
			end)
			row:SetIcon("icon16/table_edit.png")
		end
		if Access("ma.questionsimn") then
			local row = menu:AddOption(line:GetValue(2)==0 and"Включить"or"Отключить", function()
				net.Start("metadmin.qaction")
					net.WriteInt(1,5)
					net.WriteInt(line.id,32)
				net.SendToServer()
				Frame:Close()
			end)
			row:SetIcon(line:GetValue(2)==0 and "icon16/table_row_insert.png"or"icon16/table_row_delete.png")
		end
		if Access("ma.questionsremove") then
			local name = line:GetValue(1)
			local row = menu:AddOption("Удалить", function()
				local id = line.id
				Derma_Query('Ты точно хочешь удалить ' .. name .. '?', 'Удаление шаблона',
					'Да', function()
							net.Start("metadmin.qaction")
								net.WriteInt(2,5)
								net.WriteInt(id,32)
							net.SendToServer()
					end,
					'Нет', function() questionslist() end
				)
				Frame:Close()
			end)
			row:SetIcon("icon16/table_delete.png")
		end

		local row = menu:AddOption("Отмена")
		row:SetIcon("icon16/cancel.png")
		
		menu.Remove = function(m)
			if IsValid(line) then
				line:SetSelected(false)
			end
		end
		menu:Open()
	end
	questionlist:AddColumn("Название"):SetFixedWidth(130)
	questionlist:AddColumn("Вкл."):SetFixedWidth(50)
	for k,v in pairs(metadmin.questions) do
		local line = questionlist:AddLine(v.name,v.enabled)
		line.id = k
	end
end

function metadmin.questionsadd()
	local frame2 = vgui.Create("DFrame")
	frame2:SetSize(400,60)
	frame2:SetTitle("Название шаблона")
	frame2:Center()
	frame2.btnMaxim:SetVisible(false)
	frame2.btnMinim:SetVisible(false)
	local text = vgui.Create("DTextEntry",frame2)
	text:StretchToParent(5,29,5,5)
	text.OnEnter = function()
		local value = text:GetValue()
		net.Start("metadmin.qaction")
			net.WriteInt(4,5)
			net.WriteInt(0,32)
			net.WriteString(value)
		net.SendToServer()
		timer.Simple(1,function()
			metadmin.questionslist()
		end)
		frame2:Remove()
	end
	text:RequestFocus()
	frame2:MakePopup()
end

function metadmin.question(tab)
	local answer = {}
	local id = tab.id
	local maxn = #tab.questions
	local Frame = vgui.Create("DFrame")
	Frame:SetSize(800,math.min(600,80+40*maxn))
	Frame:SetTitle("Вопросы ("..maxn..")")
	Frame:ShowCloseButton(false)
	Frame:SetDraggable(true)
	Frame:Center()
	Frame:MakePopup()
	local DScrollPanel = vgui.Create("DScrollPanel",Frame)
	DScrollPanel:SetSize(790,math.min(540,60+40*maxn))
	DScrollPanel:SetPos(1,25)
	local DPanel = vgui.Create("DPanel",DScrollPanel)
	DPanel:SetPos(5,5)
	DPanel:SetSize(790, 20+40*maxn)
	DLabel:SetDark(1)
	local num = 0
	for k, v in pairs(tab.questions) do
		local question = vgui.Create("DLabel",DPanel)
		question:SetSize(760,20)
		question:SetPos(5,5+num*40)
		question:SetText(v..":")
		answer[k] = vgui.Create("DTextEntry",DPanel)
		answer[k]:SetPos(5,25+num*40)
		answer[k]:SetSize(760,20)
		num = num+1
	end
	local send = vgui.Create("DButton",Frame)
	send:SetPos(5,math.min(575,55+40*maxn))
	send:SetText("Отправить")
	send:SetSize(790,20)
	send.DoClick = function()
		local answers = {}
		for k, v in pairs(answer) do
			answers[k] = answer[k]:GetValue()
		end
		net.Start( "metadmin.answers" )
			net.WriteTable({ans = answers, id = id})
		net.SendToServer()
		Frame:Close()
	end
end

function metadmin.viewanswers(tab)
	if not tab then return end
	local maxn = #tab.questions
	local Frame = vgui.Create("DFrame")
	Frame:SetSize(800,math.min(600,80+40*maxn))
	Frame:SetTitle("Ответы игрока "..tab.nick.."("..tab.sid..")")
	Frame.btnMaxim:SetVisible(false)
	Frame.btnMinim:SetVisible(false)
	Frame:SetDraggable(true)
	Frame:Center()
	Frame:MakePopup()
	local DScrollPanel = vgui.Create("DScrollPanel",Frame)
	DScrollPanel:SetSize(790,math.min(540,60+40*maxn))
	DScrollPanel:SetPos(1,25)
	local DPanel = vgui.Create("DPanel",DScrollPanel)
	DPanel:SetPos(5,5)
	DPanel:SetPos(5,5)
	DPanel:SetSize(790,20+40*maxn)
	DLabel:SetDark(1)
	local num = 0
	for k=1,maxn do
		local question = vgui.Create("DLabel",DPanel)
		question:SetSize(760,20)
		question:SetPos(5,5+num*40)
		question:SetText(tab.questions[k]..":")
		local answer = vgui.Create("DTextEntry",DPanel)
		answer:SetPos(5,25+num*40)
		answer:SetSize(760,20)
		answer:SetText(tab.answers[k])
		answer:SetEditable(false)
		num = num+1
	end
	local send = vgui.Create("DButton",Frame)
	send:SetPos(5,math.min(575,55+40*maxn))
	send:SetText("Обратно в меню")
	send:SetSize(790,20)
	send.DoClick = function()
		Frame:Close()
		metadmin.menu()
	end
end

function metadmin.questions2(id,type,ply)
	local tab = metadmin.questions[id].questions
	if not tab then return end
	local maxn = #tab
	local questions2 = {}
	local Frame = vgui.Create("DFrame")
	Frame:SetSize(800,math.min(600,80+20*maxn))
	Frame:SetTitle(type == "edit"and"Редактирование шаблона вопросов "or"Шаблон вопросов "..metadmin.questions[id].name)
	Frame.btnMaxim:SetVisible(false)
	Frame.btnMinim:SetVisible(false)
	Frame:SetDraggable(true)
	Frame:Center()
	Frame:MakePopup()
	local DScrollPanel = vgui.Create("DScrollPanel",Frame)
	DScrollPanel:SetSize(790,math.min(540,60+20*maxn))
	DScrollPanel:SetPos(1,25)
	local DPanel = vgui.Create("DPanel",DScrollPanel)
	DPanel:SetPos(5,5)
	DPanel:SetSize(790,20+20*maxn)
	DLabel:SetDark(1)
	local num = 0
	for k, v in pairs(tab) do
		if type == "edit" then
			questions2[k] = vgui.Create("DTextEntry",DPanel)
			questions2[k]:SetSize(760,20)
			questions2[k]:SetPos(5,5+num*20)
			questions2[k]:SetText(v)
		else
			local question = vgui.Create("DLabel",DPanel)
			question:SetSize(760,20)
			question:SetPos(5,5+num*20)
			question:SetText(k.."."..v)
		end
		num = num+1
	end
	local send = vgui.Create("DButton",Frame)
	send:SetPos(5,math.min(575,55+20*maxn))
	send:SetText( type == "edit" and "Сохранить" or ply and "Отправить игроку "..ply.nick or "Обратно в меню" )
	send:SetSize(790,20)
	if type == "edit" then
		local add = vgui.Create("DButton",Frame)
		add:SetPos(600,2.5)
		add:SetText("Добавить")
		add:SetSize(80, 20)
		add.DoClick = function()
			local k = #questions2 + 1
			Frame:SetSize( 800, math.min(600,80+20*k) )
			DScrollPanel:SetSize( 790, math.min(540,60+20*k) )
			DPanel:SetSize( 790, 20+20*k )
			send:SetPos( 5, math.min(575,55+20*k))
			questions2[k] = vgui.Create( "DTextEntry", DPanel )
			questions2[k]:SetSize( 760, 20 )
			questions2[k]:SetPos( 5, 5 + (k-1)*20 )
			questions2[k]:SetText("Новое поле")
		end
		local rem = vgui.Create("DButton",Frame)
		rem:SetPos(680,2.5)
		rem:SetText("Удалить")
		rem:SetSize(80,20)
		rem.DoClick = function()
			local k = #questions2 -1
			Frame:SetSize( 800, math.min(600,80+20*k) )
			DScrollPanel:SetSize( 790, math.min(540,60+20*k) )
			DPanel:SetSize( 790, 20+20*k )
			send:SetPos( 5, math.min(575,55+20*k))
			questions2[k+1]:Remove()
			questions2[k+1] = nil
		end
	end
	send.DoClick = function()
		if type == "edit" then
			local tab2 = {}
			for k, v in pairs(questions2) do
				tab2[k] = v:GetValue()
			end
			net.Start("metadmin.qaction")
				net.WriteInt(3,5)
				net.WriteInt(id,32)
				net.WriteTable(tab2)
			net.SendToServer()
			Frame:Close()
			metadmin.questionslist()
		else
			if ply then
				net.Start("metadmin.action")
					net.WriteString(ply.sid)
					net.WriteInt(3,5)
					net.WriteString(id)
				net.SendToServer()
			else
				metadmin.questionslist()
			end
			Frame:Close()
		end
	end
end