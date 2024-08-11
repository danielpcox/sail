-- main.lua
include "/sail/wind/vector_field2.lua"
include "/sail/wind/particle_draw.lua"
include "/sail/vectors.lua"
include "/sail/boat.lua"
include "/sail/stats.lua"

-- TODO: Get display dimensions
screen_width = 720
screen_height = 480

function __init()
    -- Place the boat in the center of the screen
    local initial_boat_x = screen_width / 2
    local initial_boat_y = screen_height / 2
    boats = { make_boat(initial_boat_x, initial_boat_y) }
    drag = 0.3 -- scale by which velocity decays per step
    init_vector_field()
    -- add_obstruction(boats[1].pos.x, boats[1].pos.y, 2) -- Add initial obstruction for the boat
end

function __update()
    local boat = boats[1]  -- Assuming we are working with the first boat for now

    -- HANDLE CONTROLS
    
    -- Adjust boat rudder angle with left and right
    if (btn(0)) boat.rudder = 0.01
    if (btn(1)) boat.rudder = -0.01
    if (not btn(1) and not btn(0)) boat.rudder = 0
    -- Adjust sail trim with up and down
    if (btn(2) and boat.sheet < 0.5) boat.sheet += 0.01
    if (btn(3) and boat.sheet > 0.01) boat.sheet -= 0.01

    -- CALCULATE PHYSICS
    
    -- Get wind vector at the boat's position
    wind_at_player = get_wind_at(boat.pos.x, boat.pos.y)
    assert(wind_at_player.x ~= nil and wind_at_player.y ~= nil, "Wind vector components must not be nil")
    assert(type(wind_at_player.x) == "number" and type(wind_at_player.y) == "number", "Wind vector components must be numbers")
    assert(math.abs(wind_at_player.x) <= 10 and math.abs(wind_at_player.y) <= 10, "Wind vector components out of expected range")

    -- compute thrust
    sail = a2v(boat.ang - boat.sail)
    orientation = a2v(boat.ang)
    thrust, sail_force = get_thrust(wind_at_player, sail, boat.v, orientation)
    assert(thrust.x ~= nil and thrust.y ~= nil, "Thrust vector components must not be nil")
    assert(type(thrust.x) == "number" and type(thrust.y) == "number", "Thrust vector components must be numbers")
    assert(math.abs(thrust.x) <= 10 and math.abs(thrust.y) <= 10, "Thrust vector components out of expected range")
    assert(type(sail_force) == "number", "Sail force must be a number")
    assert(math.abs(sail_force) <= 10, "Sail force out of expected range")
    
    -- compute boat rotation
    boat.ang += boat.rudder * mag(thrust) * 0.5 + boat.rudder * 0.02
    boat.ang += (boat.ang - boat.ang_prev)
    boat.ang_prev = boat.ang
    assert(type(boat.ang) == "number", "Boat angle must be a number")
  
    -- Let wind move sail until sheet is taut
    boat.sail += 0.009 * sail_force
    boat.sheet = boat.sheet % 1
    if boat.sail >= (0.5 + boat.sheet) then
        boat.sail = (0.5 + boat.sheet) % 1
    elseif boat.sail <= (0.5 - boat.sheet) then
        boat.sail = (0.5 - boat.sheet) % 1
    end
    boat.sail += (boat.sail - boat.sail_prev)
    boat.sail_prev = boat.sail
    assert(type(boat.sail) == "number", "Boat sail must be a number")
    assert(boat.sail >= 0 and boat.sail <= 1, "Boat sail out of expected range")
    assert(type(boat.sheet) == "number", "Boat sheet must be a number")
    assert(boat.sheet >= 0 and boat.sheet <= 1, "Boat sheet out of expected range")
   
    -- Update motion parameters
    boat.v = plus(boat.v, thrust)
    boat.pos = plus(boat.pos, boat.v)
    boat.v = scale(drag, boat.v)
    assert(type(boat.pos.x) == "number" and type(boat.pos.y) == "number", "Boat position must be numbers")

    -- Update the position of the obstruction to follow the boat
    -- update_obstruction_position(obstructions[1], boat.pos.x, boat.pos.y)

    update_vector_field()
end

function draw_boat()
    local boat = boats[1]  -- Assuming we are working with the first boat for now
    show(scale(10, orientation), boat.pos.x, boat.pos.y, 4)
    show(scale(7, sail), boat.pos.x + 10 * orientation.x, boat.pos.y + 10 * orientation.y, 6)
    show(scale(10, thrust), 400, 200, 3)
    show(scale(10, pull_force), 400, 220, 8)
    show(scale(10, push_force), 400, 220, 9)
    show(scale(10, apparent), 400, 240, 28)
end

function __draw()
    cls()
    local boat = boats[1]  -- Assuming we are working with the first boat for now

    -- Center the camera on the boat
    camera(boat.pos.x - screen_width / 2, boat.pos.y - screen_height / 2)
    
    -- Draw a rectangle filling the screen, relative to the boat's position
    rectfill(boat.pos.x - screen_width / 2, boat.pos.y - screen_height / 2, boat.pos.x + screen_width / 2, boat.pos.y + screen_height / 2, Colors.dark_blue)

    draw_vector_field()
    draw_boat()
end