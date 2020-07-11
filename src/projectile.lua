local Object = require("classic")
Projectile = Object.extend(Object)

local lg = love.graphics

local offscreen = {x = -69, y = -69}

function Projectile:new(x, y, w, h)
  self.x = x
  self.y = y
  self.w = w
  self.h = h
  self.active = false
  self.velocity = {x = 0, y = 0}
  self.cols = {}
  self.ttl = 0
  world:add(self, 0, 0, 5, 5)
end

function Projectile:update(dt)
  if self.active and self.ttl > 0 then
    self.x, self.y, self.cols = world:move(
      self,
      self.x + self.velocity.x * dt,
      self.y + self.velocity.y * dt
    )
    self.ttl = self.ttl - dt
  else
    self.active = false
    world.udpate(self, offscreen.x, offscreen.y)
    self.x = offscreen.x
    self.y = offscreen.y
    self.velocity = {x = 0, y = 0}
  end
end

function Projectile:draw()
  if self.active then
    lg.setColor(1, 1, 1, 0.9)
    lg.circle('fill', self.x, self.y, 6)
  end
end

function Projectile:start(startX, startY, velocityX, velocityY)
  if self.active then
    return
  end
  world:update(self, startX, startY)
  self.x = startX
  self.y = startY
  self.velocity = {x = velocityX, y = velocityY}
  self.active = true
  self.ttl = 1
end

return Projectile
