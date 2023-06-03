"""
    POMDPAdaptors

Types and objects for interfacting with the (POMDPS.jl)[https://github.com/JuliaPOMDP/POMDPs.jl] ecosystem.
"""
module PODMPAdaptors

using POMDPs
using POMDPTools
using QuickPOMDPs

using PandemicAIs
import PandemicAIs: SingleActions

function getquickmdp(reward)
    QuickMDP(
        actions = SingleActions.possibleactions,
        transition = (s, a) -> Deterministic(resolveandbranch(s, a)[1]),
        statetype = Pandemic.Game,
        actiontype = SingleActions.PlayerAction,
        isterminal = PandemicAIs.isterminal,
        reward = reward,
    )
end

end
