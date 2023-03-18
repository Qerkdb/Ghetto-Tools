script_name("Ghetto Helper by Squzi")
script_version("0.1")
script_author('Squzi')

--==--libs--==--
require 'moonloader'
local imgui = require 'imgui'
local imadd = require 'imgui_addons'
imgui.ToggleButton = require('imgui_addons').ToggleButton
local imadd = require("imgui_addons")
local inicfg = require "inicfg"
local sampev = require 'lib.samp.events'
local rkeys = require 'rkeys'
local dlstatus = require('moonloader').download_status
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8
local fa = require 'faIcons'
local fonts = renderCreateFont("Arial", 9, 5)

local cfg = inicfg.load({
   config = {
      SbivBind = false,
      DrugTimer = false,
      Bell = false,
      mainwin = true,
      Kill = false,
      CmdMb = false,
      Invite = false,
      InvRank = 1,
      UnInvite = false,
      UvalText = u8'Выселен.',
      SpawnCar = false,
      NaborBang = 0,
      Nabor = false,
      Stats = false,
      CPX = 13,
      CPY = 992,
      HPHud = false,
      Sklad = false,
      CmdMb = true,
      CmdM4 = true,
      OverLay = false,
      CheckOnline = false,
      OPX = 13,
      OPY = 992,
      fb_pal1 = 255,
      fb_pal2 = 255,
      fb_pal3 = 255,
      colorfb = 0xFFFFFF,
      ColorFb = false,
      AutoUpdate = 1,
      WPX = 500,
      WPC = 500,
      DPX = 500,
      DPY = 500,
      CommandAct = 'gh',
      SizeFont = 9,
      FlagFont = 5,
      DrugKolvo = 3,
      DrugTimerTime = 7,
      SbivKey = 0x5A,
      TextSbiv = ' ',
      formuval = false,
	  lpan = false,
   }
}, "Ghetto Helper/Ghetto Helper.ini")
local font = renderCreateFont("Arial", cfg.config.SizeFont, cfg.config.FlagFont)

--==--Fastgun--==--
local page = { 
	[1] = 2107,
	[2] = 2108,
	[3] = 2109,
	["cur"] = 1
}

local Weapon = {
	["de"]  	= { model = 348, x = 0, y = 32, z = 189, name = "Desert Eagle" },
	["fgs"] 	= { model = 349, x = 0, y = 23, z = 140, name = "ShotGun" },
	["fgu"] 	= { model = 352, x = 0, y = 360, z = 188, name = "Micro Uzi" },
	["fgmp"] 	= { model = 353, x = 0, y = 17, z = 181, name = "MP5" },
	["fgak"] 	= { model = 355, x = 0, y = 27, z = 134, name = "AK-47" },
	["m4"]  	= { model = 356, x = 0, y = 27, z = 134, name = "M4" },
	["fgr"] 	= { model = 357, x = 0, y = 13, z = 120, name = "Rifle" }
}

for name, _ in pairs(Weapon) do
	setmetatable(Weapon[name], {
		__call = function(self, count)
			return {
				step = 0,
				model = self.model,
				rot = { x = self.x, y = self.y, z = self.z },
				count = count,
				clock = os.clock()
			}
		end
	})
end
--==--Imgui--==--
local window = imgui.ImBool(false)
local window_v = imgui.ImBool(false)
local checksbiv = imgui.ImBool(cfg.config.SbivBind)
local checkdtimer = imgui.ImBool(cfg.config.DrugTimer)
local checkbell = imgui.ImBool(cfg.config.Bell)
local checkkill = imgui.ImBool(cfg.config.Kill)
local nepocaz = imgui.ImBool(cfg.config.mainwin)
local ComboNabor = imgui.ImInt(cfg.config.NaborBang)
local checkinvite = imgui.ImBool(cfg.config.Invite)
local invrank = imgui.ImInt(cfg.config.InvRank)
local checkuninvite = imgui.ImBool(cfg.config.UnInvite)
local uvaltext = imgui.ImBuffer(cfg.config.UvalText,256)
local checkspawncar = imgui.ImBool(cfg.config.SpawnCar)
local checknabor = imgui.ImBool(cfg.config.Nabor)
local checkstats = imgui.ImBool(cfg.config.Stats)
local checkhphud = imgui.ImBool(cfg.config.HPHud)
local checksklad = imgui.ImBool(cfg.config.Sklad)
local checkonline = imgui.ImBool(cfg.config.CheckOnline)
local radioautoupdate = imgui.ImInt(cfg.config.AutoUpdate)
local commandact = imgui.ImBuffer(cfg.config.CommandAct,256)
local sizefont = imgui.ImInt(cfg.config.SizeFont)
local flagfont = imgui.ImInt(cfg.config.FlagFont)
local cmdmb = imgui.ImBool(cfg.config.CmdMb)
local OverLay = imgui.ImBool(cfg.config.OverLay)
local cmdm4 = imgui.ImBool(cfg.config.CmdM4)
local formuval = imgui.ImBool(cfg.config.formuval)
local textsbiv = imgui.ImBuffer(cfg.config.TextSbiv,256)
local checklpan = imgui.ImBool(cfg.config.lpan)

--==--Local--==--
local Timer = {state = false, start = 0}
local TimerTime = 7
local menu = 1
local menun = 'Главная'
local killss = 0
local pagesize = 15
local changestatspos = false
local firstspawn = false
local current = 0
local total = 0
local kills = 0
local deaths = 0
local ratio = 0
local fa_font = nil
local fontsize = nil
local menuk = {
	fa.ICON_INFO..u8' Информация',
	fa.ICON_BARS..u8' Функции',
	fa.ICON_ID_CARD..u8' Для 9+ рангов',
	fa.ICON_TERMINAL..u8' Команды',
	fa.ICON_COGS..u8' Настройки',
}
local dead_players = {}
local tLastKeys = {}
HotkeySbiv = {
    v = {0x5A}
}

