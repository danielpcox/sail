-- vector_field2.lua
include "/sail/wind/perlin.lua"

-- Initialize the Perlin noise generator
local perlin = Perlin:new(time())

-- Initialize base direction and intensity
local base_direction = 0.5
local base_intensity = 1.5

-- List to store obstructions
obstructions = {}

-- Define the grid size
local grid_width = 40
local grid_height = 40
local cell_size = 14 -- Size of each cell in pixels

-- Initialize the vector field
function init_vector_field()
    vector_field = {}
    for y = 1, grid_height do
        vector_field[y] = {}
        for x = 1, grid_width do
            vector_field[y][x] = {x = 1, y = 0} -- Initialize with unit vectors pointing right
            assert(vector_field[y][x].x ~= nil and vector_field[y][x].y ~= nil, "Vector field components must not be nil")
            assert(type(vector_field[y][x].x) == "number" and type(vector_field[y][x].y) == "number", "Vector field components must be numbers")
        end
    end
end


-- Function to draw the vector field
function draw_vector_field()
    -- cls() -- Clear the screen
    for y = 1, grid_height do
        for x = 1, grid_width do
            local vec = vector_field[y][x]
            assert(vec.x ~= nil and vec.y ~= nil, "Vector field components must not be nil")
            assert(type(vec.x) == "number" and type(vec.y) == "number", "Vector field components must be numbers")
            local start_x = (x - 1) * cell_size + cell_size / 2
            local start_y = (y - 1) * cell_size + cell_size / 2
            local end_x = start_x + vec.x * cell_size / 2
            local end_y = start_y + vec.y * cell_size / 2
            local color = 7
            if vec.x == 0 and vec.y == 0 then
                color = 8 -- Highlight the shadowed area
            end
 
            line(start_x, start_y, end_x, end_y, color) -- Draw the vector as a line
            circfill(end_x, end_y, 1, color) -- Draw a small circle at the end of the vector
        end
    end
end

-- Function to get wind at a specific position
function get_wind_at(x, y)
    local grid_x = math.floor(x / cell_size) + 1
    local grid_y = math.floor(y / cell_size) + 1
    if grid_x >= 1 and grid_x <= grid_width and grid_y >= 1 and grid_y <= grid_height then
        assert(vector_field[grid_y] and vector_field[grid_y][grid_x], "Vector field must be initialized and non-empty")
        return vector_field[grid_y][grid_x]
    else
        return {x = 0, y = 0} -- No wind outside the grid
    end
end

function apply_wind_shadow(obs, wind_direction)
    local grid_x = math.floor(obs.x / cell_size) + 1
    local grid_y = math.floor(obs.y / cell_size) + 1
    local radius = obs.radius

    -- Calculate the direction of the wind shadow
    local shadow_angle = atan2(wind_direction.y, wind_direction.x)
    local shadow_length = radius * 10 -- Length of the wind shadow (adjust as needed)

    for d = 0, shadow_length do
        local nx = math.floor(grid_x + d * wind_direction.x)
        local ny = math.floor(grid_y + d * wind_direction.y)
        
        if nx >= 1 and nx <= grid_width and ny >= 1 and ny <= grid_height then
            local vec = vector_field[ny][nx]
            local reduction = (shadow_length - d) / shadow_length
            
            -- Apply wind shadow effect
            vec.x = vec.x * (1 - reduction)
            vec.y = vec.y * (1 - reduction)
            
            -- Apply lateral spread of the shadow
            local spread_width = math.ceil(radius * (1 - d/shadow_length))
            for r = -spread_width, spread_width do
                local spread_nx = math.floor(nx - r * wind_direction.y)
                local spread_ny = math.floor(ny + r * wind_direction.x)
                if spread_nx >= 1 and spread_nx <= grid_width and spread_ny >= 1 and spread_ny <= grid_height then
                    local spread_vec = vector_field[spread_ny][spread_nx]
                    local spread_reduction = reduction * (1 - math.abs(r) / spread_width)
                    spread_vec.x = spread_vec.x * (1 - spread_reduction)
                    spread_vec.y = spread_vec.y * (1 - spread_reduction)
                end
            end
        end
    end
end

-- Function to update the vector field
function update_vector_field()
    local time = t() * 0.1
    local noise_value_direction = perlin:noise(time, 0)
    local noise_value_intensity = perlin:noise(0, time)
    local direction_variation = noise_value_direction * 0.1 * math.pi
    local intensity_variation = noise_value_intensity * 0.5 + 0.5 -- Normalize to [0.5, 1.5]

    local current_direction = base_direction + direction_variation
    local current_intensity = base_intensity * intensity_variation

    -- Initialize the vector field with base wind direction and intensity
    for y = 1, grid_height do
        for x = 1, grid_width do
            local vec = vector_field[y][x]
            vec.x = current_intensity * math.cos(current_direction)
            vec.y = current_intensity * math.sin(current_direction)
            -- Assert that vector field components are valid
            assert(vec.x ~= nil and vec.y ~= nil, "Vector field components must not be nil")
            assert(type(vec.x) == "number" and type(vec.y) == "number", "Vector field components must be numbers")
        end
    end

    -- Apply wind shadow effects from obstructions
    for _, obs in ipairs(obstructions) do
        apply_wind_shadow(obs, {x = math.cos(current_direction), y = math.sin(current_direction)})
    end
end
-- Function to add an obstruction
function add_obstruction(mx, my, radius)
    table.insert(obstructions, {x = mx, y = my, radius = radius})
end

-- Function to update the position of the obstruction
function update_obstruction_position(obs, mx, my)
    obs.x = mx
    obs.y = my
end


-- Function to draw the obstruction at the mouse position
function draw_obstruction(mx, my)
    circfill(mx, my, cell_size / 2, 8) -- Draw a circle to indicate the obstruction
    add_obstruction(mx, my, 3) -- Add obstruction to the list
end
