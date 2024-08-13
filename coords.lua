local screen_width = 480
local screen_height = 270

-- Initialize coordinate offsets and screen coordinates
coords = {
    -- screen coordinates are the coordinates
    -- in world space that are visible onscreen
    screen = {
        top = 0,
        left = 0,
        right = screen_width,
        bottom = screen_height,
        width = screen_width,
        height = screen_height,
        cx = screen_width / 2, -- Center X coordinate of the screen
        cy = screen_height / 2 -- Center Y coordinate of the screen
    }
}

function inset_coords(coords, inset)
    new_coords = {
        top = coords.top + inset,
        left = coords.left + inset,
        right = coords.right - inset,
        bottom = coords.bottom - inset,
        width = coords.width - inset,
        height = coords.height - inset
    }
    return new_coords
end

-- Convert world coordinates to screen coordinates
function world_to_screen_coords(world_x, world_y)
    local screen_x = world_x + coords.screen.left
    local screen_y = world_y + coords.screen.top
    return screen_x, screen_y
end

-- Convert screen coordinates to world coordinates
function screen_to_world_coords(screen_x, screen_y)
    local world_x = screen_x - coords.screen.left
    local world_y = screen_y - coords.screen.top
    return world_x, world_y
end

-- Update camera position to follow the player
function update_screen_pos(boat)
    -- update position of the camera object
    coords.screen.top = boat.pos.y - (screen_height / 2)
    coords.screen.left = boat.pos.x - (screen_width / 2)
    coords.screen.right = boat.pos.x + (screen_width / 2)
    coords.screen.bottom = boat.pos.y + (screen_height / 2)
    coords.screen.cx = boat.pos.x
    coords.screen.cy = boat.pos.y
end
