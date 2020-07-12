local Object = require("classic")
local lg = love.graphics
Gun = Object.extend(Object)

-- states
READY, AIMING, FIRING, RESOLVING, COOLDOWN = 1, 2, 3, 4, 5

-- gun types
GUN_TYPE = {
  BASIC = 1,
  REVERS = 2,
  TELE = 3,
  BAT = 4,
  BACK = 5,
  BLOCK = 6
}

function Gun:new()
  self.arrows = {
    [GUN_TYPE.BASIC] = Projectile(-69, -69),
    [GUN_TYPE.BAT] = Projectile(-69, -69, GUN_TYPE.BAT)
  }
  self.state = READY
  self.currentArrow = GUN_TYPE.BASIC
  self.nextArrow = GUN_TYPE.BASIC
end

function Gun:getNext()
  return self.arrows[GUN_TYPE.BAT]
end

function Gun:update(dt)
  if self.state == RESOLVING then
    self.cooldown = 1
    self.state = COOLDOWN
  end
  if self.state == COOLDOWN then
    self.cooldown = self.cooldown - dt
    if self.cooldown <= 0 then
      self.state = READY
    end
  end
end

function Gun:draw()
  if self.state == READY then
    lg.setColor(0, 169, 0, 1)
    lg.rectangle("fill", 20, 20, 10, 10)
  end
end

return Gun
