return function(c)
  -- strip leading "#" or "0x" if necessary
  if c:sub(1, 1) == "#" then
    c = c:sub(2)
  elseif c:sub(1,2) == "0x" then
    c = c:sub(3)
  end

  local color = {}
  local color_width = (#c < 6) and 1 or 2
  local max_val = 16^color_width - 1
  for i = 1, #c, color_width do
    color[#color+1] = tonumber(c:sub(i, i+color_width-1), 16) / max_val
  end

  return color
end
