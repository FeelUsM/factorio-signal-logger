local function tick2time(t)
	local s = math.floor(t / 60)
	t = t % 60
	local m = math.floor(s / 60)
	s = s % 60
	local h = math.floor(m / 60)
	m = m % 60
	local d = math.floor(h / 24)
	h = h % 24
	return string.format("%d-%02d:%02d:%02d.%02d", d, h, m, s, t)
end

local function log_name(entity, message, error)
	if not (entity and entity.valid) then
		game.print("invalid entity")
		return
	end
	local pos = entity.position
	local tick
	if game then
		tick = tick2time(game.tick)
	else
		tick = "startup"
	end
	local line = string.format("%s, [%d: %d, %d], %s %s.", 
		tick, 
		entity.unit_number,
		pos.x, 
		pos.y, 
		message,
		entity.combinator_description
	)
	helpers.write_file("signals.txt", line.."\n", true)
	if error then
		game.print(line)
	end
end

local function log_signals(entity)
	if not (entity and entity.valid) then
		game.print("invalid entity")
		return
	end
	local tick
	if game then
		tick = tick2time(game.tick)
	else
		tick = "startup"
	end
	local line = string.format("%s, [%d %s] {", tick, entity.unit_number, entity.combinator_description)
	local new_signals = storage.signals[entity.unit_number]
	if new_signals then
		for i =1,#new_signals do
			line = line .. string.format("%s.%s = %d, ", new_signals[i].signal.name, new_signals[i].signal.quality, new_signals[i].count)
		end
	end
	line = line .. "}\n"
	helpers.write_file("signals.txt", line, true)
end

---------------------------------------------------
--- GUI ---

local function create_gui(player, entity)
	-- Удаляем старый GUI если есть
	if player.gui.screen.signal_logger_gui then
		player.gui.screen.signal_logger_gui.destroy()
	end
	
	-- Создаем новый GUI
	local frame = player.gui.screen.add{
		type = "frame",
		name = "signal_logger_gui",
		direction = "vertical",
		caption = "Signal Logger"
	}
	frame.auto_center = true
	
	-- Текстовое поле для ввода имени
	local flow = frame.add{type = "flow", direction = "vertical"}
	flow.style.padding = 10
	
	flow.add{type = "label", caption = "Имя логгера:"}
	
	-- Получаем сохраненное имя из storage
	local textfield = flow.add{
		type = "textfield",
		name = "logger_name_field",
		text = entity.combinator_description
	}
	textfield.style.width = 300
	textfield.focus()
	
	-- Кнопка OK
	local button_flow = flow.add{type = "flow", direction = "horizontal"}
	button_flow.style.top_margin = 10
	button_flow.style.horizontally_stretchable = true
	
	button_flow.add{
		type = "button",
		name = "logger_ok_button",
		caption = "OK",
		style = "confirm_button"
	}
	
	button_flow.add{
		type = "button",
		name = "logger_cancel_button",
		caption = "Отмена"
	}
	
	-- Сохраняем ссылку на entity
	global_open_guis = global_open_guis or {}
	global_open_guis[player.index] = entity
	
	player.opened = frame
end

local function close_gui(player)
	if player.gui.screen.signal_logger_gui then
		player.gui.screen.signal_logger_gui.destroy()
	end
	global_open_guis = global_open_guis or {}
	global_open_guis[player.index] = nil
end

-- Открытие GUI при клике на сущность или призрак
script.on_event(defines.events.on_gui_opened, function(event)
	local entity = event.entity
	
	if entity and entity.valid and (entity.name == "signal-logger" or entity.name == "entity-ghost" and entity.ghost_name == "signal-logger") then
		local player = game.get_player(event.player_index)
		if player then
			create_gui(player, entity)
			return
		end
	end
end)

-- Обработка кликов по кнопкам
script.on_event(defines.events.on_gui_click, function(event)
	local player = game.get_player(event.player_index)
	if not player then return end
	
	local element = event.element
	
	if element.name == "logger_ok_button" then
		local entity = global_open_guis[player.index]
		if entity and entity.valid then
			local gui = player.gui.screen.signal_logger_gui
			if gui then
				local textfield = gui.children[1].logger_name_field
				local new_name = textfield.text or ""
				
				if (entity.name == "signal-logger" or entity.name == "entity-ghost" and entity.ghost_name == "signal-logger") then
					-- Работаем с призраком
					local tags = entity.tags or {}
					local old_name = entity.combinator_description or ""
					
					if old_name ~= new_name then
						entity.combinator_description = new_name
						log_name(entity, string.format("renamed %s ->", old_name))
					end
				end
			end
		end
		close_gui(player)
	elseif element.name == "logger_cancel_button" then
		close_gui(player)
	end
end)

-- Закрытие GUI
script.on_event(defines.events.on_gui_closed, function(event)
	local player = game.get_player(event.player_index)
	if player and event.element and event.element.name == "signal_logger_gui" then
		close_gui(player)
	end
end)

