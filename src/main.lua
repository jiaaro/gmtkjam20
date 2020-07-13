require('joystick')
anim8 = require('anim8')
sti = require('sti')
bump = require('bump')
lume = require("lume")
sprites = require('sprites')
hexcolor = require('hexcolor')

projectile = require('projectile')
Gun = require('gun')

DEBUG = false

PX_PER_METER = 16
PLAYER_SPEED = 8 * PX_PER_METER
PLAYER_ON_LADDER_SPEED = 4 * PX_PER_METER
JUMP_HEIGHT = 20 * PX_PER_METER
MIN_DEAD_TIME = 1 -- seconds
DEATH_POSSIBLE = true

camera = {
  zoom = 1,
  x = 0,
  y = 0,
}

BLOCK = 8 -- pixels

local lg = love.graphics
animation = nil
local proj = {x = 0, y = 0, active = false}

movementVector = {x = 0, y = 0}
local keyboard_controls_map = {
  [LEFT] = {'left', 'a'},
  [RIGHT] = {'right', 'd'},
  [UP] = {'up', 'w'},
  [DOWN] = {'down', 's'}
}
local gamePadAxis_map = {
  [LEFT] = {'leftx', -0.75},
  [RIGHT] = {'leftx', 0.75},
  [UP] = {'lefty', -0.75},
  [DOWN] = {'lefty', 0.75}
}
function playerIsMoving(dir)
  if dir == LEFT or dir == UP then
    return joystick and (joystick:isDown(dir) or joystick:getGamepadAxis(gamePadAxis_map[dir][1]) < gamePadAxis_map[dir][2]) or love.keyboard.isDown(keyboard_controls_map[dir][1], keyboard_controls_map[dir][2])
  else
    return joystick and (joystick:isDown(dir) or joystick:getGamepadAxis(gamePadAxis_map[dir][1]) > gamePadAxis_map[dir][2]) or love.keyboard.isDown(keyboard_controls_map[dir][1], keyboard_controls_map[dir][2])
  end
end

function getInputVector()
  local x = joystick:getGamepadAxis('leftx')
  local y = joystick:getGamepadAxis('lefty')
  if x > 0.1 or x < -0.1 and y >0.1 or y < -0.1 then
    return {x = x, y = y}
  end

  left = playerIsMoving(LEFT) and -1 or 0
  right = playerIsMoving(RIGHT) and 1 or 0
  up = playerIsMoving(UP) and -1 or 0
  down = playerIsMoving(DOWN) and 1 or 0
  return {x = left+right, y = up+down}
end

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

