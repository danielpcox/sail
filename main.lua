include "/sail/wind/perlin.lua"

-- Initialize the Perlin noise generator
local perlin = Perlin:new(time())

-- Initialize base direction and intensity
local base_direction = 0.5
local base_intensity = 4

-- List to store obstructions
local obstructions = {}

-- Define the grid size
local grid_width = 20
local grid_height = 20
local cell_size = 14 -- Size of each cell in pixels

-- Initialize the vector field
local vector_field = {}
for y = 1, grid_height do
    vector_field[y] = {}
    for x = 1, grid_width do
        vector_field[y][x] = {dx = 1, dy = 0} -- Initialize with unit vectors pointing right
    end
end

-- Function to draw the vector field
function draw_vector_field()
    cls() -- Clear the screen
    for y = 1, grid_height do
        for x = 1, grid_width do
            local vec = vector_field[y][x]
            local start_x = (x - 1) * cell_size + cell_size / 2
            local start_y = (y - 1) * cell_size + cell_size / 2
            local end_x = start_x + vec.dx * cell_size / 2
            local end_y = start_y + vec.dy * cell_size / 2
            local color = 7
            if vec.dx == 0 and vec.dy == 0 then
                color = 8 -- Highlight the shadowed area
            end
            line(start_x, start_y, end_x, end_y, color) -- Draw the vector as a line
            circfill(end_x, end_y, 1.5, color) -- Draw a small circle at the end of the vector
        end
    end
end

-- Function to get wind at a specific position
function get_wind_at(x, y)
    local grid_x = math.floor(x / cell_size) + 1
    local grid_y = math.floor(y / cell_size) + 1
    if grid_x >= 1 and grid_x <= grid_width and grid_y >= 1 and grid_y <= grid_height then
        return vector_field[grid_y][grid_x]
    else
        return {dx = 0, dy = 0} -- No wind outside the grid
    end
end


function apply_wind_shadow(obs, wind_direction)
    local grid_x = math.floor(obs.x / cell_size) + 1
    local grid_y = math.floor(obs.y / cell_size) + 1
    local radius = obs.radius

    -- Calculate the direction of the wind shadow
    local shadow_angle = atan2(wind_direction.dy, wind_direction.dx)
    local shadow_length = radius * 10 -- Length of the wind shadow (adjust as needed)

    for d = 0, shadow_length do
        local nx = math.floor(grid_x + d * wind_direction.dx)
        local ny = math.floor(grid_y + d * wind_direction.dy)
        
        if nx >= 1 and nx <= grid_width and ny >= 1 and ny <= grid_height then
            local vec = vector_field[ny][nx]
            local reduction = (shadow_length - d) / shadow_length
            
            -- Apply wind shadow effect
            vec.dx = vec.dx * (1 - reduction)
            vec.dy = vec.dy * (1 - reduction)
            
            -- Apply lateral spread of the shadow
            local spread_width = math.ceil(radius * (1 - d/shadow_length))
            for r = -spread_width, spread_width do
                local spread_nx = math.floor(nx - r * wind_direction.dy)
                local spread_ny = math.floor(ny + r * wind_direction.dx)
                if spread_nx >= 1 and spread_nx <= grid_width and spread_ny >= 1 and spread_ny <= grid_height then
                    local spread_vec = vector_field[spread_ny][spread_nx]
                    local spread_reduction = reduction * (1 - math.abs(r) / spread_width)
                    spread_vec.dx = spread_vec.dx * (1 - spread_reduction)
                    spread_vec.dy = spread_vec.dy * (1 - spread_reduction)
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
    local direction_variation = noise_value_direction * 2 * math.pi
    local intensity_variation = noise_value_intensity * 0.5 + 0.5 -- Normalize to [0.5, 1.5]

    local current_direction = base_direction + direction_variation
    local current_intensity = base_intensity * intensity_variation

    -- Initialize the vector field with base wind direction and intensity
    for y = 1, grid_height do
        for x = 1, grid_width do
            local vec = vector_field[y][x]
            vec.dx = current_intensity * math.cos(current_direction)
            vec.dy = current_intensity * math.sin(current_direction)
        end
    end

    -- Apply wind shadow effects from obstructions
    for _, obs in ipairs(obstructions) do
        apply_wind_shadow(obs, {dx = math.cos(current_direction), dy = math.sin(current_direction)})
    end
end

-- Function to add an obstruction
function add_obstruction(mx, my, radius)
    table.insert(obstructions, {x = mx, y = my, radius = radius})
end

-- Function to draw the obstruction at the mouse position
function draw_obstruction(mx, my)
    circfill(mx, my, cell_size / 2, 8) -- Draw a circle to indicate the obstruction
    add_obstruction(mx, my, 3) -- Add obstruction to the list
end

function __init()
end

function __update()
    if btnp(0) then base_direction = base_direction - 0.1 end -- Left
    if btnp(1) then base_direction = base_direction + 0.1 end -- Right
    if btnp(2) then base_intensity = base_intensity - 0.1 end -- Up
    if btnp(3) then base_intensity = base_intensity + 0.1 end -- Down
    
    local mx, my = mouse()
    if btnp(4) then -- Assuming button 4 is used to place obstructions
        draw_obstruction(mx, my)
    end
    update_vector_field()
end

function __draw()
    cls()
    draw_vector_field()
end
