module PandemicAIs

include("./CompoundActions.jl")
include("./Actions.jl")

include("./POMDPAdaptors.jl")

using Pandemic
export Pandemic

using PrecompileTools

"""
    isterminal!(game)

Checks if `game` is in a terminal state, with [`Pandemic.checkstate!`](@ref).
"""
function isterminal!(game)::Bool
    Pandemic.checkstate!(game) != Pandemic.Playing
end

@compile_workload begin
    map = Pandemic.Maps.vanillamap()
    g = Pandemic.newgame(map, Pandemic.Introductory, 4)
    for act in Actions.possibleactions(g)
        branch = Actions.resolveandbranch(g, act)
    end
end

end
