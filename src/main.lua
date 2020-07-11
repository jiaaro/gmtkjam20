require('joystick')
anim8 = require('anim8')
sti = require('sti')
bump = require('bump')
lume = require("lume")

projectile = require('projectile')

PX_PER_METER = 16
PLAYER_SPEED = 8 * PX_PER_METER
JUMP_HEIGHT = 20 * PX_PER_METER

camera = {
  zoom = 1,
  x = 0,
  y = 0,
}

BLOCK = 8 -- pixels

local lg = love.graphics
local animation = nil
local proj = nil

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

  lg.setDefaultFilter('nearest', 'nearest')

  windowWidth  = lg.getWidth()
	windowHeight = lg.getHeight()

  local dbg = require('emmy_core')
  dbg.tcpListen('localhost', 9966)
  --dbg.waitIDE()

  joysticks = love.joystick.getJoysticks()
  joystick = joysticks[1]

	-- Load a map exported to Lua from Tiled
	map = sti("assets/maps/map01.lua", { 'bump' })
  map_width, map_height = map.width * map.tilewidth, map.height * map.tileheight
  camera.scale = math.min(
      map_width / (16 * (2*BLOCK)),
      map_height / (9 * (2*BLOCK))
  )

  -- Prepare physics world with horizontal and vertical gravity
	world = bump.newWorld(2 * BLOCK)
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

  player.w = 2*BLOCK
  player.h = 2*BLOCK
  world:add(player, 0, 0, player.w, player.h)

  -- add bullets to map
  projectiles_layer = map:addCustomLayer("projectiles")
  projectiles_layer.proj = {
    sprite = lg.circle('fill', 0, 0, 10),
    x = 0,
    y = 0,
    ox = 10,
    oy = 10
  }


  -- Prepare collision objects
	map:bump_init(world)

  proj = Projectile(0, 0, 0, 0)

  bat_image = lg.newImage("assets/images/animations/noBKG_BatFlight_strip.png")
  animation = {
    spriteSheet = bat_image,
    quads = {},
    duration = 1,
    currentTime = 0
  }

  for x = 0, bat_image:getWidth() - 64, 64 do
      table.insert(animation.quads, lg.newQuad(x, 0, 64, 64, bat_image:getDimensions()))
  end


end

function love.update(dt)
  if joystick and (joystick:isDown(LEFT) or joystick:getGamepadAxis("leftx") < -0.1) or love.keyboard.isDown('left', 'a') then
    player.velocity.x = math.max(-PLAYER_SPEED, player.velocity.x - (PLAYER_SPEED * .3))
    player.direction = -1
  elseif joystick and (joystick:isDown(RIGHT) or joystick:getGamepadAxis("leftx") > 0.1) or love.keyboard.isDown('right', 'd') then
    player.velocity.x = math.min(PLAYER_SPEED, player.velocity.x + (PLAYER_SPEED * .3))
    player.direction = 1
  end

  player.velocity.y = player.velocity.y + PX_PER_METER

  player.x, player.y, cols, len = world:move(
      player,
      lume.clamp(lume.round(player.x + player.velocity.x * dt), 0, map_width - player.w),
      lume.clamp(lume.round(player.y + player.velocity.y * dt), -8 * BLOCK, map_height - player.h)
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

  player.velocity.x = player.velocity.x * .95

  -- do parallax
  for i, layer in pairs(map.layers) do
    if layer.properties.parallax then
      local parallax = layer.properties.parallax or 1.0
      layer.x = lume.round((1 - parallax) * camera.x)
      layer.y = lume.round((1 - parallax) * camera.y)
    end
  end


  -- bullet update
  if player.isShooting then
    proj:start(player.x, player.y, 200 * player.direction, 0)
    player.isShooting = false
  end
  proj:update(dt)


  map:update(dt)

  local viewport_w = windowWidth / camera.scale
  local viewport_h = windowHeight / camera.scale
  camera.x = lume.round(lume.clamp(player.x - .5 * viewport_w, 0, map_width - viewport_w))
  camera.y = lume.round(lume.clamp(player.y - .7 * viewport_h, 0, map_height - viewport_h))

  -- whiskers = {
  if player.direction > 0 then
    items, len = world:querySegmentWithCoords(
      player.x + 2*BLOCK,
      player.y + 0.5*BLOCK,
      player.x + 2*BLOCK + player.direction*100*BLOCK,
      player.y + 0.5*BLOCK
    )
  else
    items, len = world:querySegmentWithCoords(
      player.x,
      player.y + 0.5*BLOCK,
      player.x + 2*BLOCK + player.direction*100*BLOCK,
      player.y + 0.5*BLOCK
    )
  end
  if len > 0 then
    pathline = {player.x, player.y + 0.5*BLOCK, items[1].x1, items[1].y1}
  else
    pathline = {player.x, player.y + 0.5*BLOCK, player.x + player.direction*100*BLOCK, player.y + 0.5*BLOCK}
  end

  -- update bat_image animation
  animation.currentTime = animation.currentTime + dt
  if animation.currentTime >= animation.duration then
    animation.currentTime = animation.currentTime - animation.duration
  end

end

function love.gamepadpressed(js, button)
  if js:getGUID() ~= joystick:getGUID() then
    return
  end

  if button == 'a' then
    player:jump()
  end

  if button == 'x' then
    player.isShooting = true
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
    love.load()
  end

  if key == 'v' then
    vel_lines = not vel_lines
  end
end

function love.mousepressed(x, y)
end

function love.draw()
  lg.setColor(1, 1, 1)

  map:draw(-camera.x, -camera.y, camera.scale, camera.scale)

  -- Draw Collision Map (useful for debugging)
  lg.setColor(1, 0, 0, 0.5)
  --map:bump_draw(world, -camera.x, -camera.y, camera.scale, camera.scale)

  lg.push()
    lg.scale(camera.scale)
    lg.translate(-camera.x, -camera.y)

    if vel_lines then
      lg.setColor(1, 0, 0, 0.3)
      lg.line(player.x, player.y, player.x + player.velocity.x, player.y)
      lg.setColor(0, 1, 0, 0.3)
      lg.line(player.x, player.y, player.x, player.y + player.velocity.y)
      lg.setColor(0, 0, 1, 0.3)
      lg.line(player.x, player.y, player.x + player.velocity.x, player.y + player.velocity.y)
    end

    if pathline then
      lg.setColor(255, 255, 51, 0.8)
      lg.line(pathline[1], pathline[2], pathline[3], pathline[4])
      lg.setColor(0, 0, 1, 0.4)
      lg.circle('fill', pathline[3], pathline[4], 40)
    end

    if proj then
      proj:draw()
    end

    -- draw bat animation
    local sprite_num = math.floor(animation.currentTime / animation.duration * #animation.quads) + 1
    lg.draw(animation.spriteSheet, animation.quads[sprite_num])
  lg.pop()

  -- debugging
  lg.setColor(1, 1, 1)
  local x,y,w,h = world:getRect(player)
  lg.print(string.format([[
    player: (%0.2f, %0.2f)
    player vel: (%0.2f, %0.2f)
    player rect: (%0.2f, %0.2f) - %0.2f x %0.2f
    proj: (%0.2f, %0.2f)
  ]],
  player.x, player.y,
  player.velocity.x, player.velocity.y,
  x, y, w, h,
  proj.x, proj.y),
  0, 0)

  -- drawJoystickDebug()

end

