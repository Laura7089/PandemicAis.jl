"""
    POMDPAdaptors

Types and objects for interfacting with the (POMDPS.jl)[https://github.com/JuliaPOMDP/POMDPs.jl] ecosystem.
"""
module PODMPAdaptors

using POMDPs
using QuickPOMDPs

using PandemicAIs
import PandemicAIs: Actions

"""
    basicreward!(state, previousaction; default=1.0, pass=0.0, loss=-100.0, win=100.0)

Simple function for rewards.
`state` is the game state which was obtained through `previousaction`.
This function must modify `state` because [`Pandemic.checkstate!`](@ref) does.

Allows passing reward amounts in, which are returned based on the state of the game:
- `win` and `loss` for the respective game ends
- `pass` if `previousaction` is [`Actions.Pass`](@ref); intended to de-incentivise doing nothing
- `default` if none of the above apply
"""
function basicreward!(
    state,
    prevaction;
    default = 1.0,
    pass = 0.0,
    loss = -100.0,
    win = 100.0,
)::Float64
    gs = Pandemic.checkstate!(state)

    if state == Pandemic.Lost
        return loss
    end
    if state == Pandemic.Won
        return win
    end
    if prevaction == Actions.Pass
        return pass
    end
    return default
end


function getquickmdp()
    # TODO: use the `_rng` arg
    function genfunc(cur, act, _rng)
        next = Actions.resolveandbranch(cur, act)[1]
        reward = basicreward!(next, act)
        (sp = next, r = reward)
    end
    isterminal = PandemicAIs.isterminal!

    QuickMDP(
        genfunc,
        actions = Actions.possibleactions,
        statetype = Pandemic.Game,
        actiontype = Actions.PlayerAction,
        isterminal = isterminal,
    )
end

end
