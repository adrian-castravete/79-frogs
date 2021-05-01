local lg = love.graphics
local fkge = require"fkge"
local S = fkge.scene
local C = fkge.componentSystem
local E = fkge.entity

C{
	name = "2d",
	x = 0,
	y = 0,
	w = 8,
	h = 8,
	r = 0,
	s = 1,
	init = function (e, x, y)
		e.pos(e, x, y)
	end,
	system = function (e)
		lg.push()
		lg.translate(e.x, e.y)
		lg.rotate(e.r)
		lg.scale(e.s, e.s)
		lg.translate(-e.w*0.5, -e.h*0.5)
		e.draw(e)
		lg.pop()
	end,
	draw = function (e)
	end,
	pos = function (e, x, y)
		e.attr{
			x = x or e.x,
			y = y or e.y,
		}
	end,
}

C{
	name = "lilly",
	parents = "2d",
	w = 16,
	h = 16,
	init = function (e, x, y)
		e.pos(e, x, y)
		e.s = math.random() + 1
	end,
	draw = function (e)
		lg.setColor{0.5, 0.8, 0}
		lg.arc("fill", 8, 8, 8, 0, 4.72)
	end,
	system = function (e)
		e.s = math.random() + 1
		e.r = e.r + 0.1
	end,
}

S("game", function()
	E("lilly", 64, 48)
end)

fkge.game{
	background = {1/3, 2/3, 1}
}
S"game"
