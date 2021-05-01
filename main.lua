local lg = love.graphics
local fkge = require"fkge"
local S = fkge.scene
local C = fkge.componentSystem
local E = fkge.entity

lg.setDefaultFilter("nearest", "nearest")

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
		if e.image then
			if e.quad then
				lg.draw(e.image, e.quad, 0, 0)
			else
				lg.draw(e.image, 0, 0)
			end
		end
	end,
	pos = function (e, x, y)
		e.attr{
			x = x or e.x,
			y = y or e.y,
		}
	end,
}

local lillyImg = lg.newImage("lilly.png")
C{
	name = "lilly",
	parents = "2d",
	w = 16,
	h = 16,
	image = lillyImg,
	quad = lg.newQuad(0, 0, 16, 16, lillyImg:getDimensions()),
	init = function (e, x, y)
		e.pos(e, x, y)
		e.s = math.random() * 2 + 1
		e.av = (math.random() - 0.5) / 20
	end,
	system = function (e)
		e.r = e.r + e.av
	end,
}

C{
	name = "input",
	system = function (e, msg)
		for _, key in ipairs(msg.keyreleased or {}) do
			if key == "escape" then
				love.event.quit()
			end
		end
	end,
}

C{
	name = "froggy",
	parents = "input",
}

S("game", function ()
	math.randomseed(os.time())
	E("froggy")
	for i=1, 32 do
		E("lilly", math.random() * 360, math.random() * 240)
	end
end)

fkge.game{
	background = {1/3, 2/3, 1}
}
S"game"
