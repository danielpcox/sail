-- Improved Perlin noise function (you can replace this with any noise function)
function improved_noise(x, y)
  -- Implement or use an existing Perlin noise function
  -- This is a placeholder for the actual noise function with more variation
  return math.sin(x * 0.1) * math.cos(y * 0.1) + math.sin(x * 0.05) * math.cos(y * 0.05)
end

-- Function to generate and draw noise based on boat position
function draw_background(boat_x, boat_y, width, height, scale)
  local base_color = 1  -- Base color index
  local noise_color = 2 -- Alternate color index
  
  -- Fill the entire background with the base color
  rectfill(0, 0, width - 1, height - 1, base_color)
  
  -- Draw noise using rectangles with alternate color
  for y = 0, height - 1, 2 do
    for x = 0, width - 1, 2 do
      local noise_value = improved_noise((x + boat_x) * scale, (y + boat_y) * scale)
      if noise_value > 0 then
        rectfill(x, y, x + 1, y + 1, noise_color)
      end
    end
  end
end

-- Linear interpolation function
function lerp(color1, color2, t)
    return color1 * (1 - t) + color2 * t
end