---------------------------------------------------
--- Инициализация ---

local function constructor(entity, nolog)
	if entity and entity.name == "signal-logger" and entity.unit_number then
		registered_loggers[entity.unit_number] = entity
		entity.combinator_description = entity.combinator_description or ""
		storage.signals[entity.unit_number] = storage.signals[entity.unit_number] or {}
		if not nolog then
			log_name(entity, "created")
		end
	else
		game.print("signal-logger constructor: wrong entity")
	end
end

local function metaconstructor(event)
	if event.entity and event.entity.name == "signal-logger" then
		constructor(event.entity) 
	end
end

script.on_event(defines.events.on_built_entity,                metaconstructor)
script.on_event(defines.events.on_robot_built_entity,          metaconstructor)
script.on_event(defines.events.script_raised_built,            metaconstructor)
script.on_event(defines.events.script_raised_revive,           metaconstructor)
script.on_event(defines.events.on_space_platform_built_entity, metaconstructor)

local function destructor(entity)
	if entity and entity.name == "signal-logger" and entity.unit_number then
		log_name(entity, "destroyed")
		storage.signals[entity.unit_number] = nil
		registered_loggers[entity.unit_number] = nil
	else
		game.print("signal-logger destructor: wrong entity")
	end
end

local function metadestructor(event)
	if event.entity and event.entity.name == "signal-logger" then
		destructor(event.entity) 
	end
end

script.on_event(defines.events.on_entity_died,         metadestructor)
script.on_event(defines.events.on_player_mined_entity, metadestructor)
script.on_event(defines.events.on_robot_mined_entity,  metadestructor)

script.on_init(function()
	helpers.write_file("signals.txt", "==== INIT ====\n", true)
	storage = {}
	storage.signals = {} -- unit_number -> signals
	registered_loggers = {} -- unit_number -> pointer
	global_open_guis = {}
	global_oninit = 2 -- full init
end)

script.on_load(function()
	helpers.write_file("signals.txt", "==== NEW SESSION ====\n", true)
	registered_loggers = {}
	global_open_guis = {}
	if storage and storage.signals then
		global_oninit = 1 -- init-compare
	else
		storage = {}
		storage.signals = {}
		global_oninit = 2
		helpers.write_file("signals.txt", "!!!!!!! DATA LOST !!!!!!!\n", true)
	end
end)

-- Копирование настроек через Shift+ПКМ/ЛКМ
script.on_event(defines.events.on_entity_settings_pasted, function(event)
	local source = event.source
	local destination = event.destination
	
	if source and source.valid and (source.name == "signal-logger" or source.name=="entity-ghost" and source.ghost_name == "signal-logger") and
	   destination and destination.valid and destination.name == "signal-logger" then
		local name = source.combinator_description
		local old_name = destination.combinator_description
		log_name(destination, "renamed to")
	end
end)

---------------------------------------------------------------
--- Логирование сигналов ---

local function get_signals(entity)
	return entity.get_signals(defines.wire_connector_id.circuit_red, defines.wire_connector_id.circuit_green)
end

local function signals_changed(a, b)
	if not a then a = {} end
	if not b then b = {} end
	if #a ~= #b then return true end
	for i = 1, #a do
		if a[i].signal.name ~= b[i].signal.name or
			a[i].signal.quality ~= b[i].signal.quality or
			a[i].count ~= b[i].count then
			return true
		end
	end
	return false
end

script.on_event(defines.events.on_tick, function(event)
	if global_oninit then
		local found = {}

		for _, surface in pairs(game.surfaces) do
			for _, entity in pairs(surface.find_entities_filtered{name="signal-logger"}) do
				found[entity.unit_number] = entity

				if global_oninit==1 then
					if not storage.signals[entity.unit_number] then
						log_name(entity, "lost signals for",true)
					else
						log_name(entity, "loaded")
						log_signals(entity)
					end
				end
				if global_oninit==2 then
					log_name(entity, "alredy exist",true)
				end

				constructor(entity, true)
			end
		end
		for unit_number, signals in pairs(storage.signals) do
			if not found[unit_number] then
				local line = string.format("trash %d",unit_number)
				helpers.write_file("signals.txt",line.."\n",true)
				game.print(line)
			end
		end

		global_oninit = 0
	end
	
	if storage and registered_loggers then
		for unit_number, entity in pairs(registered_loggers) do
			if entity.valid and entity.unit_number then
				local new_signals = get_signals(entity)
				local old_signals = storage.signals[entity.unit_number] or {}
				if signals_changed(old_signals, new_signals) then
					storage.signals[entity.unit_number] = new_signals
					log_signals(entity)
				end
			else
				-- Сущность невалидна, удаляем из реестра
				registered_loggers[unit_number] = nil
				storage.signals[unit_number] = nil
			end
		end
	end
end)