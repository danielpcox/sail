-- vector_field.lua
include "/sail/perlin.lua"

-- Initialize Perlin noise with a seed
local perlin = Perlin:new(1)

-- Gameplay and performance configuration
local base_grid_size = 40 -- Base grid size for the vector field
local high_res_grid_size = 20 -- High-resolution grid size around obstructions
local high_res_grid_radius = 50 -- Radius around obstructions for the high-resolution grid
local influence_radius = 100 -- Radius of influence of the boat on the wind

-- Function to vary the wind vector smoothly using Perlin noise
local function vary_wind(wind, wind_config, time)
    local noise_x = perlin:noise(time * wind_config.noise_frequency, 0) * 2 - 1
    local noise_y = perlin:noise(0, time * wind_config.noise_frequency) * 2 - 1

    local direction_variation_x = noise_x * wind_config.direction_variability
    local direction_variation_y = noise_y * wind_config.direction_variability

    local strength_variation = (perlin:noise(time * wind_config.noise_frequency, time * wind_config.noise_frequency) * 2 - 1) * wind_config.strength_variability

    wind.x = wind.x + direction_variation_x
    wind.y = wind.y + direction_variation_y
    wind.x = wind.x * (1 + strength_variation)
    wind.y = wind.y * (1 + strength_variation)
    return wind
end

-- Function to generate a vector field
function generate_vector_field(screen_width, screen_height, boats, barriers, wind_config, time)
    local vector_field = {}
    local half_screen_width = screen_width / 2
    local half_screen_height = screen_height / 2

    -- Function to apply scene influence on wind
    local function apply_scene_influence(wind)
        return vary_wind(wind, wind_config, time)
    end

    -- Function to adjust wind vector based on obstructions
    local function adjust_for_obstructions(pos, wind, boats, barriers)
        for _, boat in ipairs(boats) do
            local distance = mag(minus(pos, boat.pos))
            if distance < influence_radius then
                local influence_factor = (influence_radius - distance) / influence_radius
                wind = scale(1 - influence_factor, wind)
            end
        end
        for _, barrier in ipairs(barriers) do
            local distance = mag(minus(pos, barrier.pos))
            if distance < influence_radius then
                local influence_factor = (influence_radius - distance) / influence_radius
                wind = scale(1 - influence_factor, wind)
            end
        end
        return wind
    end

    -- Generate base grid
    for x = -half_screen_width, half_screen_width, base_grid_size do
        for y = -half_screen_height, half_screen_height, base_grid_size do
            local pos = vec(x, y)
            local wind = apply_scene_influence(vec(wind_config.base_direction.x * wind_config.base_strength, wind_config.base_direction.y * wind_config.base_strength))
            wind = adjust_for_obstructions(pos, wind, boats, barriers)
            table.insert(vector_field, {pos = pos, vector = wind})
        end
    end

    -- Generate high-resolution grid around obstructions
    for _, boat in ipairs(boats) do
        for x = boat.pos.x - high_res_grid_radius, boat.pos.x + high_res_grid_radius, high_res_grid_size do
            for y = boat.pos.y - high_res_grid_radius, boat.pos.y + high_res_grid_radius, high_res_grid_size do
                local pos = vec(x, y)
                local distance = mag(minus(pos, boat.pos))
                if distance <= high_res_grid_radius then
                    local wind = apply_scene_influence(vec(wind_config.base_direction.x * wind_config.base_strength, wind_config.base_direction.y * wind_config.base_strength))
                    wind = adjust_for_obstructions(pos, wind, boats, barriers)
                    table.insert(vector_field, {pos = pos, vector = wind})
                end
            end
        end
    end

    for _, barrier in ipairs(barriers) do
        for x = barrier.pos.x - high_res_grid_radius, barrier.pos.x + high_res_grid_radius, high_res_grid_size do
            for y = barrier.pos.y - high_res_grid_radius, barrier.pos.y + high_res_grid_radius, high_res_grid_size do
                local pos = vec(x, y)
                local distance = mag(minus(pos, barrier.pos))
                if distance <= high_res_grid_radius then
                    local wind = apply_scene_influence(vec(wind_config.base_direction.x * wind_config.base_strength, wind_config.base_direction.y * wind_config.base_strength))
                    wind = adjust_for_obstructions(pos, wind, boats, barriers)
                    table.insert(vector_field, {pos = pos, vector = wind})
                end
            end
        end
    end

    return vector_field
end

