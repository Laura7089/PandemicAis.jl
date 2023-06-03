"""
    POMDPAdaptors

Types and objects for interfacting with the (POMDPS.jl)[https://github.com/JuliaPOMDP/POMDPs.jl] ecosystem.
"""
module PODMPAdaptors

using POMDPs
using POMDPTools
using QuickPOMDPs

using PandemicAIs
import PandemicAIs: Actions

function getquickmdp(reward)
    QuickMDP(
        actions = Actions.possibleactions,
        transition = (s, a) -> Deterministic(Actions.resolveandbranch(s, a)[1]),
        statetype = Pandemic.Game,
        actiontype = Actions.PlayerAction,
        isterminal = PandemicAIs.isterminal,
        reward = reward,
    )
end

end
