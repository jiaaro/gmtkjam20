local Object = require("classic")
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
    [GUN_TYPE.BASIC] = Projectile(-69, -69, 0, 0),
    [GUN_TYPE.REVERS] = Projectile(-69, -69, 0, 0)
  }
  self.state = READY
  self.currentArrow = GUN_TYPE.BASIC
  self.nextArrow = GUN_TYPE.BASIC
end

function Gun:getNext()
  print(self.arrows)
  print(self.arrows[1])
  return self.arrows[GUN_TYPE.BASIC]
end

function Gun:draw()

end


return Gun
