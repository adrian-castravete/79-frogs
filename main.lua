local lg = love.graphics
local fkge = require"fkge"
local S = fkge.scene
local C = fkge.componentSystem
local E = fkge.entity
local A = fkge.anim
local L = fkge.lerp

WIDTH, HEIGHT = 360, 240

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
	init = function (e, x, y, s)
		e.pos(e, x, y)
		e.s = s or math.random() * 2 + 1
		e.av = math.random() / 20 + 0.01
		if math.random() < 0.5 then
			e.av = -e.av
		end
	end,
	system = function (e)
		e.r = e.r + e.av
	end,
}

C{
	name = "input",
	system = function (e, msg)
		for _, key in ipairs(msg.keypressed or {}) do
			if key == "escape" then
				love.event.quit()
			else
				e.jump = true
			end
		end
		if msg.mousepressed and #msg.mousepressed > 0 or
		   msg.joystickpressed and #msg.joystickpressed > 0 then
			e.jump = true
		end
	end,
}

local froggyImg = lg.newImage("froggy.png")
local fw, fh = froggyImg:getDimensions()
local froggyQuads = {
	ready = lg.newQuad(0, 0, 16, 16, fw, fh),
	jump = lg.newQuad(16, 0, 16, 32, fw, fh),
	water = lg.newQuad(0, 16, 16, 16, fw, fh),
}
C{
	name = "froggy",
	parents = "input, 2d",
	w = 16,
	h = 16,
	state = "ready",
	image = froggyImg,
	quad = froggyQuads.ready,
	init = function (e)
		e.setLilly(e, fkge.find("lilly", function (e) return e end))
	end,
	--[[draw = function (e)
		if e.image then
			if e.quad then
				lg.draw(e.image, e.quad, 0, 0)
			else
				lg.draw(e.image, 0, 0)
			end
		end
		lg.setColor(1, 0, 0)
		local ms = math.sin(e.r)
		local mc = math.cos(e.r)
		lg.line(8, 8-25, 8, 8-75)
	end,--]]
	setLilly = function (e, l)
		e.lilly = l
		e.x = l.x
		e.y = l.y
		e.rd = l.r - e.r
		e.setState(e, "ready")
	end,
	setState = function (e, s)
		e.state = s
		e.quad = froggyQuads[s]
	end,
	doJump = function (e)
		e.jump = false
		e.setState(e, "jump")
		for i=1, 10 do
			local d = 25 + i*5
			local l = e.lillyAt(e, e.x + math.sin(e.r)*d, e.y - math.cos(e.r)*d)
			if l then
				e.lilly.destroy = true
				e.jumpNormal(e, l, d)
				return
			end
		end
		e.jumpWater(e)
	end,
	lillyAt = function (e, x, y)
		return fkge.find("lilly", function (l)
				local dx, dy = l.x - x, l.y - y
				if math.sqrt(dx*dx + dy*dy) < l.s*8 then
					return l
				end
			end)
	end,
	jumpNormal = function (e, l, d, cb)
		local sx, sy = e.x, e.y
		A(d / 60, function (v)
			e.s = math.sin(v * math.pi) + 1
			if l then
				e.x = L(sx, l.x, v)
				e.y = L(sy, l.y, v)
			else
				e.x = e.x + math.sin(e.r)
				e.y = e.y - math.cos(e.r)
			end
		end, function()
			if l then
				e.setLilly(e, l)
			end
			if cb then cb(e) end
		end)
	end,
	jumpWater = function (e)
		e.jumpNormal(e, nil, 60, function ()
			e.setState(e, "water")
			A(3, function (v)
				if v < 0.3 then
					e.s = math.sin(v / 0.3 * math.pi) + 1
					e.quad:setViewport(math.floor(v * 12) * 16, 32, 16, 16, fw, fh)
				else
					e.quad:setViewport(0, 16, 16, 16, fw, fh)
				end
			end, function ()
				fkge.wipe(function ()
					S"game"
				end)
			end)
		end)
	end,
	system = function (e)
		if e.jump then
			e.doJump(e)
		end
		if e.state == "ready" then
			e.r = e.lilly.r - e.rd
		end
	end,
}

S("game", function ()
	math.randomseed(os.time())
	for i=1, 32 do
		local f, x, y, s, n = true, 0, 0, 1, 0
		while f and n < 1000 do
			x, y, s = math.random() * WIDTH, math.random() * HEIGHT, math.random() * 2 + 1
			f = fkge.find("lilly", function (e)
				local dx, dy = math.abs(e.x - x), math.abs(e.y - y)
				if dx < 48 and dy < 48 and math.sqrt(dx*dx + dy*dy) < (e.s + s) * 16 then
					return true
				end
			end)
			n = n + 1
		end
		if n < 1000 then
			E("lilly", x, y, s)
		end
	end
	E("froggy")
end)

fkge.game{
	width = WIDTH,
	height = HEIGHT,
	background = {1/15, 2/15, 6/15}
}
S"game"