local fa_glyph_ranges = imgui.ImGlyphRanges({ fa.min_range, fa.max_range })
function imgui.BeforeDrawFrame()
    if fa_font == nil then
        local font_config = imgui.ImFontConfig()
        font_config.MergeMode = true
        fa_font = imgui.GetIO().Fonts:AddFontFromFileTTF('moonloader/resource/fonts/fontawesome-webfont.ttf', 14.0, font_config, fa_glyph_ranges)
    end
end

function neakBtn(...)
    local result = false
    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.03, 0.03, 0.03, 0.03))
    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.03, 0.03, 0.03, 0.03))
    imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.03, 0.03, 0.03, 0.03))
    if imgui.Button(...) then
        result = true
    end
    imgui.PopStyleColor(3)
    return result
end

function imgui.OnDrawFrame()
    --if window.v then
        imgui.SetNextWindowPos(imgui.ImVec2(350,305), imgui.Cond.FirstUseEver)
        imgui.Begin('Ghetto Helper by Squzi', window, imgui.WindowFlags.NoTitleBar, imgui.WindowFlags.AlwaysAutoResize)
        imgui.BeginChild('##left', imgui.ImVec2(150, 305), true)
        for k, v in ipairs(menuk) do
            if menu ~= k then
                if neakBtn(v, imgui.ImVec2(-1, 55)) then
                    menu = k
                    menun = u8:decode(menuk[k])
                end
            else
                if imgui.Button(v, imgui.ImVec2(-1, 55)) then
                    menu = k
                    menun = u8:decode(menuk[k])
                end
            end
		end
        imgui.EndChild()
        imgui.SameLine()
        imgui.BeginChild('##right', imgui.ImVec2(500, 305), true)
        if menu == 1 then
            imgui.Text(u8'Скрипт создан для упрощения игры в гетто или на каптах')
            imgui.Text(u8'Автор этого скрипта VRush')
            --imgui.Link("https://www.blast.hk/threads/138165/",u8'Тема на Blast.hk')
            --imgui.Link("https://send.monobank.ua/jar/6t7Whh3esB",u8'Поддержать автора')
            imgui.TextColoredRGB('Спасибо за пользование {525497}Ghetto Helper{FFFFFF})')
            imgui.Text(u8'Текущая версия: '..thisScript().version..u8' Последняя версия для обновления '..updateversion)
            if updateversion ~= thisScript().version then 
                imgui.Text(u8'Требуется обновление!')
                imgui.SameLine()
                if imgui.Button(u8'Обновить до версии '..updateversion) then 
                    autoupdate("https://raw.githubusercontent.com/Qerkdb/Ghetto-Tools/main/autoupdate.json", '['..string.upper(thisScript().name)..']: ', "https://www.blast.hk/threads/138165/")
                end
            else 
                imgui.Text(u8'Обновление не требуется')
            end
        end
        if menu == 2 then
            if imgui.Checkbox('##Sbiv', checksbiv) then
                cfg.config.SbivBind = checksbiv.v
                inicfg.save(cfg,'Ghetto Helper/Ghetto Helper.ini')
            end
            imgui.SameLine()
            imgui.Text(u8'Сбив на Z ')
            imgui.SameLine()
            if imgui.Button(fa.ICON_COGS) then imgui.OpenPopup(u8'Сбив на Z') end
            if imgui.BeginPopup(u8'Сбив на Z') then
                imgui.Text(u8'При нажатии на нлавишу в чат будет отправляться сообщение, сбивая анимацию')
                imgui.Text(u8'Выбрать клавишу: ')
                imgui.SameLine()
                if imadd.HotKey("##1", HotkeySbiv, tLastKeys, 100) then
                    cfg.config.SbivKey = table.concat(HotkeySbiv.v)
                    inicfg.save(cfg,'Ghetto Helper/Ghetto Helper.ini')
                end
                imgui.PushItemWidth(90)
                imgui.Text(u8'Сообщение для сбива: ')
                imgui.SameLine()
                if imgui.InputText(u8'', textsbiv) then
                    cfg.config.TextSbiv = textsbiv.v
                    inicfg.save(cfg,'Ghetto Helper/Ghetto Helper.ini')
                end
                imgui.EndPopup()
            end

            if imgui.Checkbox('##DrugTimer', checkdtimer) then
                cfg.config.DrugTimer = checkdtimer.v
                inicfg.save(cfg,'Ghetto Helper/Ghetto Helper.ini')
            end
            imgui.SameLine()
            imgui.Text(u8'DrugTimer ')
            imgui.SameLine()
            if imgui.Button(fa.ICON_COGS..'##2') then imgui.OpenPopup(u8'DrugTimer') end
            if imgui.BeginPopup(u8'DrugTimer') then
                imgui.Text(u8'При нажатии на Х будет использоватся нарко и запускаться таймер на экране.')
                imgui.EndPopup()
            end

            if imgui.Checkbox('##bell', checkbell) then
                cfg.config.Bell = checkbell.v
                inicfg.save(cfg,'Ghetto Helper/Ghetto Helper.ini')
            end
            imgui.SameLine()
            imgui.Text(u8'Колокольчик ')
            imgui.SameLine()
            if imgui.Button(fa.ICON_COGS..'##3') then imgui.OpenPopup(u8'bell') end
            if imgui.BeginPopup(u8'bell') then
                imgui.Text(u8'При нанесении урона, будет проигрыватся звук.')
                imgui.EndPopup()
            end

            if imgui.Checkbox('##kill', checkkill) then
                cfg.config.Kill = checkkill.v
                inicfg.save(cfg,'Ghetto Helper/Ghetto Helper.ini')
            end
            imgui.SameLine()
            imgui.Text(u8'KillState')
            imgui.SameLine()
            if imgui.Button(fa.ICON_COGS..'##4') then imgui.OpenPopup(u8'kill') end
            if imgui.BeginPopup(u8'kill') then
                imgui.Text(u8'Надпись +kill при убийстве')
                imgui.EndPopup()
            end

            if imgui.Checkbox('##stats', checkstats) then
                cfg.config.Stats = checkstats.v
                inicfg.save(cfg,'Ghetto Helper/Ghetto Helper.ini')
            end
            imgui.SameLine()
            imgui.Text(u8'CaptStats')
            imgui.SameLine()
            if imgui.Button(fa.ICON_COGS..'##5') then imgui.OpenPopup(u8'CaptStats') end
            if imgui.BeginPopup(u8'CaptStats') then
                imgui.Text(u8'Ваша статистика капт в слева под радаром')
                if imgui.Button(u8'Изменить позицию##s') then
                    changestatspos = true
                    msg('Нажмите ЛКМ чтобы сохранить позицию.')
                    window.v = false
                end
                if imgui.Button(u8'Обнулить') then
                    total,deaths,kills = 0, 0, 0
                end
                imgui.Text(u8'Размер шрифта')
                imgui.SameLine()
                imgui.Ques('После смены размера перезагрузите скрипт')
                imgui.SameLine()
                if imgui.InputInt('##size', sizefont) then
                    local font = renderCreateFont("Arial", cfg.config.SizeFont, cfg.config.FlagFont)
                    cfg.config.SizeFont = sizefont.v
                    inicfg.save(cfg,'Ghetto Helper/Ghetto Helper.ini')
                end
                imgui.Text(u8'Флаг шрифта')
                imgui.SameLine()
                imgui.Ques('После смены флага перезагрузите скрипт')
                imgui.SameLine()
                if imgui.InputInt('##flag', flagfont) then
                    local font = renderCreateFont("Arial", cfg.config.SizeFont, cfg.config.FlagFont)
                    cfg.config.FlagFont = flagfont.v
                    inicfg.save(cfg,'Ghetto Helper/Ghetto Helper.ini')
                end
                imgui.EndPopup()
            end

            if imgui.Checkbox('##hphud', checkhphud) then
                cfg.config.HPHud = checkhphud.v
                inicfg.save(cfg,'Ghetto Helper/Ghetto Helper.ini')
            end
            imgui.SameLine()
            imgui.Text(u8'HPHud')
            imgui.SameLine()
            if imgui.Button(fa.ICON_COGS..'##7') then imgui.OpenPopup(u8'HpHud') end
            if imgui.BeginPopup(u8'HpHud') then
                imgui.Text(u8'Показывает кол-во ХП на хпбаре')
                imgui.EndPopup()
            end
			if imgui.Checkbox('##lpan', checklpan) then
                cfg.config.lpan = checklpan.v
                inicfg.save(cfg,'Ghetto Helper/Ghetto Helper.ini')
            end
			imgui.SameLine()
            imgui.Text(u8'Быстрое')
            imgui.SameLine()
            if imgui.Button(fa.ICON_COGS..'##8') then imgui.OpenPopup(u8'lpan') end
            if imgui.BeginPopup(u8'lpan') then
                imgui.Text(u8'Добавляет некоторые сокращенные функции:\n1) Закрывает и открывает авто на L\n2) Бег анимкой на R\n3) Открытие телефона на P')
                imgui.EndPopup()
            end
        end
        if menu == 3 then
            if imgui.Checkbox(u8'##inv', checkinvite) then
                cfg.config.Invite = checkinvite.v
                inicfg.save(cfg,'Ghetto Helper/Ghetto Helper.ini')
            end
            imgui.SameLine()
            imgui.PushItemWidth(82.5)
            imgui.Text(u8'Быстрый инвайт')
            imgui.SameLine()
            if imgui.Button(fa.ICON_COGS) then imgui.OpenPopup(u8'inv') end
            if imgui.BeginPopup(u8'inv') then
                imgui.Text(u8'Автоматически будет отправлять инвайт с РП отыгровкой. Активация: ПКМ + 1')
                if imgui.InputInt(u8'Ранг при инвайте', invrank) then
                    cfg.config.InvRank = invrank.v
                    inicfg.save(cfg,'Ghetto Helper/Ghetto Helper.ini')
                end
                if invrank.v <= 0 or invrank.v >= 9 then
                    invrank.v = 1
                end
                imgui.EndPopup()
            end
            if imgui.Checkbox(u8'##uval', checkuninvite) then
                cfg.config.UnInvite = checkuninvite.v
                inicfg.save(cfg,'Ghetto Helper/Ghetto Helper.ini')
            end
            imgui.SameLine()
            imgui.PushItemWidth(120)
            imgui.Text(u8'Быстрое увольнение')
            imgui.SameLine()
            if imgui.Button(fa.ICON_COGS..'##7') then imgui.OpenPopup(u8'uval') end
            if imgui.BeginPopup(u8'uval') then
                imgui.Text(u8'Быстрое увольнение члена банды. Активация: /fu [ID]')
                if imgui.InputText(u8'Причина увольнения', uvaltext) then
                    cfg.config.UnInviteText = uvaltext.v
                    inicfg.save(cfg,'Ghetto Helper/Ghetto Helper.ini')
                end
                imgui.EndPopup()
            end
            if imgui.Checkbox(u8'##formuval', formuval) then
                cfg.config.formuval = formuval.v
                inicfg.save(cfg,'Ghetto Helper/Ghetto Helper.ini')
            end
            imgui.SameLine()
            imgui.Text(u8'Форма на увольнение')
            imgui.SameLine()
            if imgui.Button(fa.ICON_COGS..'##10') then imgui.OpenPopup(u8'forluval') end
            if imgui.BeginPopup(u8'forluval') then
                imgui.Text(u8'При сообщениях по типу "псж" "увал" будет выводится форма для увольнения.')
                if imgui.InputText(u8'Причина увольнения#11', uvaltext) then
                    cfg.config.UnInviteText = uvaltext.v
                    inicfg.save(cfg,'Ghetto Helper/Ghetto Helper.ini')
                end
                imgui.EndPopup()
            end

            if imgui.Checkbox(u8'##scar', checkspawncar) then
                cfg.config.SpawnCar = checkspawncar.v
                inicfg.save(cfg,'Ghetto Helper/Ghetto Helper.ini')
            end
            imgui.SameLine()
            imgui.Text(u8'Быстрый спавн каров')
            imgui.SameLine()
            if imgui.Button(fa.ICON_COGS..'##8') then imgui.OpenPopup(u8'scar') end
            if imgui.BeginPopup(u8'scar') then
                imgui.Text(u8'Быстрый спавн каров фракции /scar')
                imgui.EndPopup()
            end

            if imgui.Checkbox(u8'##sklad', checksklad) then
                cfg.config.Sklad = checksklad.v
                inicfg.save(cfg,'Ghetto Helper/Ghetto Helper.ini')
            end
            imgui.SameLine()
            imgui.Text(u8'Быстрое открытие склада')
            imgui.SameLine()
            if imgui.Button(fa.ICON_COGS..'##9') then imgui.OpenPopup(u8'sklad') end
            if imgui.BeginPopup(u8'sklad') then
                imgui.Text(u8'Быстрое открытие складав фракции /sk')
                imgui.EndPopup()
            end
            if imgui.Checkbox(u8'##nabor', checknabor) then
                cfg.config.Nabor = checknabor.v
                inicfg.save(cfg,'Ghetto Helper/Ghetto Helper.ini')
            end
            imgui.SameLine()
            imgui.Text(u8'Объявления о наборе(в разработке)')
            imgui.SameLine()
            if imgui.Button(fa.ICON_COGS..'##10') then imgui.OpenPopup(u8'nabor') end
            if imgui.BeginPopup(u8'nabor') then
                imgui.Text(u8'Быстрая рассылка о наборе во фракцию при вводе команды /na')
                imgui.PushItemWidth(130)
                if imgui.Combo('', ComboNabor, bands) then
                    cfg.config.NaborBang = ComboNabor.v
                    inicfg.save(cfg,'Ghetto Helper/Ghetto Helper.ini')
                end
                imgui.EndPopup()
            end
        end
        if menu == 4 then
            if imgui.Checkbox('##mb', cmdmb) then
                cfg.config.CmdMb = cmdmb.v
                inicfg.save(cfg,'Ghetto Helper/Ghetto Helper.ini')
            end
            imgui.SameLine()
            imgui.Text(u8'/mb')
            imgui.SameLine()
            if imgui.Button(fa.ICON_COGS) then imgui.OpenPopup(u8'mb') end
            if imgui.BeginPopup(u8'mb') then
                imgui.Text(u8'Быстрое открытие /members')
                imgui.EndPopup()
            end
			
			--[[if imgui.Checkbox('##OverLay', checkkill) then
                cfg.config.OverLay = OverLay.v
                inicfg.save(cfg,'Ghetto Helper/Ghetto Helper.ini')
            end
            imgui.SameLine()
            imgui.Text(u8'OverLay')
            imgui.SameLine()
            if imgui.Button(fa.ICON_COGS..'##100') then imgui.OpenPopup(u8'OverLay') end
            if imgui.BeginPopup(u8'ОверЛей') then
                imgui.Text(u8'Статистика по онлайну и прочему.')
                imgui.EndPopup()
            end]]
            if imgui.Checkbox('##m4', cmdm4) then
                cfg.config.CmdM4 = cmdm4.v
                inicfg.save(cfg,'Ghetto Helper/Ghetto Helper.ini')
            end
            imgui.SameLine()
            imgui.Text(u8'/m4')
            imgui.SameLine()
            imgui.Ques(u8'Быстрое создание эмки /m4 [Кол-вл]')
        end
        if menu == 5 then
            imgui.Text(u8'Автообновление')
            if imgui.RadioButton(u8'Включить', radioautoupdate, 1) then
                cfg.config.AutoUpdate = 1
                inicfg.save(cfg,'Ghetto Helper/Ghetto Helper.ini')
            end
            imgui.SameLine()
            if imgui.RadioButton(u8'Выключить', radioautoupdate, 2) then
                cfg.config.AutoUpdate = 2
                inicfg.save(cfg,'Ghetto Helper/Ghetto Helper.ini')
            end
            imgui.Text(u8'Команда активации')
            imgui.SameLine()
            if imgui.InputText('', commandact) then
                cfg.config.CommandAct = commandact.v
                inicfg.save(cfg,'Ghetto Helper/Ghetto Helper.ini')
            end
        end
        imgui.EndChild()
        imgui.BeginChild("left_info", imgui.ImVec2(150, 70), false)
        imgui.NewLine()
        imgui.SameLine(15)
        imgui.SetCursorPosY(imgui.GetCursorPosY()+13)
        imgui.Text(u8("АВТОР"))
        imgui.SameLine(95)
        imgui.SetCursorPosY(imgui.GetCursorPosY()-3)
        imgui.Button("Squzi", imgui.ImVec2(50, 25))
        imgui.NewLine()
        imgui.SameLine(15)
        imgui.SetCursorPosY(imgui.GetCursorPosY()+3.5)
        imgui.Text(u8("ВЕРСИЯ"))
        imgui.SameLine(95)
        imgui.SetCursorPosY(imgui.GetCursorPosY()-3.5)
        imgui.Button(tostring(thisScript().version), imgui.ImVec2(50, 25))
        imgui.EndChild()
        imgui.SameLine()
        imgui.BeginChild("right_info", imgui.ImVec2(500, 100), false)
        imgui.SetCursorPosY(imgui.GetCursorPosY()+10)
        if imgui.Button(u8'Перезагрузить скрипт', imgui.ImVec2(-1, 25)) then lua_thread.create(function() reload = true window.v = false imgui.ShowCursor = false msg('Скрипт был принудительно перезагружен') wait(50) thisScript():reload() end) end
        if imgui.Button(u8'Сбросить настройки', imgui.ImVec2(-1, 25)) then
            msg('Настройки были сборошены до состояние "По умолчанию"')
            os.remove(getWorkingDirectory()..'/config/Ghetto Helper/Ghetto Helper.ini')
            msg('Скрипт был принудительно перезагружен')
            window.v = false
            thisScript():reload()
        end
		--imgui.SameLine(1)
		if imgui.Button(u8"Выход", imgui.ImVec2(-1, 25)) then
			window.v = false
		end
        imgui.EndChild()
        imgui.End()
