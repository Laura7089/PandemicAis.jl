using PandemicAIs

MAP = Pandemic.Maps.circle12()

function testgame(seed=nothing)
    Pandemic.newgame(Pandemic.Maps.circle12(), Pandemic.Settings(4, Pandemic.Introductory), MersenneTwister(seed))
end

include("./SingleActions.jl")
include("./CompoundActions.jl")
