-- boat.lua
include "/sail/vectors.lua"

function make_boat(x, y)
    return {
        pos = { x = x, y = y },
        prev_pos = { x = x, y = y },
        v = { x = 0, y = 0 },
        ang = 0,
        ang_prev = 0,
        sail = 0.5,
        sail_prev = 0.5,
        sheet = 0.5,
        rudder = 0
    }
end

function get_thrust(wind, sail, velocity, orientation)
 -- compute boat thrust from wind, sail trim, boat velocity, and boat orientation
 apparent = minus(wind, velocity)
 local sail_norm = norm(sail)
 push_force = proj(apparent, sail_norm)

 apparent_norm = norm(apparent)
 -- How close to +0.5 the +dot product is between apparent wind and sail
 parallelism = abs(dot(unit(apparent), unit(sail)))
 local p = parallelism
 -- expressed as a number in [0,1]
 -- parallelism is in [0,1], where 1 is parallel, and 0 is perpendicular.
 -- Since we want the lift to increase proportional to the angle until ~34 degrees,
 lift_mag = (-p^3+.5*p^2) * sign(sail.x)
 -- in the direction of the norm of the apparent wind
 pull_force = scale(lift_mag, apparent_norm)
 
 local lift = plus(push_force, pull_force)
 local thrust = proj(lift, orientation)
 return thrust, mag(push_force)*sign(sail.x)
end