end

function autoupdate(json_url, prefix, url)
    lua_thread.create(function()
        local dlstatus = require('moonloader').download_status
        local json = getWorkingDirectory() .. '\\'..thisScript().name..'-version.json'
        if doesFileExist(json) then os.remove(json) end
        downloadUrlToFile(json_url, json,
        function(id, status, p1, p2)
            if status == dlstatus.STATUSEX_ENDDOWNLOAD then
            if doesFileExist(json) then
                local f = io.open(json, 'r')
                if f then
                local info = decodeJson(f:read('*a'))
                updatelink = info.updateurl
                updateversion = info.latest
                f:close()
                os.remove(json)
                if updateversion ~= thisScript().version then
                    lua_thread.create(function(prefix)
                    local dlstatus = require('moonloader').download_status
                    local color = -1
                    msg('Обнаружено обновление. Пытаюсь обновиться c '..thisScript().version..' на '..updateversion)
                    wait(250)
                    downloadUrlToFile(updatelink, thisScript().path,
                        function(id3, status1, p13, p23)
                        if status1 == dlstatus.STATUS_DOWNLOADINGDATA then
                            print(string.format('Загружено %d из %d.', p13, p23))
                        elseif status1 == dlstatus.STATUS_ENDDOWNLOADDATA then
                            print('Загрузка обновления завершена.')
                            msg('Обновление завершено!')
                            goupdatestatus = true
                            lua_thread.create(function() wait(500) thisScript():reload() end)
                        end
                        if status1 == dlstatus.STATUSEX_ENDDOWNLOAD then
                            if goupdatestatus == nil then
                            msg('Обновление прошло неудачно. Запускаю устаревшую версию.')
                            update = false
                            end
                        end
                        end
                    )
                    end, prefix
                    )
                else
                    update = false
                    msg('Обновление не требуется.')
                end
                end
            else
                msg('Не могу проверить обновление. Смиритесь или проверьте самостоятельно на '..url)
                update = false
            end
            end
        end
        )
        while update ~= false do wait(100) end
    end)
