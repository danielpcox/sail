-- coords.lua
local screen_width = 480
local screen_height = 270

-- Initialize coordinate offsets and screen coordinates
coords = {
    camera = {
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
function update_camera(boat)
    local dx = boat.pos.x - boat.prev_pos.x
    local dy = boat.pos.y - boat.prev_pos.y

    coords.camera.x = coords.camera.x + dx
    coords.camera.y = coords.camera.y + dy
end

-- Update coordinate offsets based on boat position
function update_coord_offsets(boat_pos)
    -- Update world coordinates based on boat position
    coords.world.x = boat_pos.x
    coords.world.y = boat_pos.y
    
    -- Update screen coordinates to center on the boat's position
    -- coords.screen.x = boat_pos.x - coords.camera.x
    -- coords.screen.y = boat_pos.y - coords.camera.y
end
