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
--local entity = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
local entity = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"]) -- за то видны сигналы при наведении мышкой
entity.type = "electric-pole"
entity.name = "signal-logger"
entity.icon = "__signal-logger__/constant-combinator-item.png"
entity.minable.result = "signal-logger"
entity.maximum_wire_distance = entity.circuit_wire_max_distance
entity.supply_area_distance = 0
--entity.sprites = make_4way_animation_from_spritesheet({ layers =
entity.pictures =
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
entity.connection_points = entity.circuit_wire_connection_points
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