end
                                                                                                                                                                                                                                                                                                                                                                                                                           function LoadScript() if thisScript().filename ~= 'Ghetto Helper by VRush.lua' then msg('Название скрипта было изменено, скрипт отключён') msg('Измените название скрипта на "Ghetto Helper by VRush.lua"') os.rename(getWorkingDirectory()..'\\'..thisScript().filename,getWorkingDirectory()..'\\Ghetto Helper by VRush.lua') end end

function main()
    while not isSampAvailable() do wait(200) end
   -- while not sampIsLocalPlayerSpawned() do wait(200) end
    if not doesDirectoryExist('moonloader/config/Ghetto Helper') then createDirectory('moonloader/config/Ghetto Helper') end
    if not doesFileExist(getWorkingDirectory()..'/config/Ghetto Helper/Ghetto Helper.ini') then inicfg.save(cfg, 'Ghetto Helper/Ghetto Helper.ini') end
    if not doesFileExist(getWorkingDirectory()..'/config/Ghetto Helper/bell.wav') then
        downloadUrlToFile('https://github.com/Venibon/Ghetto-Helper/raw/main/bell.wav', getWorkingDirectory()..'/config/Ghetto Helper/bell.wav')
    end
    if not doesFileExist(getWorkingDirectory()..'/resource/fonts/fontawesome-webfont.tt') then
        downloadUrlToFile('https://github.com/Venibon/Ghetto-Helper/raw/main/fontawesome-webfont.ttf', getWorkingDirectory()..'/resource/fonts/fontawesome-webfont.tt')
    end
        imgui.Process = false
        local json = getWorkingDirectory() .. '\\'..thisScript().name..'-version.json'
        if doesFileExist(json) then os.remove(json) end
        downloadUrlToFile('https://raw.githubusercontent.com/Qerkdb/Ghetto-Tools/main/autoupdate.json', json,
          function(id, status, p1, p2)
            if status == dlstatus.STATUSEX_ENDDOWNLOAD then
              if doesFileExist(json) then
                local f = io.open(json, 'r')
                if f then
                  local info = decodeJson(f:read('*a'))
                  updateversion = info.latest
                  f:close()
                  os.remove(json)
                end
              end
            end
        end)
        msg('Загружен! Автор доработки Squzi. Открыть меню: /'..cfg.config.CommandAct)
        if cfg.config.AutoUpdate == 1 then
            autoupdate("https://raw.githubusercontent.com/Qerkdb/Ghetto-Tools/main/autoupdate.json", '['..string.upper(thisScript().name)..']: ', "https://www.blast.hk/threads/138165/")
        elseif cfg.config.AutoUpdate == 2 then
            msg('Автообновление было выключено, проверьте обновление в Главном меню')
        end

        sampRegisterChatCommand('gh', function()
            if cfg.config.mainwin then
                window_v = true
            else
                window.v = not window.v
            end
        end)

        sampRegisterChatCommand(cfg.config.CommandAct, function()
            if cfg.config.mainwin then
                window_v.v = true
            else
                window.v = not window.v
            end
        end)

        sampRegisterChatCommand("fu", function(arg)
            if cfg.config.UnInvite then
                if not arg:match('%d+') then
                    sampAddChatMessage('Правильный ввод: /fu [ID]', -1)
                else
                    id = tonumber(arg)
                    sampSendChat('/uninvite '..arg..' '..u8:decode(cfg.config.UvalText))
                end
            else
                sampSendChat('/1')
            end
        end)

        sampRegisterChatCommand("mb", function(arg)
            if cfg.config.CmdMb then
                sampSendChat('/members')
            else
                sampSendChat('/1')
            end
        end)

        sampRegisterChatCommand("scar", function(arg)
            if cfg.config.SpawnCar then
                sampSendChat('/lmenu')
                scar = true
            else
                sampSendChat('/1')
            end
        end)

        sampRegisterChatCommand("sk", function(arg)
            if cfg.config.Sklad then
                sampSendChat('/lmenu')
                sampSendDialogResponse(1214, 1, 3, -1)
                return false
            else
                sampSendChat('/1')
            end
        end)

        sampRegisterChatCommand("na", function(arg)
            if cfg.config.Nabor then
                lua_thread.create(function()
                    local g = ComboNabor.v + 1
                    msg('Проходит набор в '..bands[g]..  ' Всех ждем на респе!')
                    printStringNow('Nabor', 6000)
                    sampSendChat('/fam Проходит набор в '..bands[g]..  ' Всех ждем на респе!')
                    wait(2500)
                    sampSendChat('/al Проходит набор в '..bands[g]..  ' Всех ждем на респе!')
                    wait(2500)
                    sampProcessChatInput('/vra Проходит набор в '..bands[g]..  ' Всех ждем на респе!')
                end)
            else
                sampSendChat('/1')
            end
        end)
        --[[sampRegisterChatCommand("de", function(input)
            if cfg.config.CmdDe then
				sampSendChat('/invent')
                sampSendClickTextdraw(2148)
				wait(2500)
				sampSendClickTextdraw(2301)
				
			end
		end)]]

        sampRegisterChatCommand("m4", function(arg)
            if cfg.config.CmdM4 then
                lua_thread.create(function()
                    if arg == '' or arg == nil or arg == 0 then
                        msg('Введите кол-во патрон')
                    else
                        ptm4 = arg
                        sampSendChat('/creategun')
                        wait(100)
                        sampSendDialogResponse(7546, 1, 3, _)
                        wait(100)
                        sampSetCurrentDialogEditboxText(ptm4)
                        wait(100)
                        sampCloseCurrentDialogWithButton(1)
                    end
                end)
            else
                sampSendChat('/1')
            end
        end)

        bool, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
        lua_thread.create(drugtimer)
        lua_thread.create(hphud)
		lua_thread.create(lpan)
        local rX, rY = getScreenResolution()
    while true do
        wait(0)
        imgui.Process = window.v or window_v.v
        if cfg.config.SbivBind then
            if isKeyJustPressed(cfg.config.SbivKey) and not sampIsCursorActive() then
                sampSendChat(u8:decode(cfg.config.TextSbiv))
            end
        end
        if cfg.config.DrugTimer then
            if wasKeyPressed(VK_X) and not sampIsCursorActive() then
                hp = getCharHealth(PLAYER_PED)
                if hp < 120 then
                    sampSendChat('/usedrugs 3')
                elseif hp >= 120 and hp < 140 then
                    sampSendChat('/usedrugs 2')
                elseif hp >= 140 then
                    sampSendChat('/usedrugs 1')
                end
                Timer.start, Timer.state = os.clock(), true
            end
        end
        if cfg.config.Invite then
            local result, target = getCharPlayerIsTargeting(playerHandle)
            if result then result, playerid = sampGetPlayerIdByCharHandle(target) end
            if result and isKeyDown(VK_1) then
                name = sampGetPlayerNickname(playerid)
                sampSendChat('/me передал бандану')
                wait(1000)
                sampSendChat('/invite '..playerid)
                invite = true
                msg('Вы приняли игрока с ником: '..name..'  Ранг: '..invrank.v)
            end
        end
        if changestatspos then
            sampToggleCursor(true)
            local CPX, CPY = getCursorPos()
            cfg.config.CPX = CPX
            cfg.config.CPY = CPY
            inicfg.save(cfg,'Ghetto Helper/Ghetto Helper.ini')
        end
        if isKeyJustPressed(VK_LBUTTON) and changecheckonlinepos then
            changecheckonlinepos = false
            sampToggleCursor(false)
            msg('Позиция сохранена.')
            window.v = true
        end
        if changecheckonlinepos then
            sampToggleCursor(true)
            local CPX, CPY = getCursorPos()
            cfg.config.OPX = CPX
            cfg.config.OPY = CPY
            inicfg.save(cfg,'Ghetto Helper/Ghetto Helper.ini')
        end
        if isKeyJustPressed(VK_LBUTTON) and changestatspos then
            changestatspos = false
            sampToggleCursor(false)
            msg('Позиция сохранена.')
            window.v = true
        end
    end
