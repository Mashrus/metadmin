metadmin = metadmin or {}
metadmin.server = "SERVER"
metadmin.category = "MetrostroiAdmin"
metadmin.provider = "sql" -- mysql,sql
metadmin.ranks = {
	["driver3class"] = "Машинист 3 класса",
	["driver2class"] = "Машинист 2 класса",
	["driver1class"] = "Машинист 1 класса",
	["user"] = "Помощник машиниста",
	["auditor"] = "Ревизор",
	["admin"] = "Поездной диспетчер",
	["chiefinstructor"] = "Главный инструктор",
	["instructor"] = "Машинист инструктор",
	["superadmin"] = "Начальник метрополитена"
}
metadmin.prom = {
	["user"] = "driver3class",
	["driver3class"] = "driver2class",
	["driver2class"] = "driver1class"
}
metadmin.dem = {
	["driver3class"] = "user",
	["driver2class"] = "driver3class",
	["driver1class"] = "driver2class"
}
metadmin.plombs = {
	["KAH"] = "КАХ",
	["VAH"] = "ВАХ",
	["RC1"] = "РЦ-1",
	["UOS"] = "РЦ-УОС",
	["OtklAVU"] = "ОтклАВУ",
	["A5"] = "A5"
}
metadmin.pogona = {}