function love.conf(t)
  t.identity = 'fkge-78-frogs'
  t.version = '11.1'
  t.accelerometerjoystick = false
  t.externalstorage = true
  t.gammacorrect = true

  local w = t.window
  w.title = "Frogs - MiniJam 79"
  w.icon = nil
  w.width = 720
  w.height = 480
  w.minwidth = 360
  w.minheight = 240
  w.resizable = true
  w.fullscreentype = 'desktop'
  w.fullscreen = false
  w.usedpiscale = false
  w.hidpi = true
end
