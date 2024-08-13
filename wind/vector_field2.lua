include "/sail/wind/perlin.lua"
include "/sail/coords.lua"

-- Initialize the Perlin noise generator
local perlin = Perlin:new(time())

-- Initialize base direction and intensity
local base_direction = 0.5
local base_intensity = 1.5

-- List to store obstructions
obstructions = {}
-- List to store low-wind zones
low_wind_zones = {}

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
    local ins = 40 -- Inset margin for drawing

    -- Adjust camera position based on inset margin
    local camera_x = coords.screen.x + ins
    local camera_y = coords.screen.y + ins
    local screen_width = coords.screen.width - (ins * 2)
    local screen_height = coords.screen.height - (ins * 2)

    -- Draw outer rectangle to frame the visible game world area
    rect(camera_x, camera_y, camera_x + screen_width, camera_y + screen_height, 6)

    -- Calculate the range of world coordinates that are visible on the screen
    local min_world_x = camera_x
    local max_world_x = camera_x + screen_width
    local min_world_y = camera_y
    local max_world_y = camera_y + screen_height

    -- Draw inner rectangle slightly inset from the outer rectangle
    rect(min_world_x + 4, min_world_y + 4, max_world_x - 4, max_world_y - 4, 6)

    -- Calculate the range of world grid coordinates that are visible on the screen
    local min_world_grid_x = math.floor(min_world_x / cell_size) * cell_size
    local max_world_grid_x = math.ceil(max_world_x / cell_size) * cell_size
    local min_world_grid_y = math.floor(min_world_y / cell_size) * cell_size
    local max_world_grid_y = math.ceil(max_world_y / cell_size) * cell_size

    -- Draw rectangle describing the visible grid cells in the world space
    rect(min_world_grid_x, min_world_grid_y, max_world_grid_x, max_world_grid_y, 6)

    -- Iterate over the visible grid cells
    for world_y = min_world_grid_y, max_world_grid_y, cell_size do
        for world_x = min_world_grid_x, max_world_grid_x, cell_size do
            local grid_x = math.floor(world_x / cell_size) + 1
            local grid_y = math.floor(world_y / cell_size) + 1

            -- Ensure the grid coordinates are within bounds
            if grid_x >= 1 and grid_x <= grid_width and grid_y >= 1 and grid_y <= grid_height then
                local vec = vector_field[grid_y][grid_x]

                -- Convert world coordinates to screen coordinates
                local screen_x, screen_y = world_to_screen_coords(world_x, world_y, coords.screen.x, coords.screen.y)
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

-- Function to apply wind shadow effect from obstructions
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

    -- Extend the vector field if the boat is near the edge
    local grid_x = math.floor(coords.screen.x / cell_size) + 1
    local grid_y = math.floor(coords.screen.y / cell_size) + 1

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

    -- Apply low-wind zones
    for _, zone in ipairs(low_wind_zones) do
        apply_low_wind_zone(zone)
    end
end

-- Function to apply low-wind zones
function apply_low_wind_zone(zone)
    local min_grid_x = math.floor(zone.x / cell_size) + 1
    local max_grid_x = math.floor((zone.x + zone.width) / cell_size) + 1
    local min_grid_y = math.floor(zone.y / cell_size) + 1
    local max_grid_y = math.floor((zone.y + zone.height) / cell_size) + 1

    -- Ensure the grid coordinates are within bounds
    min_grid_x = math.max(min_grid_x, 1)
    max_grid_x = math.min(max_grid_x, grid_width)
    min_grid_y = math.max(min_grid_y, 1)
    max_grid_y = math.min(max_grid_y, grid_height)

    -- Apply damping factor to the wind vectors inside the zone
    for grid_y = min_grid_y, max_grid_y do
        for grid_x = min_grid_x, max_grid_x do
            local vec = vector_field[grid_y][grid_x]
            vec.x = vec.x * zone.damping_factor
            vec.y = vec.y * zone.damping_factor
        end
    end
end

-- Function to extend the vector field in a given direction
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

-- Function to remove out-of-bounds cells from the vector field
function remove_out_of_bounds_cells()
    local min_x = math.floor((coords.screen.x - margin * cell_size) / cell_size) + 1
    local max_x = math.floor((coords.screen.x + coords.screen.width + margin * cell_size) / cell_size) + 1
    local min_y = math.floor((coords.screen.y - margin * cell_size) / cell_size) + 1
    local max_y = math.floor((coords.screen.y + coords.screen.height + margin * cell_size) / cell_size) + 1

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

-- Function to add a low-wind zone
function add_low_wind_zone(x, y, width, height, damping_factor)
    table.insert(low_wind_zones, {
        x = x,
        y = y,
        width = width,
        height = height,
        damping_factor = damping_factor
    })
end

-- Function to apply low-wind zones
function apply_low_wind_zone(zone)
    local min_grid_x = math.floor(zone.x / cell_size) + 1
    local max_grid_x = math.floor((zone.x + zone.width) / cell_size) + 1
    local min_grid_y = math.floor(zone.y / cell_size) + 1
    local max_grid_y = math.floor((zone.y + zone.height) / cell_size) + 1

    -- Ensure the grid coordinates are within bounds
    min_grid_x = math.max(min_grid_x, 1)
    max_grid_x = math.min(max_grid_x, grid_width)
    min_grid_y = math.max(min_grid_y, 1)
    max_grid_y = math.min(max_grid_y, grid_height)

    -- Apply damping factor to the wind vectors inside the zone
    for grid_y = min_grid_y, max_grid_y do
        for grid_x = min_grid_x, max_grid_x do
            local vec = vector_field[grid_y][grid_x]
            vec.x = vec.x * zone.damping_factor
            vec.y = vec.y * zone.damping_factor
        end
    end
end
