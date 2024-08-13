local screen_width = 480
local screen_height = 270

-- Initialize coordinate offsets and screen coordinates
coords = {
    -- screen coordinates are the coordinates
    -- in world space that are visible onscreen
    screen = {
        x = 0,
        y = 0,
        top = 0,
        left = 0,
        right = screen_width,
        bottom = screen_height,
        width = screen_width,
        height = screen_height,
        cx = math.floor(screen_width / 2), -- Center X coordinate of the screen
        cy = math.floor(screen_height / 2) -- Center Y coordinate of the screen
    }
}

-- Convert world coordinates to screen coordinates
function world_to_screen_coords(world_x, world_y, camera_x, camera_y)
    local screen_x = world_x - camera_x
    local screen_y = world_y - camera_y
    return screen_x, screen_y
end

-- Convert screen coordinates to world coordinates
function screen_to_world_coords(screen_x, screen_y, camera_x, camera_y)
    local world_x = screen_x + camera_x
    local world_y = screen_y + camera_y
    return world_x, world_y
end

-- Update camera position to follow the player
function update_screen_pos(boat)
    -- update position of the camera object
    coords.screen.x = boat.pos.x - screen_width / 2
    coords.screen.y = boat.pos.y - screen_height / 2
    coords.screen.cx = coords.screen.x + screen_width / 2
    coords.screen.cy = coords.screen.y + screen_height / 2
    coords.screen.top = boat.pos.x - screen_width / 2
    coords.screen.left = boat.pos.y - screen_height / 2
    coords.screen.right = boat.pos.x + screen_width / 2
    coords.screen.bottom = boat.pos.y + screen_height / 2
end
