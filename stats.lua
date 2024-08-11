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
    local y_pos = origin_y + math.floor(readout_size / 2)
    
    -- Draw the circular base
    circ(x_pos, y_pos, readout_size, color) -- Draw a circle with radius 5 units

    -- Draw each vector
    for i = 1, num_vectors do
        local angle = (i - 1) * (2 * math.pi / num_vectors)
        local magnitude = vector[i] * scale
        local end_x = magnitude * math.cos(angle)
        local end_y = magnitude * math.sin(angle)
        
        -- Create the vector to be shown
        local v = vec(end_x, end_y)

        -- Debugging prints to verify vector values
        -- print("Vector " .. i .. ": (" .. x_pos .. ", " .. y_pos .. ") to (" .. end_x .. ", " .. end_y .. ") with magnitude " .. magnitude)
        
        -- Draw the vector using the show function
        show(v, x_pos, y_pos, color)
    end
end


function draw_stats(boat, push_force, lift_mag, orientation, wind_at_player, thrust, pull_force, apparent)
    local stats_x = boat.pos.x - 240
    local stats_y = boat.pos.y - 135
    local line_height = 10
    local visualizer_offset_x = 70
    local visualizer_scale = 2

    -- Print and visualize each stat
    local function draw_stat(label, value, y_offset, color)
        print(label .. " " .. roundToDecimalPlaces(value, 3), stats_x, stats_y + y_offset, color)
    end

    local function draw_vector_stat(label, vector, y_offset, color)
        print(label, stats_x, stats_y + y_offset, color)
        local scaled_vector = scale(visualizer_scale, vector)
        show(scaled_vector, stats_x + visualizer_offset_x, stats_y + y_offset + 5, color)
    end

    -- Display scalar stats
    draw_stat("push_force", mag(push_force), 0, 9)
    draw_stat("pull_force", lift_mag, line_height, 8)
    draw_stat("sheet", boat.sheet, 2 * line_height, 10)
    draw_stat("sail", boat.sail, 3 * line_height, 11)
    draw_stat("rudder", boat.rudder, 4 * line_height, 12)

    -- Display vector stats
    draw_vector_stat("orientation", orientation, 5 * line_height, 7)
    draw_vector_stat("wind", wind_at_player, 6 * line_height, 7)
    draw_vector_stat("thrust", thrust, 7 * line_height, 7)
    draw_vector_stat("pull_force", pull_force, 8 * line_height, 7)
    draw_vector_stat("push_force", push_force, 9 * line_height, 7)
    draw_vector_stat("apparent", apparent, 10 * line_height, 7)
end