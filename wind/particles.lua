--[[pod_format="raw",created="2024-08-11 02:08:21",modified="2024-08-11 02:08:21",revision=0]]
-- particles.lua
include "/sail/colors.lua"

-- Configuration
particle_config = {
    base_particle = {
        appearance = {
            colors = {Colors.blue},
            lifetime = 100,
            scale = 24,
            ax = 0,
            ay = 0,
            custom_update = nil,
            events = {}
        },
        rate = .1,
    },
    wind_particle = {
        appearance = {
            colors = {Colors.dark_blue, Colors.blue, Colors.light_gray, Colors.white},
            lifetime = 80,
            scale = 1,
            ax = 0,
            ay = 0,
            custom_update = nil,
            events = {}
        },
        rate = function(wind) return math.floor(mag(wind) * 2) end
    },
    splash_particle = {
        appearance = {
            colors = {Colors.indigo, Colors.blue, Colors.light_gray, Colors.white},
            lifetime = 60,
            scale = 1,
            ax = 0,
            ay = 0,
            custom_update = nil,
            events = {}
        },
        rate = function(wind) return math.floor(mag(wind) * 1.5) end,
        radius = 60
    }
}

-- Particle Class
Particle = {}
Particle.__index = Particle

function Particle:new(x, y, vx, vy, appearance)
    local p = setmetatable({}, Particle)
    p.x = x
    p.y = y
    p.vx = vx
    p.vy = vy
    p.ax = appearance.ax or 0
    p.ay = appearance.ay or 0
    p.life = appearance.lifetime
    p.colors = appearance.colors
    p.color_transition = appearance.color_transition or "linear"
    p.shape = appearance.shape or "circle"
    p.scale = appearance.scale or 1
    p.initial_life = appearance.lifetime
    p.custom_update = appearance.custom_update
    p.events = appearance.events or {}
    return p
end

function Particle:update()
    if self.custom_update then
        self.custom_update(self)
    else
        self.vx = self.vx + self.ax
        self.vy = self.vy + self.ay
        self.x = self.x + self.vx
        self.y = self.y + self.vy
        self.life = self.life - 1
    end

    for _, event in ipairs(self.events) do
        if self.life == event.time then
            event.action(self)
        end
    end
end

function Particle:draw()
    local intensity_index = math.floor((1 - (self.life / self.initial_life)) * (#self.colors - 1)) + 1
    local color = self.colors[intensity_index]
    local half_scale = math.floor(self.scale / 2)
    ovalfill(self.x - half_scale, self.y - half_scale, self.x + half_scale, self.y + half_scale, color)
end

-- Particle System
ParticleSystem = {}
ParticleSystem.__index = ParticleSystem

function ParticleSystem:new()
    local ps = setmetatable({}, ParticleSystem)
    ps.particles = {}
    return ps
end

function ParticleSystem:add(particle)
    table.insert(self.particles, particle)
end

function ParticleSystem:update()
    for i = #self.particles, 1, -1 do
        local p = self.particles[i]
        p:update()
        if p.life <= 0 then
            table.remove(self.particles, i)
        end
    end
end

function ParticleSystem:draw()
    for _, p in ipairs(self.particles) do
        p:draw()
    end
end

-- Derive Vector Field
function derive_vector_field(wind, boats)
    local vector_field = {}
    vector_field.wind = wind
    vector_field.boats = boats
    return vector_field
end

-- Render Particles
function render_particles(vector_field, screen_width, screen_height, particle_system)
    local wind = vector_field.wind
    local boats = vector_field.boats
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
        local vx = wind.x / 10
        local vy = wind.y / 10
        local base_particle = Particle:new(x, y, vx, vy, particle_config.base_particle.appearance)
        particle_system:add(base_particle)
    end

    -- Generate new wind particles
    local wind_particle_rate = particle_config.wind_particle.rate(wind)
    local wind_particles_to_create = math.floor(wind_particle_rate)
    local wind_particle_fraction = wind_particle_rate - wind_particles_to_create
    if math.random() < wind_particle_fraction then
        wind_particles_to_create = wind_particles_to_create + 1
    end

    for i = 1, wind_particles_to_create do
        local x = math.random(0, screen_width) + (player_pos_x - screen_width / 2)
        local y = math.random(0, screen_height) - (screen_height / 2) + player_pos_y
        local wind_particle = Particle:new(x, y, wind.x, wind.y, particle_config.wind_particle.appearance)
        particle_system:add(wind_particle)
    end

    -- Generate new splash particles near boats
    for _, boat in ipairs(boats) do
        local splash_particle_rate = particle_config.splash_particle.rate(wind)
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
            local splash_particle = Particle:new(x, y, wind.x, wind.y, particle_config.splash_particle.appearance)
            particle_system:add(splash_particle)
        end
    end
end

-- Main Update Function
function update_particles(wind, screen_width, screen_height, boats)
    local vector_field = derive_vector_field(wind, boats)
    render_particles(vector_field, screen_width, screen_height, particle_system)
end

-- Main Draw Function
function draw_particles()
    particle_system:draw()
end