function love.load(args)
  -- time in level
  t = 0

  lg.setDefaultFilter('nearest', 'nearest')
  youdiedfont = lg.newFont(54, 'mono', .25)

  windowWidth  = lg.getWidth()
	windowHeight = lg.getHeight()

  if args and args[#args] == '-debug' then
    DEBUG = true
    local dbg = require('emmy_core')
    dbg.tcpListen('localhost', 9966)
    dbg.waitIDE()
  end

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
  player.is_dead = false
  player.speed = PLAYER_SPEED
  player.jump_height = JUMP_HEIGHT
  player.direction = 1
  player.velocity = {x=0, y=0}
  player.can_jump = true
  player.x = 2*BLOCK
  player.y = 2*BLOCK

  local proj = {x = 0, y = 0, active = false}
  gun = Gun()
  function player:draw()
    local x, y
    for _, batch in pairs(self.batches) do
      x, y = self.x, self.y
      x = x + self.renderoffsetx
      y = y + self.renderoffsety
      if self.direction == -1 then
        x = x + 12
      end
      -- draw hitbox for debugging
      --lg.rectangle('fill', math.floor(self.x), math.floor(self.y), self.w, self.h)

      lg.draw(batch, math.floor(x), math.floor(y), 0, player.direction, 1)
    end
  end
  function player:jump()
    if DEATH_POSSIBLE and player.is_dead and t - player.death_time > MIN_DEAD_TIME then
      love.load()
      return
    end

    if not self.can_jump then
      return
    end
    self.velocity.y = -1 * JUMP_HEIGHT
    self.can_jump = false
  end

  player.w = 8
  player.h = 2*BLOCK -3
  player.renderoffsetx = -2
  player.renderoffsety = -3
  world:add(player, 2*BLOCK, 0, player.w, player.h)
  gun.state = READY

  -- Prepare collision objects
	map:bump_init(world)

  bat_image = lg.newImage("assets/images/animations/noBKG_BatFlight_strip.png")
  animation = {
    spriteSheet = bat_image,
    quads = {},
    duration = 1,
    currentTime = 0
  }

  if DEBUG then
    player.x, player.y = 450, 411
    world:update(player, player.x, player.y)
  end

  function map.layers.skeletons:update(dt)
    local x, y
    for _, obj in ipairs(self.objects) do
      x, y = self.x + obj.x, self.y + obj.y
      world:update(obj, x, y)
    end
  end
  function map.layers.skeletons:draw()
    local x, y
    for _, obj in ipairs(self.objects) do
      x, y = self.x + obj.x, self.y + obj.y
      --lg.rectangle('fill', x, y, obj.width, obj.height)
      sprites.skeleton:draw(x, y)
    end
  end
  for _, obj in ipairs(map.layers.skeletons.objects) do
    obj.collision_type = 'cross'
    world:add(obj, obj.x, obj.y, obj.width, obj.height)
  end

  for x = 0, bat_image:getWidth() - 64, 64 do
      table.insert(animation.quads, lg.newQuad(x, 0, 64, 64, bat_image:getDimensions()))
  end
end

local function playerFilter(playeritem, other)
  if other.collision_type then
    return other.collision_type
  end
  return (other.layer and other.layer.properties.collision) or 'slide'
end


function love.update(dt)
  -- total game time
  t = t + dt
  if DEATH_POSSIBLE and player.is_dead then
    return
  end

  map.layers.skeletons.x = math.sin(t) * BLOCK * 3

  local _, _, currentlyTouching, ctlen = world:check(player, player.x, player.y, playerFilter)
  local touchingLadder = false
  for i = 1, ctlen do
    local layer = currentlyTouching[i].other.layer
    if currentlyTouching[i].overlaps and layer and layer.name == 'ladder' then
      touchingLadder = true
      player.velocity.x = 0
      player.velocity.y = math.max(0, player.velocity.y * .1)
      player.can_jump = true
    elseif not player.is_dead and currentlyTouching[i].overlaps and layer and layer.name == 'hazards' then
      player.is_dead = true
      player.death_time = t
      return
    elseif not player.is_dead and currentlyTouching[i].overlaps and layer and layer.properties.object_type == 'enemy' then
      player.is_dead = true
      player.death_time = t
      return
    end
    if cols[i].other.gun_type == GUN_TYPE.BAT  then
      moving_platform_vel = cols[i].other.velocity
    end
  end

  if joystick and (joystick:isDown(BUTTON.SQUARE) or love.keyboard.isDown('j')) and (gun.state == READY or gun.state == AIMING) then
    gun.state = AIMING
    proj = gun:getNext()
    movementVector = getInputVector()
    pathline = {player.x + 0.5*player.w, player.y + 0.5*player.h, player.x + 0.5*player.w + 100*(movementVector.x), player.y + 0.5*player.h + 100*(movementVector.y)}
  else
    if gun.state == AIMING then
      gun.state = FIRING
    else
    end
    if playerIsMoving(LEFT) then
      player.velocity.x = math.max(-PLAYER_SPEED, player.velocity.x - (PLAYER_SPEED * .3))
      player.direction = -1
    elseif playerIsMoving(RIGHT) then
      player.velocity.x = math.min(PLAYER_SPEED, player.velocity.x + (PLAYER_SPEED * .3))
      player.direction = 1
    elseif playerIsMoving(UP) then
      if touchingLadder then
        player.velocity.y = -PLAYER_ON_LADDER_SPEED
        if joystick:isGamepadDown("a") then
          player:jump()
        end
      end

    elseif playerIsMoving(DOWN) then
      if touchingLadder then
        player.velocity.y = PLAYER_ON_LADDER_SPEED
      end
    end
  end

  if not touchingLadder then
    player.velocity.y = player.velocity.y + PX_PER_METER
  end

  if moving_platform_vel then
    print(player.velocity.x)
    player.velocity.x = player.velocity.x + moving_platform_vel.x
    print(player.velocity.x)
  end

  player.x, player.y, cols, len = world:move(
      player,
      lume.clamp(lume.round(player.x + player.velocity.x * dt), 0, map_width - player.w),
      lume.clamp(lume.round(player.y + player.velocity.y * dt), -8 * BLOCK, map_height - player.h),
      playerFilter
  )

  for i = 1, len do
    if cols[i].type == 'slide' and cols[i].touch.y > 0 then
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
  if gun.state == FIRING then
    local arrow_size = 5
    local x = 0
    if player.direction < 0 then
      x = player.x - arrow_size
    else
      x = player.x + player.w
    end
    movementVector = getInputVector()
    proj:start(x, player.y + 0.25*player.h - proj.h)
    gun.state = RESOLVING
  end
  if proj and proj.active and world:hasItem(proj) then
    proj:update(dt)
  end
  gun:update(dt)


  map:update(dt)

  local viewport_w = windowWidth / camera.scale
  local viewport_h = windowHeight / camera.scale
  camera.x = lume.round(lume.clamp(player.x - .5 * viewport_w, 0, map_width - viewport_w))
  camera.y = lume.round(lume.clamp(player.y - .7 * viewport_h, 0, map_height - viewport_h))

  -- -- whiskers = {
  -- if player.direction > 0 then
  --   items, len = world:querySegmentWithCoords(
  --     player.x + 2*BLOCK,
  --     player.y + 0.5*BLOCK,
  --     player.x + 2*BLOCK + player.direction*100*BLOCK,
  --     player.y + 0.5*BLOCK
  --   )
  -- else
  --   items, len = world:querySegmentWithCoords(
  --     player.x,
  --     player.y + 0.5*BLOCK,
  --     player.x + 2*BLOCK + player.direction*100*BLOCK,
  --     player.y + 0.5*BLOCK
  --   )
  -- end
  -- if len > 0 then
  --   pathline = {player.x, player.y + 0.5*BLOCK, items[1].x1, items[1].y1}
  -- else
  --   pathline = {player.x, player.y + 0.5*BLOCK, player.x + player.direction*100*BLOCK, player.y + 0.5*BLOCK}
  -- end

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
  elseif DEBUG and cmd and key == 'd' then
    DEATH_POSSIBLE = not DEATH_POSSIBLE
  elseif love.keyboard.isDown("lshift", 'rshift') and cmd and key == 'r' then
    player.is_dead = false
    player.death_time = nil
  elseif cmd and key == 'r' then
    love.load()
  elseif key == 'v' then
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

    if DEBUG and vel_lines then
      lg.setColor(1, 0, 0, 0.3)
      lg.line(player.x, player.y, player.x + player.velocity.x, player.y)
      lg.setColor(0, 1, 0, 0.3)
      lg.line(player.x, player.y, player.x, player.y + player.velocity.y)
      lg.setColor(0, 0, 1, 0.3)
      lg.line(player.x, player.y, player.x + player.velocity.x, player.y + player.velocity.y)
    end

    if DEBUG and pathline then
      lg.setColor(255, 255, 51, 0.8)
      lg.line(pathline[1], pathline[2], pathline[3], pathline[4])
      lg.setColor(0, 0, 1, 0.4)
      lg.circle('fill', pathline[3], pathline[4], 40)
    end

    if proj.active then
      proj:draw()
    end

    -- draw bat animation
    local sprite_num = math.floor(animation.currentTime / animation.duration * #animation.quads) + 1
    lg.draw(animation.spriteSheet, animation.quads[sprite_num], proj.x - 25, proj.y -30)
  lg.pop()

    gun:draw()

  -- debugging
  if DEBUG then
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
  end

  -- drawJoystickDebug()
  if player.is_dead then
    lg.setColor(unpack(hexcolor("f9d68f")))
    local message = "YOU DIED"
    if t - player.death_time > MIN_DEAD_TIME then
      message = 'continue?'
    end
    lg.printf(
        message,
        youdiedfont,
        0, windowHeight * .25,
        windowWidth, 'center'
    )
  end

end

