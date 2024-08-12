-- vector_field2.lua
include "/sail/wind/perlin.lua"
include "/sail/coords.lua"
include "/sail/wind/perlin.lua"
include "/sail/coords.lua"


-- Initialize the Perlin noise generator
local perlin = Perlin:new(time())

-- Initialize base direction and intensity
local base_direction = 0.5
local base_intensity = 1.5

-- List to store obstructions
obstructions = {}

-- Define the grid size
local margin = 5 -- Number of cells to keep as a buffer around the visible area
cell_size = 32 -- Size of each cell in pixels
local grid_width = math.ceil(coords.screen.width / cell_size) + 2 * margin
local grid_height = math.ceil(coords.screen.height / cell_size) + 2 * margin

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
    local cam_x = coords.camera.x
    local cam_y = coords.camera.y

    -- Calculate the range of grid cells that are visible on the screen
    local min_grid_x = math.floor(cam_x / cell_size) + 1
    local max_grid_x = math.floor((cam_x + coords.screen.width) / cell_size) + 1
    local min_grid_y = math.floor(cam_y / cell_size) + 1
    local max_grid_y = math.floor((cam_y + coords.screen.width) / cell_size) + 1

    -- Ensure the grid coordinates are within bounds
    min_grid_x = math.max(min_grid_x, 1)
    max_grid_x = math.min(max_grid_x, grid_width)
    min_grid_y = math.max(min_grid_y, 1)
    max_grid_y = math.min(max_grid_y, grid_height)

    -- Iterate over the visible grid cells
    for grid_y = min_grid_y, max_grid_y do
        for grid_x = min_grid_x, max_grid_x do
            local vec = vector_field[grid_y][grid_x]
            local world_x = (grid_x - 1) * cell_size
            local world_y = (grid_y - 1) * cell_size
            local screen_x, screen_y = world_to_screen_coords(world_x, world_y, cam_x, cam_y)
            local end_x = screen_x + vec.x * cell_size / 2
            local end_y = screen_y + vec.y * cell_size / 2
            local color = 7
            if vec.x == 0 and vec.y == 0 then
                color = 8 -- Highlight the shadowed area
            end
            line(screen_x, screen_y, end_x, end_y, color) -- Draw the vector as a line
        end
    end
end

-- Function to get wind at a specific position
function get_wind_at(world_x, world_y)
    assert(type(world_x) == "number" and type(world_y) == "number", "World X and World Y must be numbers")
    local grid_x = math.floor(world_x / cell_size) + 1
    local grid_y = math.floor(world_y / cell_size) + 1

    -- Adjust grid coordinates if they are out of bounds
    if grid_x < 1 then grid_x = 1 end
    if grid_x > grid_width then grid_x = grid_width end
    if grid_y < 1 then grid_y = 1 end
    if grid_y > grid_height then grid_y = grid_height end

    return vector_field[grid_y][grid_x]
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

function update_vector_field()
    local time = t() * 0.1
    local noise_value_direction = perlin:noise(time, 0)
    local noise_value_intensity = perlin:noise(0, time)
    local direction_variation = noise_value_direction * 0.1 * math.pi
    local intensity_variation = noise_value_intensity * 0.5 + 0.5 -- Normalize to [0.5, 1.5]

    local current_direction = base_direction + direction_variation
    local current_intensity = base_intensity * intensity_variation

    -- Extend the vector field if the boat is near the edge
    local grid_x = math.floor(coords.camera.x / cell_size) + 1
    local grid_y = math.floor(coords.camera.y / cell_size) + 1

    local extend_margin = margin -- Number of cells to extend when near the edge

    if grid_x <= extend_margin then
        extend_vector_field("left")
    elseif grid_x >= grid_width - extend_margin then
        extend_vector_field("right")
    end

    if grid_y <= extend_margin then
        extend_vector_field("up")
    elseif grid_y >= grid_height - extend_margin then
        extend_vector_field("down")
    end

    -- Remove out-of-bounds cells
    remove_out_of_bounds_cells()

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

function extend_vector_field(direction)
    if direction == "left" then
        for y = 1, grid_height do
            table.insert(vector_field[y], 1, {x = 1, y = 0})
        end
        grid_width = grid_width + 1
    elseif direction == "right" then
        for y = 1, grid_height do
            table.insert(vector_field[y], {x = 1, y = 0})
        end
        grid_width = grid_width + 1
    elseif direction == "up" then
        local new_row = {}
        for x = 1, grid_width do
            table.insert(new_row, {x = 1, y = 0})
        end
        table.insert(vector_field, 1, new_row)
        grid_height = grid_height + 1
    elseif direction == "down" then
        local new_row = {}
        for x = 1, grid_width do
            table.insert(new_row, {x = 1, y = 0})
        end
        table.insert(vector_field, new_row)
        grid_height = grid_height + 1
    end
end

function remove_out_of_bounds_cells()
    local min_x = math.floor((coords.camera.x - margin * cell_size) / cell_size) + 1
    local max_x = math.floor((coords.camera.x + coords.screen.width + margin * cell_size) / cell_size) + 1
    local min_y = math.floor((coords.camera.y - margin * cell_size) / cell_size) + 1
    local max_y = math.floor((coords.camera.y + coords.screen.height + margin * cell_size) / cell_size) + 1

    -- Remove rows outside the bounds
    while grid_height > 0 and (grid_height < min_y or grid_height > max_y) do
        table.remove(vector_field, grid_height)
        grid_height = grid_height - 1
    end

    -- Remove columns outside the bounds
    for y = 1, grid_height do
        while #vector_field[y] > 0 and (#vector_field[y] < min_x or #vector_field[y] > max_x) do
            table.remove(vector_field[y], #vector_field[y])
        end
    end

    -- Adjust grid width
    grid_width = #vector_field[1]
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