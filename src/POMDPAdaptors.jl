"""
    POMDPAdaptors

Types and objects for interfacting with the (POMDPS.jl)[https://github.com/JuliaPOMDP/POMDPs.jl] ecosystem.
"""
module PODMPAdaptors

using POMDPs
using QuickPOMDPs

using PandemicAIs

function getquickmdp()
    # TODO: use the `_rng` arg
    genfunc =
        (cur, act, _rng) -> (sp = PandemicAIs.Actions.branchandresolve(cur, act), r = 1.0)
    isterminal = (state) -> Pandemic.checkstate!(state) != Pandemic.Playing

    QuickMDP(
        genfunc,
        actions = PandemicAIs.Actions.possibleactions,
        statetype = PandemicAIs.Pandemic.Game,
        actiontype = PandemicAIs.Actions.PlayerAction,
        isterminal = isterminal,
    )
end

end