end

function saveini(section,value)
    cfg.config[section] = value
    inicfg.save(cfg,'Ghetto Helper/Ghetto Helper.ini')
end

local msguval = {
    'псж',
    'psj',
    'увал',
    'увал псж',
    'увольте',
		'кик'
}

function sampev.onServerMessage(color, text)
    if cfg.config.formuval then
        if text:find('%[F%] .+ (.+)%[(.+)%]: (.+)') then
            local nick, id, textmsg = text:match('%[F%] .+ (.+)%[(.+)%]: (.+)')
            for k, v in ipairs(msguval) do
                if textmsg:lower():find(v) then
                    msg(nick..' Хочет уйти по собственному желанию. Нажмите + для одобрения или - для отказа.')
                    lasttime = os.time()
                    lasttimes = 0
                    time_out = 5
                    lua_thread.create(function()
                        while lasttimes < time_out do
                            lasttimes = os.time() - lasttime
                            wait(0)
                            printStyledString("PSJ  "..nick..' ' .. time_out - lasttimes .. " WAIT", 1000, 4)
                            if isKeyJustPressed(0xBB) then
                                printStyledString("Accept Form", 1000, 4)
                                sampSendChat('/uninvite '..id..' Выселен.')
                                msg(nick..' Был уволен ПСЖ.',-1)
                                break
                            end
                            if isKeyJustPressed(0xBD) then
                                printStyledString("Skipped Form", 1000, 4)
                                break
                            end
                        end
                    end)
                end
            end
        end
    end
