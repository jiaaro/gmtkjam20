local anim8 = require 'anim8'
local lg = love.graphics

local function getMedieval(name, ...)
  local seqs = {}
  for _, seq in ipairs({...}) do
    local img = lg.newImage(string.format('assets/images/animations/noBKG_%s%s_strip.png', name, seq))
    local grid = anim8.newGrid(64, 64, img:getWidth(), img:getHeight())
    seqs[seq] = anim8.newAnimation(grid(), 0.1)
  end
  return seqs
end

return {
  bat = getMedieval('Bat', "Flight", "Attack", "Death"),
}
