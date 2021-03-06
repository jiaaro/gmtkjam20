local Object = require("classic")
Projectile = Object.extend(Object)
local lg = love.graphics

local offscreen = {x = -69, y = -69}

function Projectile:new(x, y, gun_type)
  if gun_type == nil then
    self.gun_type = GUN_TYPE.BASIC
  end
  self.gun_type = gun_type
  self.collision_type = "cross"
  self.x = x
  self.y = y
  self.w = 1
  self.h = 1
  self.active = false
  self.velocity = {x = 0, y = 0}
  self.cols = {}
  self.ttl = 1
  if gun_type == GUN_TYPE.BASIC then
    self.w = 2
    self.h = 1
  elseif gun_type == GUN_TYPE.BAT then
    self.collision_type = "slide"
    self.w = 24
    self.h = 3
    self.ttl = 100
    self.velocity = {x = 8*BLOCK, y = 0}
  end
  world:add(self, self.x, self.y, self.w, self.h)
end

local function batProjectileFilter(item, other)
  if other ~= player then
    return 'cross'
  end
  return 'slide'
end

function Projectile:update(dt)
  if self.active and self.ttl > 0 then
    self.x, self.y, self.cols = world:move(
      self,
      self.x + self.velocity.x * dt,
      self.y + self.velocity.y * dt,
      batProjectileFilter
    )
    self.ttl = self.ttl - dt
    if #self.cols > 0 then
      if self.cols[1] then
        -- print(self.cols[1])

      end
    end
  else
    self.active = false
    world:update(self, offscreen.x, offscreen.y)
    self.x = offscreen.x
    self.y = offscreen.y
    self.velocity = {x = 0, y = 0}
  end
end

function Projectile:draw()
  if self.active then
    lg.setColor(1, 1, 1, 1)
    -- lg.circle('fill', self.x, self.y, self.w)
    -- local sprite_num = math.floor(animation.currentTime / animation.duration * #animation.quads) + 1
    -- lg.draw(animation.spriteSheet, animation.quads[sprite_num])
  end
end

function Projectile:start(startX, startY)
  world:update(self, startX, startY)
  self.x = startX
  self.y = startY
  self.active = true
end

return Projectile