end

function sampev.onShowDialog(id, style, title, button1, button2, text)
    if invite and id == 25640 then
        sampSendDialogResponse(id, 1 , invrank.v - 1, 0)
        msg('Вы приняли игрока с ником: '..name..'  Ранг: '..invrank.v)
        invite = false
        return false
    end
    if scar and id == 1214 then
        sampSendDialogResponse(1214, 1, 4, -1)
        scar = false
        return false
    end
end

function sampev.onSendGiveDamage(playerId,damage)
	if cfg.config.Bell then
		local audio = loadAudioStream('moonloader/config/Ghetto Helper/bell.wav')
		setAudioStreamState(audio, 1)
	end
    if cfg.config.Stats then
        dmg = tonumber(damage)
        dmg = math.floor(dmg)
        total = total + dmg -- Total Damage
        current = current + dmg -- Current Damage
        local _, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
        result, handle2 = sampGetCharHandleBySampPlayerId(playerId)
        health = sampGetPlayerHealth(playerId)
        if health < damage or health == 0 then
            kills = kills + 1
        end
    end
    if cfg.config.Kill then
        health = sampGetPlayerHealth(playerId)
        if health < damage or health == 0 then
            printStyledString('+KILL', 5000, 7)
        end
    end
end


function sampev.onSendSpawn()
    lua_thread.create(function()
        killss = 0
        if cfg.config.Stats then
            if firstspawn == false then wait(30) firstspawn = true end
            if firstspawn == true then
                deaths = deaths + 1
            end
        end
        local TimeLeft = math.floor(Timer.start + TimerTime - os.clock())
    end)
