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

local function log_name(entity, message)
	if not (entity and entity.valid) then
		global_error = true
		return
	end
	local pos = entity.position
	local tick
	if game then
		tick = tick2time(game.tick)
	else
		tick = "startup"
	end
	local line = string.format("%s, [%d: %d, %d], %s\n", 
		tick, 
		entity.unit_number,
		pos.x, 
		pos.y, 
		message
	)
	helpers.write_file("signals.txt", line, true)
end

local function log_signals(entity, new_signals)
	if not (entity and entity.valid) then
		global_error = true
		return
	end
	local tick
	if game then
		tick = tick2time(game.tick)
	else
		tick = "startup"
	end
	local line = string.format("%s, [%d %s] {", tick, entity.unit_number, storage.logger_names[entity.unit_number])
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
	local unit_number = entity.unit_number
	local current_name = ""
	if unit_number and storage.logger_names and storage.logger_names[unit_number] then
		current_name = storage.logger_names[unit_number]
	end
	
	local textfield = flow.add{
		type = "textfield",
		name = "logger_name_field",
		text = current_name
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

-- Открытие GUI при клике на сущность
script.on_event(defines.events.on_gui_opened, function(event)
	local entity = event.entity
	if entity and entity.valid and entity.name == "signal-logger" then
		local player = game.get_player(event.player_index)
		if player then
			create_gui(player, entity)
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
		if entity and entity.valid and entity.unit_number then
			local gui = player.gui.screen.signal_logger_gui
			if gui then
				local textfield = gui.children[1].logger_name_field
				local new_name = textfield.text or ""
				
				-- Получаем старое имя из storage
				local unit_number = entity.unit_number
				storage.logger_names = storage.logger_names or {}
				local old_name = storage.logger_names[unit_number] or ""
				
				-- Логируем только если имя действительно изменилось
				if old_name ~= new_name then
					log_name(entity, string.format("renamed %s -> %s",old_name, new_name))
					
					-- Сохраняем новое имя в storage
					storage.logger_names[unit_number] = new_name
					
					--game.print(string.format("[Signal Logger] Имя изменено: '%s' -> '%s' at [%d, %d]", 
						--old_name, new_name, entity.position.x, entity.position.y))
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
local function constructor(entity, name)
	if entity and entity.name == "signal-logger" and entity.unit_number then
		if storage.registered_loggers then
			storage.registered_loggers[entity.unit_number] = entity
		end
		if storage.logger_names then
			storage.logger_names[entity.unit_number] = name or ""
		end
		if storage.signals then
			storage.signals[entity.unit_number] = {}
		end
		log_name(entity, string.format("created %s", name))
	else
		game.print("signal-logger constructor: wrong enity\n")
	end
end

local function metaconstructor(event)
	if event.entity and event.entity.name == "signal-logger" then
		constructor(event.entity) 
	end
end

--script.on_event(defines.events.on_built_entity,                metaconstructor)  -- игрок построил руками
script.on_event(defines.events.on_robot_built_entity,          metaconstructor)  -- робот построил
script.on_event(defines.events.script_raised_built,            metaconstructor)  -- другой скрипт создал сущность
script.on_event(defines.events.script_raised_revive,           metaconstructor)  -- сущность восстановлена из призрака скриптом
script.on_event(defines.events.on_space_platform_built_entity, metaconstructor)  -- построено на космической 

local function destructor(entity)
	if entity and entity.name == "signal-logger" and entity.unit_number then
		if storage.logger_names then
			log_name(entity, string.format("destroyed %s",storage.logger_names[entity.unit_number]))
			helpers.write_file("signals.txt", string.format("%s [%d %s] destructed\n", tick2time(game.tick), entity.unit_number, storage.logger_names[entity.unit_number]), true)
			storage.logger_names[entity.unit_number] = nil
		else
			log_name(entity, "destroyed ???")
			helpers.write_file("signals.txt", string.format("%s [%d ???] destructed\n", tick2time(game.tick), entity.unit_number), true)
		end
		if storage.signals then
			storage.signals[entity.unit_number] = nil
		end
		if storage.registered_loggers then
			storage.registered_loggers[entity.unit_number] = nil
		end
	else
		game.print("signal-logger destructor: wrong enity\n")
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

local function init()
	if not storage then storage = {} end
	storage.registered_loggers = {}
	storage.logger_names = {}
	storage.signals = {}
	for _, surface in pairs(game.surfaces) do
		for _, entity in pairs(surface.find_entities_filtered{name="signal-logger"}) do
			constructor(entity)
		end
	end
end

script.on_init(function()
	helpers.write_file("signals.txt", "==== INIT ====\n", true)
	init()
	global_open_guis = {}
end)

script.on_load(function()
	helpers.write_file("signals.txt", "==== NEW SESSION ====\n", true)
	if storage and storage.registered_loggers and storage.logger_names and storage.signals then
		for unit_number, entity in pairs(storage.registered_loggers) do
			log_name(entity, string.format("loaded %s",storage.logger_names[unit_number]))
			log_signals(entity, storage.signals[unit_number])
		end
	else
		helpers.write_file("signals.txt", "!!!!!!! DATA LOST !!!!!!!\n", true)
		global_error = true
	end
	global_open_guis = {}
end)

-- Сохранение настроек в чертеж
script.on_event(defines.events.on_player_setup_blueprint, function(event)
	--game.print("on_player_setup_blueprint")
	local player = game.get_player(event.player_index)
	if not player then return end
	
	local blueprint = player.blueprint_to_setup
	if not blueprint or not blueprint.valid_for_read then
		blueprint = player.cursor_stack
	end
	
	if blueprint and blueprint.valid_for_read and blueprint.is_blueprint then
		local entities = blueprint.get_blueprint_entities()
		if not entities then return end
		
		local mapping = event.mapping.get()
		
		for idx, bp_entity in pairs(entities) do
			if bp_entity.name == "signal-logger" then
				-- Находим реальную сущность через mapping
				local real_entity = mapping[idx]
				if real_entity and real_entity.valid and real_entity.unit_number then
					local name = storage.logger_names[real_entity.unit_number]
					if name and name ~= "" then
						-- Сохраняем имя в tags чертежа
						bp_entity.tags = bp_entity.tags or {}
						bp_entity.tags.logger_name = name
						blueprint.set_blueprint_entities(entities)
					end
				end
			end
		end
	end
end)

-- Восстановление настроек из чертежа
script.on_event(defines.events.on_built_entity, function(event)
	--game.print("on_built_entity")
	local entity = event.created_entity or event.entity
	if entity and entity.valid and entity.name == "signal-logger" and entity.unit_number then
		-- Проверяем есть ли сохраненное имя в tags
		local name = ""
		if event.tags and event.tags.logger_name then
			name = event.tags.logger_name
		end
		constructor(entity,name)
	end
end)

-- Копирование настроек через Shift+ПКМ/ЛКМ
script.on_event(defines.events.on_entity_settings_pasted, function(event)
	--game.print("on_entity_settings_pasted")
	local source = event.source
	local destination = event.destination
	
	if source and source.valid and source.name == "signal-logger" and
	   destination and destination.valid and destination.name == "signal-logger" then
		local source_id = source.unit_number
		local dest_id = destination.unit_number
		
		if source_id and dest_id and storage.logger_names then
			local name = storage.logger_names[source_id]
			if name then
				local old_name = storage.logger_names[dest_id]
				storage.logger_names[dest_id] = name
				log_name(destination, string.format("renamed %s -> %s",old_name, name))
			end
		end
	end
end)

---------------------------------------------------------------

local function get_signals(entity)
	return entity.get_signals(defines.wire_connector_id.circuit_red, defines.wire_connector_id.circuit_green)
end

local function signals_changed(a, b)
	if not a then a = {} end
	if not b then b = {} end
	if #a ~= #b then return true end -- "different length" end
	for i = 1, #a do
		if a[i].signal.name ~= b[i].signal.name or
			a[i].signal.quality ~= b[i].signal.quality or
			a[i].count ~= b[i].count then
			return true -- string.format("different position %d",i)
		end
	end
	return false -- "same"
end

script.on_event(defines.events.on_tick, function(event)
	if global_error then
		init()
		global_error = false
	end
	--for _, surface in pairs(game.surfaces) do
		--for _, entity in pairs(surface.find_entities_filtered{name="signal-logger"}) do
	if storage and storage.registered_loggers then
		for unit_number, entity in pairs(storage.registered_loggers) do
			if entity.unit_number then
				local new_signals = get_signals(entity)
				local old_signals = storage.signals[entity.unit_number] or {}
				if signals_changed(old_signals, new_signals) then
					log_signals(entity, new_signals)
					storage.signals[entity.unit_number] = new_signals
				end
			end
		end
	end
end)