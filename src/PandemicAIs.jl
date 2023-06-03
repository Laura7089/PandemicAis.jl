module PandemicAIs

include("./SingleActions.jl")
include("./CompoundActions.jl")
include("./POMDPAdaptors.jl")

using Pandemic
export Pandemic
using .SingleActions

using PrecompileTools
using SumTypes

"""
    isterminal(game)

Checks if `game` is in a terminal state.
"""
function isterminal(game)
    state = Pandemic.checkstate(game)
    if state == Pandemic.Won
        @info "Found winning state" state
    end

    return state != Pandemic.Playing
end

"""
    resolve!(game, action)

Play `action` as the current player of `game`, in the current state.

Pass a non-empty `AbstractVector` as `action` to perform a sequence of actions.
Mutates `game`.
Calls [`Pandemic.SingleActions.advanceaction!`](@ref) after the action has been performed and returns the result.
"""
function resolve!(
    g::Pandemic.Game,
    act::SingleActions.PlayerAction;
    rng = nothing,
)::Tuple{Bool,Bool}
    PActions = Pandemic.Actions
    p = g.playerturn
    ploc = g.playerlocs[p]
    # TODO: ensure all invalid actions throw errors when this is called
    @cases act begin
        Drive(c) => PActions.move_one!(g, p, c)
        DirectFlight(c) => PActions.move_direct!(g, p, c)
        CharterFlight(c) => PActions.move_chartered!(g, p, c)
        ShuttleFlight(c) => PActions.move_station!(g, p, c)
        # TODO: this will crash if we have all stations in play
        BuildStation => PActions.buildstation!(g, p, g.playerlocs[p])
        DiscoverCure(d) => PActions.findcure!(g, p, d)
        # TODO: this doesn't provide a way to treat disease cubes which aren't in the city
        TreatDisease(d) => PActions.treatdisease!(g, p, ploc, d)
        ShareKnowledge(p2) => PActions.shareknowledge!(g, p, p2, ploc)
        Pass => PActions.pass!(g)
    end

    return PActions.advanceaction!(g; rng = rng)
end
"""
    resolve!(game, action)

Play the [`CompoundActions.CompoundAction`](@ref) `action` out from on `game`.

If a component of `action` ends the game, this function will stop iterating.
Returns `(l, r)` where `l` indicates if the player turn changed and `r` indicates if the round changed.

Pass `rng` kwarg to override `game.rng`.
"""
function resolve!(
    g::Game,
    acts::CompoundActions.CompoundAction;
    rng = nothing,
)::Tuple{Bool,Bool}
    if length(acts) == 0
        throw(error("empty action set passed"))
    end
    turnchanged = false
    roundchanged = false

    for act in acts
        l, r = resolve!(g, act; rng = rng)
        turnchanged |= l
        roundchanged |= r
        if l && isterminal(g)
            break
        end
    end

    return (turnchanged, roundchanged)
end
export resolve!

"""
    resolveandbranch(game, action)

Same as with [`resolve!`](@ref) but clones `game` and returns it.

The first item of the returned tuple is the mutated copy of `game`, the latter two are those from [`resolve!`](@ref).
"""
function resolveandbranch(
    g::Pandemic.Game,
    act;
    rng = nothing,
)::Tuple{Pandemic.Game,Bool,Bool}
    gc = deepcopy(g)
    r = resolve!(gc, act; rng = rng)
    return (gc, r[1], r[2])
end
export resolveandbranch

@compile_workload begin
    map = Pandemic.Maps.vanillamap()
    g = Pandemic.newgame(map, Pandemic.Settings(4, Pandemic.Introductory))
    for act in SingleActions.possibleactions(g)
        branch = resolveandbranch(g, act)
    end
end

end
