"""
    Rewards

Contains a collection of functions that implement rewards based on states or actions.
"""
module Rewards

using Pandemic

"""
    cure_progress(game)

Get a fraction [0,1] of diseases cured.
"""
function cure_progress(g::Game)::Float64
    cured = count(g.diseases) do d
        d == Pandemic.Cured || d == Pandemic.Eradicated
    end
    return cured / length(g.diseases)
end
export cure_progress

"""
    num_outbreaks(game)

Get a fraction [0,1] of outbreaks which have occurred out of the amount which incurs loss.
"""
function num_outbreaks(g::Game)::Float64
    return (g.settings.max_outbreaks - g.outbreaks) / g.settings.max_outbreaks
end
export num_outbreaks

"""
    num_stations(game)

Get a fraction [0,1] of stations in play vs maximum stations in the game.
"""
function num_stations(g::Game)::Float64
    return count(g.stations) / g.settings.max_stations
end
export num_stations

"""
    CubeSaturation

Reward functions related to relative amounts of cubes in play.
"""
module CubeSaturation

using Pandemic

"""
    for_disease(game, disease)

Get a fraction [0,1] of cubes **out of play** out of the possible cubes for `disease`.
"""
function for_disease(g::Game, dis::Pandemic.Disease)::Float64
    return 1.0 - (cubesinplay(g, dis) / g.settings.cubes_per_disease)
end
export for_disease

"""
    avg_all(game)

Get the fraction [0,1] of cubes **out of play** out of possible cubes for all diseases.
"""
function avg_all(g::Game)::Float64
    return sum(g.cubes) / (length(instances(Disease)) * g.settings.cubes_per_disease)
end
export avg_all

"""
    max_all(game)

Get the fraction [0,1] of cubes **out of play** out of possible cubes for the disease for which it is **highest**.
"""
function max_all(g::Game)::Float64
    return max(for_disease.(Ref(g), instances(Disease))...)
end
export max_all

"""
    min_all(game)

Get the fraction [0,1] of cubes **out of play** out of possible cubes for the disease for which it is **lowest**.
"""
function min_all(g::Game)::Float64
    return min(for_disease.(Ref(g), instances(Disease))...)
end
export min_all

end
export CubeSaturation

end
