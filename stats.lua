-- stats.lua

-- Function to round to the nearest integer
local function round(num)
    return math.floor(num + 0.5)
end

-- Function to round to a specific number of decimal places
local function roundToDecimalPlaces(num, places)
    local mult = 10^(places or 0)
    return math.floor(num * mult + 0.5) / mult
end

function draw_vector_visualizer(vector, scale, origin_x, origin_y, color)
    local readout_size = 5
    local num_vectors = #vector
    local x_pos = origin_x
    local v_pos = origin_y + math.floor(readout_size / 2);
    
    -- Draw the circular base
    circ(x_pos, v_pos, readout_size, color) -- Draw a circle with radius 16 units

    -- Draw each vector
    for i = 1, num_vectors do
        local angle = (i - 1) * (2 * math.pi / num_vectors)
        local magnitude = vector[i] * scale
        local end_x = x_pos + magnitude * math.cos(angle)
        local end_y = v_pos + magnitude * math.sin(angle)
        
        -- Draw the vector line
        line(x_pos, v_pos, end_x, end_y, color) -- Using color index 8 for the vector lines
    end
end


function draw_stats(boat, push_force, lift_mag, orientation)
    local stats_x = boat.pos.x - 240
    local stats_y = boat.pos.y - 135

    -- If you want to round to 2 decimal places, for example:
    print("push_force "..roundToDecimalPlaces(mag(push_force), 3), stats_x, stats_y, 9)
    print("pull_force "..roundToDecimalPlaces(lift_mag, 3), stats_x, stats_y + 10, 8)
    print("sheet "..roundToDecimalPlaces(boat.sheet, 3), stats_x, stats_y + 20, 10)
    print("sail "..roundToDecimalPlaces(boat.sail, 3), stats_x, stats_y + 30, 11)
    print("rudder "..roundToDecimalPlaces(boat.rudder, 3), stats_x, stats_y + 40, 12)
    print("orientation "..roundToDecimalPlaces(orientation.x, 3)..", "..roundToDecimalPlaces(orientation.y, 2), stats_x, stats_y + 50)
    draw_vector_visualizer(orientation, 1, stats_x + 20, stats_y + 60, 7)
   -- print("wind "..roundToDecimalPlaces(wind.x, 3)..", "..roundToDecimalPlaces(wind.y, 3), stats_x, stats_y + 60)
end
