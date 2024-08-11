-- physics.lua

function vec(x,y)
 return {x=x, y=y}
end

function a2v(angle)
 -- unit vector for a given angle
 return vec(cos(angle), sin(angle))
end

function v2a(v)
 -- angle wrt the x axis of a given vector
 return atan2(v.x, v.y)
end

function mag(v)
 -- magnitude of v
 return sqrt(v.x^2+v.y^2)
end

function unit(v)
 -- unit vector in the same direction as v
 local m = mag(v)
 return vec(v.x/m, v.y/m)
end

function plus(a, b)
 -- add two vectors
 return vec(a.x+b.x, a.y+b.y)
end

function neg(v)
 -- negate / reverse a vector
 return vec(-v.x, -v.y)
end

function minus(a, b)
 -- subtract two vectors
 return plus(a, neg(b))
end

function scale(s, v)
 -- scale a vector by a scalar
 return vec(v.x*s, v.y*s)
end

function rotate(v, a)
 return vec(v.x*cos(a)-v.y*sin(a), v.x*sin(a)+v.y*cos(a))
end

function sign(number)
    return number > 0 and 1 or (number == 0 and 0 or -1)
end

function show(v, x, y, c)
 -- Draw arrows representing the vector v with origin x,y
 line(x, y, v.x+x, v.y+y, c)
 pset(v.x+x, v.y+y, 7) -- white arrowhead
end

function norm(v)
 -- A vector orthogonal to v with the same length
 return vec(v.y, -v.x)
end

function dot(a, b)
 -- Calculate the dot product of two vectors
 return a.x * b.x + a.y * b.y
end

function proj(a, b)
 -- Calculate the projection of vector a onto vector b
 local dotAB = dot(a, b)
 local dotBB = dot(b, b)
 local scaleFactor = dotAB / dotBB
 return scale(scaleFactor, b)
end


