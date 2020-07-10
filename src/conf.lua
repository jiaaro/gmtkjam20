
function love.conf(t)
  t.version = "11.3"
  t.identity = "lctrl"
  t.window.title = "lctrl"

  -- Mac
  t.window.width = 800
  t.window.height = 480
  t.window.resizable = false

  --t.window.resizable = true
  t.window.msaa = 4
  t.window.highdpi = true
end
