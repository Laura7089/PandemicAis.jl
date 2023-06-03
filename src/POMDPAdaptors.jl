"""
    POMDPAdaptors

Types and objects for interfacting with the (POMDPS.jl)[https://github.com/JuliaPOMDP/POMDPs.jl] ecosystem.
"""
module PODMPAdaptors

using POMDPs
using POMDPTools
using QuickPOMDPs

using PandemicAIs
import PandemicAIs: SingleActions, CompoundActions

function quickmdpsingle(reward)
    QuickMDP(
        actions = SingleActions.possibleactions,
        transition = (s, a) -> Deterministic(resolveandbranch(s, a)[1]),
        statetype = Pandemic.Game,
        actiontype = SingleActions.PlayerAction,
        isterminal = PandemicAIs.isterminal,
        reward = reward,
    )
end

function quickmdpcompound(reward)
    QuickMDP(
        actions = CompoundActions.possiblecompounds,
        transition = (s, a) -> Deterministic(resolveandbranch(s, a)[1]),
        statetype = Pandemic.Game,
        actiontype = CompoundActions.CompoundAction,
        isterminal = PandemicAIs.isterminal,
        reward = reward,
    )
end

function quickmdpfullcompound(reward)
    QuickMDP(
        actions = CompoundActions.possiblefullcompounds,
        transition = (s, a) -> Deterministic(resolveandbranch(s, a)[1]),
        statetype = Pandemic.Game,
        actiontype = CompoundActions.CompoundAction,
        isterminal = PandemicAIs.isterminal,
        reward = reward,
    )
end

end
