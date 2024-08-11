--[[pod_format="raw",created="2024-08-11 02:06:02",modified="2024-08-11 02:10:31",revision=3]]
-- main.lua
include "/sail/vectors.lua"
include "/sail/boat.lua"
include "/sail/stats.lua"

include "/sail/wind/particles.lua"
include "/sail/wind/vector_field.lua"
include "/sail/wind/particle_draw.lua"

-- TODO: Get display dimensions
screen_width = 720
screen_height = 480
grid_size = 64 -- grid size for vector field

-- Initialize Particle System
particle_system = ParticleSystem:new()

-- Particle configuration parameters
particle_rate = 10
particle_lifetime = 10
base_particle_rate = 2
base_particle_lifetime = 50

-- Wind configuration
wind_config = {
    base_direction = {x = 1, y = 0.1}, -- Initial wind direction
    base_strength = 1.5, -- Initial wind strength
    direction_variability = 0.1, -- Variability in wind direction
    strength_variability = 0.1, -- Variability in wind strength
    noise_frequency = 0.1, -- Frequency of the Perlin noise
    noise_amplitude = 0.1 -- Amplitude of the Perlin noise
}

function __init()
    wind_angle = 0.25
    drag = 0.3 -- scale by which velocity decays per step
    
    -- Initialize boats array and add the initial boat
    boats = { make_boat(240, 13) }
end


-- function get_wind_at_position(pos, vector_field, grid_size)
--     local closest_distance = math.huge
--     local closest_vector = nil

--     for _, field in ipairs(vector_field) do
--         local distance = mag(minus(pos, field.pos))
--         if distance < closest_distance then
--             closest_distance = distance
--             closest_vector = field.vector
--         end
--     end

--     assert(closest_vector ~= nil, "No wind vector found for the given position")
--     return closest_vector
-- end 


function __update()
    local boat = boats[1]  -- Assuming we are working with the first boat for now
    
    -- Adjust boat rudder angle with left and right
    if (btn(0)) boat.rudder = 0.01
    if (btn(1)) boat.rudder = -0.01
    if (not btn(1) and not btn(0)) boat.rudder = 0
    -- Adjust sail trim with up and down
    if (btn(2) and boat.sheet < 0.5) boat.sheet += 0.01
    if (btn(3) and boat.sheet > 0.01) boat.sheet -= 0.01
    
    -- Generate vector field
    vector_field = generate_vector_field(screen_width, screen_height, boats, {}, wind_config, time())
    
    -- Get wind vector at the boat's position
    wind_at_player = get_wind_at_position(boat.pos, vector_field)
      
    -- Assert that wind vector is valid
    assert(wind_at_player.x ~= nil and wind_at_player.y ~= nil, "Wind vector components must not be nil")
    assert(type(wind_at_player.x) == "number" and type(wind_at_player.y) == "number", "Wind vector components must be numbers")
 
    -- compute thrust
    sail = a2v(boat.ang - boat.sail)
    orientation = a2v(boat.ang)
    
    -- TODO: better way to integrate vector field and boat motion
    local boat_wind = {x = wind_at_player.x * 5, y = wind_at_player.y * 5}
    thrust, sail_force = get_thrust(boat_wind, sail, boat.v, orientation)   
    
    -- Assert that thrust and sail_force are valid
    assert(thrust.x ~= nil and thrust.y ~= nil, "Thrust vector components must not be nil")
    assert(type(thrust.x) == "number" and type(thrust.y) == "number", "Thrust vector components must be numbers")
    assert(type(sail_force) == "number", "Sail force must be a number")
    
    -- compute boat rotation
    boat.ang += boat.rudder * mag(thrust)*0.5 + boat.rudder * 0.02
    boat.ang += (boat.ang - boat.ang_prev)
    boat.ang_prev = boat.ang
    
    -- Assert that boat angle is valid
    assert(type(boat.ang) == "number", "Boat angle must be a number")
    
    -- Let wind move sail until sheet is taut
    boat.sail += 0.009*sail_force
    boat.sheet = boat.sheet % 1
    if boat.sail >= (0.5 + boat.sheet) then
        boat.sail = (0.5 + boat.sheet) % 1
    elseif boat.sail <= (0.5 - boat.sheet) then
        boat.sail = (0.5 - boat.sheet) % 1
    end
    boat.sail += (boat.sail - boat.sail_prev)
    boat.sail_prev = boat.sail
   
    -- Assert that sail and sheet are valid
    assert(type(boat.sail) == "number", "Boat sail must be a number")
    assert(type(boat.sheet) == "number", "Boat sheet must be a number")
    
    -- Update motion parameters
    boat.v = plus(boat.v, thrust)
    boat.pos = plus(boat.pos, boat.v)
    boat.v = scale(drag, boat.v)
    
    -- Initialize push_force and lift_mag if not already done
    push_force = push_force or vec(0, 0)
    lift_mag = lift_mag or 0
    
    -- Update particles
    update_particles(vector_field, screen_width, screen_height, boats)
end


function draw_boat()
    local boat = boats[1]  -- Assuming we are working with the first boat for now
    show(scale(10, orientation), boat.pos.x, boat.pos.y, 4)
    show(scale(7, sail), boat.pos.x+10*orientation.x, boat.pos.y+10*orientation.y, 6)
    show(scale(10, thrust), 400, 200, 3)
    show(scale(10, pull_force), 400, 220, 8)
    show(scale(10, push_force), 400, 220, 9)
    show(scale(10, apparent), 400, 240, 28)
end

function draw_vector_field(vector_field, grid_size)
    for _, field in ipairs(vector_field) do
        local start_pos = field.pos
        local end_pos = plus(start_pos, scale(grid_size, field.vector))
        line(start_pos.x, start_pos.y, end_pos.x, end_pos.y, 7) -- Assuming color 7 for the vector arrows
    end
end

function __draw()
    cls()
    local boat = boats[1]  -- Assuming we are working with the first boat for now
    
    -- Center the camera on the boat
    camera(boat.pos.x - 240, boat.pos.y - 135)
    
    -- Draw a rectangle filling the screen, relative to the boat's position
    rectfill(boat.pos.x - screen_width / 2, boat.pos.y - screen_height / 2, boat.pos.x + screen_width / 2, boat.pos.y + screen_height / 2, Colors.dark_blue)
    
    draw_particles()
    draw_boat()
    draw_stats(boat, push_force, lift_mag, orientation)
    draw_vector_field(vector_field, grid_size) -- Draw the vector field
end
