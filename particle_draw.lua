-- particle_draw.lua
include "/sail/particles.lua"
include "/sail/vector_field.lua"

-- Update Particles
function update_particles(vector_field, screen_width, screen_height, boats)
    local player_boat = boats[1]
    local player_pos_x = player_boat.pos.x
    local player_pos_y = player_boat.pos.y

    -- Update particle system
    particle_system:update()

    -- Generate new base particles
    local base_particle_rate = particle_config.base_particle.rate
    local base_particles_to_create = math.floor(base_particle_rate)
    local base_particle_fraction = base_particle_rate - base_particles_to_create
    if math.random() < base_particle_fraction then
        base_particles_to_create = base_particles_to_create + 1
    end

    for i = 1, base_particles_to_create do
        local x = math.random(0, screen_width) + (player_pos_x - screen_width / 2)
        local y = math.random(0, screen_height) - (screen_height / 2) + player_pos_y
        local vx = vector_field[1].vector.x / 10
        local vy = vector_field[1].vector.y / 10
        local base_particle = Particle:new(x, y, vx, vy, particle_config.base_particle.appearance)
        particle_system:add(base_particle)
    end

    -- Generate new wind particles
    local wind_particle_rate = particle_config.wind_particle.rate(vector_field[1].vector)
    local wind_particles_to_create = math.floor(wind_particle_rate)
    local wind_particle_fraction = wind_particle_rate - wind_particles_to_create
    if math.random() < wind_particle_fraction then
        wind_particles_to_create = wind_particles_to_create + 1
    end

    for i = 1, wind_particles_to_create do
        local x = math.random(0, screen_width) + (player_pos_x - screen_width / 2)
        local y = math.random(0, screen_height) - (screen_height / 2) + player_pos_y
        local wind_particle = Particle:new(x, y, vector_field[1].vector.x, vector_field[1].vector.y, particle_config.wind_particle.appearance)
        particle_system:add(wind_particle)
    end

    -- Generate new splash particles near boats
    for _, boat in ipairs(boats) do
        local splash_particle_rate = particle_config.splash_particle.rate(vector_field[1].vector)
        local splash_particles_to_create = math.floor(splash_particle_rate)
        local splash_particle_fraction = splash_particle_rate - splash_particles_to_create
        if math.random() < splash_particle_fraction then
            splash_particles_to_create = splash_particles_to_create + 1
        end

        for i = 1, splash_particles_to_create do
            local radius = particle_config.splash_particle.radius
            local angle = math.random() * 2 * math.pi
            local distance = math.random() * radius
            local x = boat.pos.x + distance * math.cos(angle)
            local y = boat.pos.y + distance * math.sin(angle)
            local splash_particle = Particle:new(x, y, vector_field[1].vector.x, vector_field[1].vector.y, particle_config.splash_particle.appearance)
            particle_system:add(splash_particle)
        end
    end
end

-- Draw Particles
function draw_particles()
    particle_system:draw()
end
