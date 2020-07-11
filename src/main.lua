require('joystick')
anim8 = require 'anim8'
sti = require('sti')

PX_PER_METER = 16
PLAYER_SPEED = 5 * PX_PER_METER
JUMP_HEIGHT = 2 * PX_PER_METER


local lg = love.graphics

function getMapObjectByName(object_name)
	for k, object in pairs(_G.map.objects) do
		if object.name == object_name then
			return object
		end
	end
end

function getMapLayerByName(object_name)
	for k, object in pairs(_G.map.layers) do
		if k == object_name then
			return object
		end
	end
end

function love.load()
  windowWidth  = lg.getWidth()
	windowHeight = lg.getHeight()

  package.cpath = package.cpath .. ';/Users/jiaaro/Library/Application Support/JetBrains/PyCharm2020.1/plugins/intellij-emmylua/classes/debugger/emmy/mac/?.dylib'
  local dbg = require('emmy_core')
  dbg.tcpListen('localhost', 9966)
  --dbg.waitIDE()

  joysticks = love.joystick.getJoysticks()
  joystick = joysticks[1]

	-- Set world meter size (in pixels)
	love.physics.setMeter(16)

	-- Load a map exported to Lua from Tiled
	map = sti("assets/maps/map01.lua")
  --spritesheet = lg.newImage('assets/images/s4m_ur4i_huge-assetpack-characters.png')

  -- Prepare physics world with horizontal and vertical gravity
	world = love.physics.newWorld(0, 0)
  playerlayer = getMapLayerByName('Player')
  player = getMapObjectByName("Player")
  player.speed = PLAYER_SPEED
  player.jump_height = JUMP_HEIGHT
	-- Prepare collision objects
	--map:box2d_init(world)
end

function love.update(dt)
  if joystick:isDown(LEFT) then
    player.x = player.x - player.speed * dt
  elseif joystick:isDown(RIGHT) then
    player.x = player.x + player.speed * dt
  end

  map:update(dt)

  playerlayer.x = player.x
  playerlayer.y = player.y
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
