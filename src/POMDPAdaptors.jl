"""
    POMDPAdaptors

Types and objects for interfacting with the (POMDPS.jl)[https://github.com/JuliaPOMDP/POMDPs.jl] ecosystem.
"""
module POMDPAdaptors

using POMDPs
using POMDPTools
using QuickPOMDPs

using PandemicAIs
import PandemicAIs: SingleActions, CompoundActions

"""
    basicmdp(actions, actiontype, reward)

Wraps a call to [`QuickMDP`](@ref) with some sane defaults.

The arguments to this function are pass through as keyword arguments, but others are preset:

- `transition`: state output of [`PandemicAIs.resolveandbranch`](@ref)
- `statetype`: [`Pandemic.Game`](@ref)
- `isterminal`: [`PandemicAIs.isterminal`](@ref)

See also [`singleaction`](@ref), [`compound`](@ref), [`compoundfull`](@ref).
"""
function basicmdp(actions, actiontype, reward)
    QuickMDP(
        actions = actions,
        actiontype = actiontype,
        reward = reward,
        transition = (s, a) -> Deterministic(resolveandbranch(s, a)[1]),
        statetype = Pandemic.Game,
        isterminal = PandemicAIs.isterminal,
    )
end
export basicmdp

"""
    singleaction(reward)

Create an MDP with [`SingleActions.PlayerAction`](@ref)s as steps.

`reward` is the reward function for the MDP.

See also [`basicmdp`](@ref), [`compound`](@ref), [`compoundfull`](@ref).
"""
function singleaction(reward)
    basicmdp(SingleActions.possibleactions, SingleActions.PlayerAction, reward)
end
export singleaction

"""
    compound(reward)

Create an MDP with [`CompoundActions.CompoundAction`](@ref)s as steps.

`reward` is the reward function for the MDP.

See also [`basicmdp`](@ref), [`singleaction`](@ref), [`compoundfull`](@ref).
"""
function compound(reward)
    basicmdp(CompoundActions.possiblecompounds, CompoundActions.CompoundAction, reward)
end
export compound

"""
    compoundfull(reward)

As with [`compound`](@ref), but only considers actions which take an entire player turn.

`reward` is the reward function for the MDP.

See also [`basicmdp`](@ref), [`singleaction`](@ref), [`compound`](@ref).
"""
function fullcompound(reward)
    basicmdp(CompoundActions.possiblefullcompounds, CompoundActions.CompoundAction, reward)
end
export compoundfull

end
