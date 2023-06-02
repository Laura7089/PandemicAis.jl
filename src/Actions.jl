module Actions

using SumTypes
using Graphs
using Pandemic
using Pandemic: Disease

# TODO: the naming of these should probably correspond with the functions in Pandemic.Actions
# Commented out pending https://github.com/MasonProtter/SumTypes.jl/issues/32
# """
#     PlayerAction{C}
#
# Sum type of actions available to a given player in a given game state.
#
# Obtained with [`possibleactions`](@ref).
# """
@sum_type PlayerAction{C} begin
    Drive{C}(dest::C)
    DirectFlight{C}(dest::C)
    CharterFlight{C}(dest::C)
    ShuttleFlight{C}(dest::C)
    BuildStation
    DiscoverCure{C}(dest::C, cards::Vector{C})
    TreatDisease(target::Disease)
    ShareKnowledge(player::Int)
    Pass
end

export PlayerAction
export Drive,
    DirectFlight,
    CharterFlight,
    ShuttleFlight,
    BuildStation,
    DiscoverCure,
    TreatDisease,
    ShareKnowledge,
    Pass

function Base.show(io::IO, act::PlayerAction)
    @cases act begin
        Drive(c) => write(io, "goto $c")
        DirectFlight(c) => write(io, "direct to $c")
        CharterFlight(c) => write(io, "charter to $c")
        ShuttleFlight(c) => write(io, "shuttle to $c")
        BuildStation => write(io, "build station")
        DiscoverCure(d, _) => write(io, "cure $d")
        TreatDisease(d) => write(io, "treat $d")
        ShareKnowledge(p) => write(io, "share with $p")
        Pass => write(io, "pass")
    end
end

"""
    ismove(action)

Returns `true` if the action is a movement actions, otherwise `false`.
"""
function ismove(act::PlayerAction)::Bool
    @cases act begin
        Drive => true
        DirectFlight => true
        CharterFlight => true
        ShuttleFlight => true
        BuildStation => false
        DiscoverCure => false
        TreatDisease => false
        ShareKnowledge => false
        Pass => false
    end
end

"""
    resolve!(game, action)

Play `action` as the current player of `game`, in the current state.

Mutates `game`.
Calls [`Pandemic.Actions.advanceaction!`](@ref) after the action has been performed and returns the result.

Pass `rng` kwarg to override `game.rng`.
"""
function resolve!(g::Pandemic.Game, act::PlayerAction; rng=nothing)::Tuple{Bool,Bool}
    PActions = Pandemic.Actions
    p = g.playerturn
    ploc = g.playerlocs[p]
    # TODO: ensure all invalid actions throw errors when this is called
    @cases act begin
        Drive(c) => Pandemic.Actions.move_one!(g, p, c)
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

    return PActions.advanceaction!(g; rng=rng)
end

"""
    resolveandbranch(game, action)

Same as with [`resolve!`](@ref) but clones `game` and returns it.

The first item of the tuple is the mutated copy of `game`, the latter two are those from [`advanceaction!`](@ref).
"""
function resolveandbranch(
    g::Pandemic.Game,
    act::PlayerAction;
    rng=nothing,
)::Tuple{Pandemic.Game,Bool,Bool}
    gc = deepcopy(g)
    r = resolve!(gc, act; rng=rng)
    return (gc, r[1], r[2])
end

# TODO: add companion function which can mutate the list after a move without reperforming all checks
"""
    possibleactions(game)

Given `game`, find all possible legal moves for the current player (`game.playerturn`).

# Notes

- For the [`DiscoverCure`](@ref) action in particular, the returned [`Action`](@ref) does **not** contain the cards that will be used.
  These must be added through some other means if desired.
"""
function possibleactions(g::Pandemic.Game)::Vector{PlayerAction}
    if Pandemic.checkstate(g) != Pandemic.Playing
        return []
    end

    # Various helper vars and aliases
    pos = g.playerlocs[g.playerturn]
    hand = g.hands[g.playerturn]
    hasownpos = pos in hand
    stationcities = [c for (c, s) in enumerate(g.stations) if s]
    cities = g.world.cities
    nc = !=(pos) # "not current", function for filtering out current pos
    neighbours = all_neighbors(g.world.graph, pos)

    # NOTE: we create these without checks since they're derived from game state

    actions = Vector{PlayerAction}(undef, 0)
    push!(actions, Pass)

    # Movement
    # Drive
    for c in neighbours
        push!(actions, Drive(c))
    end
    # Direct Flight
    for c in filter(nc, hand)
        push!(actions, DirectFlight(c))
    end
    # Charter Flight
    if hasownpos
        for c in filter(nc, cities)
            push!(actions, CharterFlight(c))
        end
    end
    # Shuttle Flight
    if g.stations[pos]
        for c in filter(nc, stationcities)
            push!(actions, ShuttleFlight(c))
        end
    end

    # Build Station
    if hasownpos && !(pos in stationcities)
        push!(actions, BuildStation)
    end

    # Discover Cure
    if g.stations[pos]
        # Check if relevant cards in hand
        diseasesinpos = filter(instances(Disease)) do d
            count(c -> cities[c].colour == d, hand) >= Pandemic.CARDS_TO_CURE
        end
        for d in diseasesinpos
            push!(actions, DiscoverCure(dis, []))
        end
    end

    # Treat Disease
    for (d, c) in enumerate(g.cubes[pos, :])
        if c > 0
            push!(actions, TreatDisease(Disease(d)))
        end
    end

    # Share Knowledge
    if hasownpos
        for (p, l) in enumerate(g.playerlocs)
            if l == pos
                push!(actions, ShareKnowledge(p))
            end
        end
    end

    return actions
end
export possibleactions

end