end

math.round = function(num, idp)
    local mult = 10^(idp or 0)
    return math.floor(num * mult + 0.5) / mult
end

function statsupdate()
    while true do wait(0)
        if cfg.config.Stats then
            renderFontDrawText(font,"{ffffff}Kills: {ef3226}"..kills.."\n{ffffff}Deaths: {ef3226}"..deaths.."\n{ffffff}Damage: {ef3226}"..total, cfg.config.CPX, cfg.config.CPY,0xffffffff)
        end
    end
end

function hphud()
    while true do wait(0)
        if cfg.config.HPHud then
            if not sampTextdrawIsExists(500) and sampIsLocalPlayerSpawned() then
                sampTextdrawCreate(500, "_", 569, 66.9)
            end
            sampTextdrawSetLetterSizeAndColor(500, 0.29, 0.9, 4294967295.0)
            sampTextdrawSetPos(500, 569.2, 66.9)
            sampTextdrawSetStyle(500, 3)
            sampTextdrawSetAlign(500, 569)
            sampTextdrawSetOutlineColor(500, 1, 4278190080.0)
            sampTextdrawSetString(500, "" .. getCharHealth(PLAYER_PED))
        elseif not cfg.config.HPHud then
            sampTextdrawDelete(500)
        end
    end
end

function drugtimer()
    while true do wait(0)
        if cfg.config.DrugTimer then
            if Timer.state then
                local TimeLeft = math.floor(Timer.start + TimerTime - os.clock())
                local rX, rY = getScreenResolution()
                renderFontDrawText(fonts,TimeLeft..'s', rX/1.05, rY/6.65, 0xFFFFFFFF, 0x90000000)
                if TimeLeft < 1 then
                    Timer.state = false
                end
            else
                local rX, rY = getScreenResolution()
                renderFontDrawText(fonts,'Use', rX/1.05, rY/6.65, 0xFFFFFFFF, 0x90000000)
            end
        end
    end
end

