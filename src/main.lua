require('joystick')
anim8 = require('anim8')
sti = require('sti')
bump = require('bump')

PX_PER_METER = 16
PLAYER_SPEED = 8 * PX_PER_METER
JUMP_HEIGHT = 2 * PX_PER_METER * 10

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

  local dbg = require('emmy_core')
  dbg.tcpListen('localhost', 9966)
  --dbg.waitIDE()

  joysticks = love.joystick.getJoysticks()
  joystick = joysticks[1]

	-- Load a map exported to Lua from Tiled
	map = sti("assets/maps/map01.lua", { 'bump' })
  --spritesheet = lg.newImage('assets/images/s4m_ur4i_huge-assetpack-characters.png')

  -- Prepare physics world with horizontal and vertical gravity
	world = bump.newWorld(16)
  player = getMapLayerByName('Player')
  player.speed = PLAYER_SPEED
  player.jump_height = JUMP_HEIGHT
  player.direction = 0
  player.velocity = {x=0, y=0}
  player.can_jump = true
  function player:jump()
    if not self.can_jump then
      return
    end
    self.velocity.y = -1 * JUMP_HEIGHT
    self.can_jump = false
  end

  world:add(player, 0, 0, 3*8, 4*8)

  -- Prepare collision objects
	map:bump_init(world)
end

function love.update(dt)
  if joystick and (joystick:isDown(LEFT) or joystick:getGamepadAxis("leftx") < -0.1) or love.keyboard.isDown('left', 'a') then
    player.velocity.x = math.max(-PLAYER_SPEED, player.velocity.x - (PLAYER_SPEED * .3))
  elseif joystick and (joystick:isDown(RIGHT) or joystick:getGamepadAxis("leftx") > 0.1) or love.keyboard.isDown('right', 'd') then
    player.velocity.x = math.min(PLAYER_SPEED, player.velocity.x + (PLAYER_SPEED * .3))
  end


  player.velocity.y = player.velocity.y + PX_PER_METER
  player.x, player.y, cols, len = world:move(
      player,
      player.x + player.velocity.x * dt,
      player.y + player.velocity.y * dt
  )

  for i = 1, len do
    if cols[i].touch.y > 0 then
      player.can_jump = true
      if player.velocity.y > 0 then
        player.velocity.y = 0
      end
      player.velocity.x = player.velocity.x * .7
    end
  end
  map:update(dt)


  -- bullet stuff?
  items, len = world:querySegmentWithCoords(player.x, player.y +2, player.x + player.velocity.x*1000, player.y +2)
  for i, thing in ipairs(items) do
    print(i, thing)
    print(thing.x1, thing.y2)
  end
  if len > 0 then
    pathline = {items[1].x1, items[1].y1, items[1].x2, items[1].y2}
  else
    pathline = nil
  end
end

function love.gamepadpressed(js, button)
  if js:getGUID() ~= joystick:getGUID() then
    return
  end

  if button == 'a' then
    player:jump()
  end
end

function love.keypressed(key)
  local os = love.system.getOS()
  local cmd;
  if os == "OS X" or os == "iOS" then
    cmd = love.keyboard.isDown("lgui", 'rgui')
  else
    cmd = love.keyboard.isDown('lctrl', 'rctrl')
  end

  if key == 'space' then
    player:jump()
  elseif key == 'right' then
  elseif key == 'left' then
  elseif cmd and key == 'r' then
  end

  if key == 'v' then
    vel_lines = not vel_lines
  end
end

function love.mousepressed(x, y)
end

function love.draw()
  lg.setColor(1, 1, 1)
  map:draw()

  -- Draw Collision Map (useful for debugging)
	lg.push()
    lg.setColor(1, 0, 0, 0.5)
    map:bump_draw(world)
  lg.pop()


  if vel_lines then
    love.graphics.setColor(1, 0, 0, 0.3)
    love.graphics.line(player.x, player.y, player.x + player.velocity.x, player.y)
    love.graphics.setColor(0, 1, 0, 0.3)
    love.graphics.line(player.x, player.y, player.x, player.y + player.velocity.y)
    love.graphics.setColor(0, 0, 1, 0.3)
    love.graphics.line(player.x, player.y, player.x + player.velocity.x, player.y + player.velocity.y)
  end

  --lg.setColor(1, 1, 1)
  --drawJoystickDebug()

  if pathline then
    love.graphics.setColor(255, 255, 51, 0.6)
    love.graphics.line(player.x, player.y, pathline[1], pathline[2])
    love.graphics.setColor(0, 0, 1, 0.4)
    love.graphics.circle('fill', pathline[1], pathline[2], 40)
  end
end


function ray(originX, originY, direction)
  love.graphics.line(originX, originY, originX + direction*6, originY)
end
