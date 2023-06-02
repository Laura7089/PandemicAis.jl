"""
    POMDPAdaptors

Types and objects for interfacting with the (POMDPS.jl)[https://github.com/JuliaPOMDP/POMDPs.jl] ecosystem.
"""
module PODMPAdaptors

using POMDPs
using QuickPOMDPs

using PandemicAIs
import PandemicAIs: Actions

function getquickmdp()
    # TODO: use the `_rng` arg
    function genfunc(cur, act, _rng)
        next = Actions.resolveandbranch(cur, act)[1]
        # De-incentivise doing nothing
        reward = if act == Actions.Pass 0.0 else 1.0 end
        (sp = next, r = reward)
    end
    isterminal = (state) -> Pandemic.checkstate!(state) != Pandemic.Playing

    QuickMDP(
        genfunc,
        actions = Actions.possibleactions,
        statetype = Pandemic.Game,
        actiontype = Actions.PlayerAction,
        isterminal = isterminal,
    )
end

end