function msg(arg)
    sampAddChatMessage('{FFFFFF}[{5d2d89}Ghetto Helper{FFFFFF}]{5d2d89}: {FFFFFF}'..arg, -1)
end

function imgui.Ques(text)
    imgui.SameLine()
    imgui.TextDisabled("(?)")
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
        imgui.TextUnformatted(u8(text))
        imgui.EndTooltip()
    end
end

function imgui.CenterText(text)
    local width = imgui.GetWindowWidth()
    local calc = imgui.CalcTextSize(text)
    imgui.SetCursorPosX( width / 2 - calc.x / 2 )
    imgui.Text(text)
end

function imgui.TextColoredRGB(text)
    local style = imgui.GetStyle()
    local colors = style.Colors
    local ImVec4 = imgui.ImVec4

    local explode_argb = function(argb)
        local a = bit.band(bit.rshift(argb, 24), 0xFF)
        local r = bit.band(bit.rshift(argb, 16), 0xFF)
        local g = bit.band(bit.rshift(argb, 8), 0xFF)
        local b = bit.band(argb, 0xFF)
        return a, r, g, b
    end

    local getcolor = function(color)
        if color:sub(1, 6):upper() == 'SSSSSS' then
            local r, g, b = colors[1].x, colors[1].y, colors[1].z
            local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
            return ImVec4(r, g, b, a / 255)
        end
        local color = type(color) == 'string' and tonumber(color, 16) or color
        if type(color) ~= 'number' then return end
        local r, g, b, a = explode_argb(color)
        return imgui.ImColor(r, g, b, a):GetVec4()
    end

    local render_text = function(text_)
        for w in text_:gmatch('[^\r\n]+') do
            local text, colors_, m = {}, {}, 1
            w = w:gsub('{(......)}', '{%1FF}')
            while w:find('{........}') do
                local n, k = w:find('{........}')
                local color = getcolor(w:sub(n + 1, k - 1))
                if color then
                    text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                    colors_[#colors_ + 1] = color
                    m = n
                end
                w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
            end
            if text[0] then
                for i = 0, #text do
                    imgui.TextColored(colors_[i] or colors[1], u8(text[i]))
                    imgui.SameLine(nil, 0)
                end
                imgui.NewLine()
            else imgui.Text(w) end
        end
    end

    render_text(text)
end

function imgui.Link(link,name,myfunc)
    myfunc = type(name) == 'boolean' and name or myfunc or false
    name = type(name) == 'string' and name or type(name) == 'boolean' and link or link
    local size = imgui.CalcTextSize(name)
    local p = imgui.GetCursorScreenPos()
    local p2 = imgui.GetCursorPos()
    local resultBtn = imgui.InvisibleButton('##'..link..name, size)
    if resultBtn then
        if not myfunc then
            os.execute('explorer '..link)
        end
    end
    imgui.SetCursorPos(p2)
    if imgui.IsItemHovered() then
        imgui.TextColored(imgui.ImVec4(0, 0.5, 1, 1), name)
        imgui.GetWindowDrawList():AddLine(imgui.ImVec2(p.x, p.y + size.y), imgui.ImVec2(p.x + size.x, p.y + size.y), imgui.GetColorU32(imgui.ImVec4(0, 0.5, 1, 1)))
    else
        imgui.TextColored(imgui.ImVec4(0, 0.3, 0.8, 1), name)
    end
    return resultBtn
end


--function onScriptTerminate(Script)
--    if not reload then
--        if Script == thisScript() then
--            lua_thread.create(function()
--                msg('Скрипт крашнулся/вылетел, сообщите о проблеме создателю скрипта')
--                msg('Его ВК - https://vk.com/veni_rush')
--            end)
--        end
--    end
--end


function isKeysDown(key, state)
    if state == nil then
        state = false
    end

    if key[1] == nil then
        return false
    end

    local result = false
    slot4 = #key < 2 and tonumber(key[1]) or tonumber(key[2])

    if #key < 2 then
    if not isKeyDown(VK_RMENU) and not isKeyDown(VK_LMENU) and not isKeyDown(VK_LSHIFT) and not isKeyDown(VK_RSHIFT) and not isKeyDown(VK_LCONTROL) and not isKeyDown(VK_RCONTROL) then
        if wasKeyPressed(slot4) and not state then
            result = true
        elseif isKeyDown(slot4) and state then
            result = true
        end
    end
    elseif isKeyDown(tonumber(key[1])) and not wasKeyReleased(tonumber(key[1])) then
    if wasKeyPressed(slot4) and not state then
        result = true
    elseif isKeyDown(slot4) and state then
        result = true
        end
    end

    if nextLockKey == key then
        if state and not wasKeyReleased(slot4) then
            result = false
        else
            result = false
            nextLockKey = ""
        end
    end

    return result
end

function lpan()
	while true do wait(0)
		if cfg.config.lpan then
			if isKeyJustPressed(VK_L) and not sampIsChatInputActive() and not sampIsDialogActive() and not isPauseMenuActive() and not isSampfuncsConsoleActive() then 
				sampSendChat("/lock")
			end
			if isKeyJustPressed(VK_R) and not sampIsChatInputActive() and not sampIsDialogActive() and not isPauseMenuActive() and not isSampfuncsConsoleActive() then
				sampSendChat("/anim 9")
			end
			if isKeyJustPressed(VK_P) and not sampIsChatInputActive() and not sampIsDialogActive() and not isPauseMenuActive() and not isSampfuncsConsoleActive() then
				sampSendChat("/phone")
			end
		end
	end
end

function OverLay()
	while true do wait(0)
		if cfg.config.OverLay then
		sampAddChatMessage('qwee')
		end
	end
end
