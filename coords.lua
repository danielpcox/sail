local screen_width = 480
local screen_height = 270
local cell_size = 32  -- Assuming cell_size is defined

-- Initialize coordinate offsets and screen coordinates
coords = {
    world = {
        x = 0,
        y = 0
    },
    grid = {
        x = 0,
        y = 0
    },
    screen = {
        x = 0,
        y = 0,
        width = screen_width,
        height = screen_height,
        cx = math.floor(screen_width / 2),
        cy = math.floor(screen_height / 2)
    }
}

-- Convert world coordinates to grid coordinates
function world_to_grid_coords(world_x, world_y)
    local grid_x = math.floor(world_x / cell_size) + 1
    local grid_y = math.floor(world_y / cell_size) + 1
    return grid_x, grid_y
end

-- Convert grid coordinates to world coordinates
function grid_to_world_coords(grid_x, grid_y)
    local world_x = (grid_x - 1) * cell_size
    local world_y = (grid_y - 1) * cell_size
    return world_x, world_y
end

-- Convert world coordinates to screen coordinates
function world_to_screen_coords(world_x, world_y, world_offset_x, world_offset_y)
    local screen_x = world_x - world_offset_x
    local screen_y = world_y - world_offset_y
    return screen_x, screen_y
end

-- Convert screen coordinates to world coordinates
function screen_to_world_coords(screen_x, screen_y, world_offset_x, world_offset_y)
    local world_x = screen_x + world_offset_x
    local world_y = screen_y + world_offset_y
    return world_x, world_y
end

-- Update screen object
function update_screen_coords(screen, cam_x, cam_y)
    screen.x = cam_x
    screen.y = cam_y
    screen.cx = cam_x + screen_width / 2
    screen.cy = cam_y + screen_height / 2
    return screen
end

-- Update coordinate offsets based on boat position
function update_coord_offsets(coords, boat_pos)
    coords.world.x = boat_pos.x - screen_width / 2
    coords.world.y = boat_pos.y - screen_height / 2
    coords.grid.x, coords.grid.y = world_to_grid_coords(coords.world.x, coords.world.y)
    coords.screen = update_screen_coords(coords.screen, coords.world.x, coords.world.y)
    return coords
end
