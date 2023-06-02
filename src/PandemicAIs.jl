module PandemicAIs

include("./CompoundActions.jl")
include("./Actions.jl")
using .Actions

using Pandemic
export Pandemic

using PrecompileTools

@compile_workload begin
    map = Pandemic.Maps.vanillamap()
    g = Pandemic.newgame(map, Pandemic.Introductory, 4)
    for act in Actions.possibleactions(g)
        branch = Actions.resolveandbranch(g, act)
    end
end

end
