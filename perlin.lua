-- perlin.lua

-- Perlin noise implementation in Lua
Perlin = {}
Perlin.__index = Perlin

function Perlin:fade(t)
    return t * t * t * (t * (t * 6 - 15) + 10)
end

function Perlin:lerp(t, a, b)
    return a + t * (b - a)
end

function Perlin:grad(hash, x, y)
    local h = hash % 4
    local u = h < 2 and x or y
    local v = h < 2 and y or x
    return ((h % 2 == 0) and u or -u) + ((h < 2) and v or -v)
end

function Perlin:noise(x, y)
    local X = math.floor(x) % 255
    local Y = math.floor(y) % 255
    x = x - math.floor(x)
    y = y - math.floor(y)
    local u = self:fade(x)
    local v = self:fade(y)
    local a = self.p[X + 1] + Y
    local aa = self.p[a + 1]
    local ab = self.p[a + 2]
    local b = self.p[X + 2] + Y
    local ba = self.p[b + 1]
    local bb = self.p[b + 2]

    return self:lerp(v, self:lerp(u, self:grad(self.p[aa + 1], x, y), self:grad(self.p[ba + 1], x - 1, y)),
                        self:lerp(u, self:grad(self.p[ab + 1], x, y - 1), self:grad(self.p[bb + 1], x - 1, y - 1)))
end

function Perlin:new(seed)
    local p = {}
    for i = 0, 255 do
        p[i + 1] = i
    end
    if seed then
        math.randomseed(seed)
    end
    for i = 255, 1, -1 do
        local j = math.random(0, 255)
        p[i + 1], p[j + 1] = p[j + 1], p[i + 1]
    end
    for i = 0, 255 do
        p[i + 257] = p[i + 1]
    end
    local instance = setmetatable({p = p}, Perlin)
    return instance
end

