require('joystick')
sti = require('sti')

local lg = love.graphics

function love.load()
  windowWidth  = lg.getWidth()
	windowHeight = lg.getHeight()

  package.cpath = package.cpath .. ';/Users/jiaaro/Library/Application Support/JetBrains/PyCharm2020.1/plugins/intellij-emmylua/classes/debugger/emmy/mac/?.dylib'
  local dbg = require('emmy_core')
  dbg.tcpListen('localhost', 9966)
  dbg.waitIDE()

  joysticks = love.joystick.getJoysticks()
  joystick = joysticks[1]

	-- Set world meter size (in pixels)
	love.physics.setMeter(16)

	-- Load a map exported to Lua from Tiled
	map = sti("assets/maps/map01.lua")

  -- Prepare physics world with horizontal and vertical gravity
	--world = love.physics.newWorld(0, 0)

	-- Prepare collision objects
	--map:box2d_init(world)
end

function love.update(dt)
  map:update(dt)
end

function love.keypressed(key)
  local os = love.system.getOS()
  local cmd;
  if os == "OS X" or os == "iOS" then
    cmd = love.keyboard.isDown("lgui", 'rgui')
  else
    cmd = love.keyboard.isDown('lctrl', 'rctrl')
  end

  if key == 'right' then
  elseif key == 'left' then
  elseif cmd and key == 'r' then
  end
end

function love.mousepressed(x, y)

end

function love.draw()
  map:draw()

  -- Draw Collision Map (useful for debugging)
	--love.graphics.setColor(1, 0, 0)
	--map:box2d_draw()


  --drawJoystickDebug()
end
