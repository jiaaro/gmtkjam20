local anim8 = require 'anim8'
local lg = love.graphics

local hugetilemap
local function getHUGE(x, y, w, h)
  hugetilemap = hugetilemap or lg.newImage('assets/images/s4m_ur4i_huge-assetpack-tilemap.png')
  hugetilemap:setFilter("nearest", "nearest")
  local quad = lg.newQuad(x, y, w, h, hugetilemap:getDimensions())
  return {
    draw=function(self, x, y)
      lg.draw(hugetilemap, quad, math.floor(x), math.floor(y))
    end
  }
end

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
  skeleton = getHUGE(28*8, 16*8, 3*8, 2*8)
}
