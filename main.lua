local lg = love.graphics
local lp = love.physics
local fkge = require"fkge"
local S = fkge.scene
local C = fkge.componentSystem
local E = fkge.entity
local A = fkge.anim
local L = fkge.lerp

WIDTH, HEIGHT = 240, 160

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
		if e.color then
			lg.setColor(e.color)
		else
			lg.setColor(1, 1, 1)
		end
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

local LillyBody = {
	name = "collision",
}

function LillyBody:system(msg, dt)
	if not self.body then
		local b = lp.newBody(fkge.find("world").world, self.x, self.y, "dynamic")
		local sh = lp.newCircleShape(8 * self.s)
		local f = lp.newFixture(b, sh)
		b:setPosition(self.x, self.y)
		b:setLinearVelocity(0, 0)
		b:setLinearDamping(0.4, 0.4)
		--f:setRestitution(0.4)
		self.body = b
		self.shape = sh
		self.fixture = f
	end
	self.x, self.y = self.body:getPosition()
end

function LillyBody:setSpeed(a, v)
	local vx = math.sin(a) * v * 100
	local vy = -math.cos(a) * v * 100
	self.body:setLinearVelocity(vx, vy)
end

--[[
function LillyBody:_draw()
	local x, y = self.body:getPosition()
	local r = self.shape:getRadius()
	lg.circle("line", x, y, r)
end

local oldDraw = love.draw
function love.draw()
	oldDraw()
	fkge.each("collision", function(e)
		e:_draw()
	end)
end--]]
C(LillyBody)

local lillyImg = lg.newImage("lilly.png")
C{
	name = "lilly",
	parents = "2d, collision",
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
	system = function (e, msg, dt)
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
		fkge.message("flower", "landedOn", l)
	end,
	setState = function (e, s)
		e.state = s
		e.quad = froggyQuads[s]
	end,
	doJump = function (e)
		e.jump = false
		e.setState(e, "jump")
		for i=1, 12 do
			local d = 15 + i*5
			local l = e.lillyAt(e, e.x + math.sin(e.r)*d, e.y - math.cos(e.r)*d)
			if l and l ~= e.lilly then
				--e.lilly.destroy = true
				e.jumpNormal(e, l, d / 60)
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
		e.lilly.setSpeed(e.lilly, math.pi + e.r, d)
		A(d, function (v)
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
		e.jumpNormal(e, nil, 1, function ()
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
		if e.state == "ready" then
			if e.jump then
				e.doJump(e)
			end
			e.r = e.lilly.r - e.rd
			e.x = e.lilly.x
			e.y = e.lilly.y
		end
	end,
}

local Flower = {
	name = "flower",
	parents = "2d",
	image = lillyImg,
	quad = lg.newQuad(16, 0, 8, 8, lillyImg:getDimensions()),
}

function Flower:init(lilly)
	local d = math.random() * 0.1
	self.color = {1, 1 - d - math.random() * 0.1, 1 - d, 0}
	self.s = 0
	local s = 1 + math.random()
	A(1, function (v)
		self.color[4] = v
		self.s = s * v
	end, function ()
		self.color[4] = nil
		self.s = s * v
	end)
	self.lilly = lilly
	self:updatePos()
end

function Flower:system(msg)
	self:updatePos()
	for _, o in ipairs(msg.landedOn or {}) do
		if o == self.lilly then
			self.destroy = true
			fkge.message("score", "flowerTaken", 1)
		end
	end
end

function Flower:updatePos()
	local l = self.lilly
	self.x = l.x
	self.y = l.y
	self.r = l.r
end

C(Flower)

local scoreImg = lg.newImage("score.png")
local sw, sh = scoreImg:getDimensions()
local scoreQuads = {}
for i=1, 10 do
	local ii = i - 1
	local sx = ii % 4
	local sy = math.floor(ii / 4)
	scoreQuads[i] = lg.newQuad(sx*16, sy*16, 16, 16, sw, sh)
end
local Score = {
	name = "score",
	parents = "2d",
	value = 0,
	w = 16,
	h = 16,
	image = scoreImg,
	quad = scoreQuads[1],
}

function Score:system(msg)
	for _, s in ipairs(msg.flowerTaken or {}) do
		self.value = self.value + s
	end
	self.placeOver = true
end

function Score:draw()
	local o = love.window.getDisplayOrientation and love.window.getDisplayOrientation()
	o = (o == "portrait" or o == "portraitflipped")
	local v = self.value
	local x = 0
	while v >= 10 do
		self:drawDigit(v%10, x, o)
		v = math.floor(v/10)
		x = x + 1
	end
	self:drawDigit(v, x, o)
end

function Score:drawDigit(n, x, o)
	lg.push()
	lg.translate(-x*16, 0)
	if o then
		lg.translate(16, 16)
		lg.rotate(-math.pi/2)
		lg.translate(0, -16)
	end
	lg.draw(scoreImg, scoreQuads[n+1], 0, 0)
	lg.pop()
end

C(Score)

local World = {
	name = "world",
}

function World:init()
	self.world = lp.newWorld()
	self:createBound(WIDTH/2, -16, WIDTH, 32)
	self:createBound(WIDTH/2, HEIGHT+16, WIDTH, 32)
	self:createBound(-16, HEIGHT/2, 32, HEIGHT+64)
	self:createBound(WIDTH+16, HEIGHT/2, 32, HEIGHT+64)
end

function World:createBound(x, y, w, h)
	local b = lp.newBody(fkge.find("world").world, x, y)
	local s = lp.newRectangleShape(w, h)
	lp.newFixture(b, s)
end

function World:system(msg, dt)
	if fkge.count("flower") < 3 then
		fkge.each("lilly", function (e)
			if math.random() < 0.1 and
			   not fkge.find("froggy", function (o)
							return o.lilly == e
						end) then
				E("flower", e)
			end
		end)
	end
	self.world:update(dt)
end
C(World)

S("game", function ()
	math.randomseed(os.time())
	E"world"
	for i=1, 32 do
		local f, x, y, s, n = true, 0, 0, 1, 0
		while f and n < 1000 do
			s = math.random() * 2 + 1
			local t = s * 8
			x, y = math.random() * (WIDTH - 2*t) + t, math.random() * (HEIGHT - 2*t) + t
			f = fkge.find("lilly", function (e)
				local dx, dy = math.abs(e.x - x), math.abs(e.y - y)
				if dx < 48 and dy < 48 and math.sqrt(dx*dx + dy*dy) < (e.s + s) * 8 then
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
	E("score").attr{
		x = WIDTH - 16,
		y = 16,
	}
end)

fkge.game{
	width = WIDTH,
	height = HEIGHT,
	background = {1/15, 2/15, 6/15}
}
S"game"
