-- Загружаем util (если используем make_4way_animation_from_spritesheet)
local util = require("util")

------------------------------------------------------------
-- ITEM (должен идти до рецепта!)
------------------------------------------------------------
local item = table.deepcopy(data.raw.item["constant-combinator"])
item.name = "signal-logger"
item.icon = "__signal-logger__/constant-combinator-item.png"
--item.icon_size = 64
item.place_result = "signal-logger"
item.order = "z[signal-logger]"
data:extend({item})

------------------------------------------------------------
-- ENTITY
------------------------------------------------------------
local entity = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
entity.type = "decider-combinator"
entity.energy_source = {
      type = "electric",
      usage_priority = "secondary-input"
    }
entity.active_energy_usage = "1kW"
entity.input_connection_bounding_box = {{-0.5, -0.5}, {0.5, 0.5}}
entity.output_connection_bounding_box = {{1, 1}, {1, 1}}
entity.screen_light_offsets =
    {
      {0, 0},
      {0, 0},
      {0, 0},
      {0, 0}
    }
entity.input_connection_points = entity.circuit_wire_connection_points
entity.output_connection_points = {
	{shadow = {red = {0, 0}, green = {0, 0} }, wire = { red = {0, 0}, green = {0, 0} }},
	{shadow = {red = {0, 0}, green = {0, 0} }, wire = { red = {0, 0}, green = {0, 0} }},
	{shadow = {red = {0, 0}, green = {0, 0} }, wire = { red = {0, 0}, green = {0, 0} }},
	{shadow = {red = {0, 0}, green = {0, 0} }, wire = { red = {0, 0}, green = {0, 0} }}
}

--entity.type = "electric-pole"
entity.name = "signal-logger"
entity.icon = "__signal-logger__/constant-combinator-item.png"
entity.minable.result = "signal-logger"
--entity.maximum_wire_distance = entity.circuit_wire_max_distance
--entity.supply_area_distance = 0
entity.sprites = make_4way_animation_from_spritesheet(
--entity.pictures =
    {
      layers =
      {
        {
          direction_count = 4,
          scale = 0.5,
          filename = "__signal-logger__/constant-combinator.png",
          width = 114,
          height = 102,
          shift = util.by_pixel(0, 5)
        },
        {
          direction_count = 4,
          scale = 0.5,
          filename = "__base__/graphics/entity/combinator/constant-combinator-shadow.png",
          width = 98,
          height = 66,
          shift = util.by_pixel(8.5, 5.5),
          draw_as_shadow = true
        }
      }
    }
)
--entity.connection_points = entity.circuit_wire_connection_points
data:extend({entity})

------------------------------------------------------------
-- RECIPE
------------------------------------------------------------
data:extend({
	{
		type = "recipe",
		name = "signal-logger",
		enabled = true,
		ingredients = {
			{type = "item", name = "electronic-circuit", amount = 5},
			{type = "item", name = "iron-plate", amount = 2}
		},
		results = {
			{type = "item", name = "signal-logger", amount = 1}
		}
	}
})
