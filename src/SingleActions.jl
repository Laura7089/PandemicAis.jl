module SingleActions

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
export ismove

# TODO: add companion function which can mutate the list after a move without reperforming all checks
"""
    possibleactions(game)

Given `game`, find all possible legal actions for the current player (`game.playerturn`).

# Notes

- For the [`DiscoverCure`](@ref) action in particular, the returned [`Action`](@ref) does **not** contain the cards that will be used.
  These must be added through some other means if desired.

See also [`possiblemoves`](@ref), [`possiblenonmoves`](@ref).
"""
function possibleactions(g::Pandemic.Game)::Vector{PlayerAction}
    vcat(possiblemoves(g), possiblenonmoves(g))
end
export possibleactions

"""
    possiblemoves(game)

Given `game`, find all possible legal **moves** for the current player (`game.playerturn`).

See also [`possibleactions`](@ref), [`possiblenonmoves`](@ref).
"""
function possiblemoves(g::Pandemic.Game)::Vector{PlayerAction}
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
    moves = Vector{PlayerAction}(undef, 0)

    # Drive
    for c in neighbours
        push!(moves, Drive(c))
    end
    # Direct Flight
    for c in filter(nc, hand)
        push!(moves, DirectFlight(c))
    end
    # Charter Flight
    if hasownpos
        for c in filter(nc, map(city -> Pandemic.cityindex(g.world, city), cities))
            push!(moves, CharterFlight(c))
        end
    end
    # Shuttle Flight
    if g.stations[pos]
        for c in filter(nc, stationcities)
            push!(moves, ShuttleFlight(c))
        end
    end

    return moves
end

"""
    possiblenonmoves(game)

Given `game`, find all possible legal **non-moves** for the current player (`game.playerturn`).

# Notes

- For the [`DiscoverCure`](@ref) action in particular, the returned [`Action`](@ref) does **not** contain the cards that will be used.
  These must be added through some other means if desired.

See also [`possibleactions`](@ref), [`possiblemoves`](@ref).
"""
function possiblenonmoves(g::Pandemic.Game)::Vector{PlayerAction}
    if Pandemic.checkstate(g) != Pandemic.Playing
        return []
    end

    # Various helper vars and aliases
    pos = g.playerlocs[g.playerturn]
    hand = g.hands[g.playerturn]
    hasownpos = pos in hand
    stationcities = [c for (c, s) in enumerate(g.stations) if s]
    cities = g.world.cities

    # NOTE: we create these without checks since they're derived from game state
    actions = PlayerAction[Pass]

    # Build Station
    if hasownpos && !(pos in stationcities)
        push!(actions, BuildStation)
    end
    # Discover Cure
    if g.stations[pos]
        # Check if relevant cards in hand
        diseasesinpos = filter(instances(Disease)) do d
            count(c -> cities[c].colour == d, hand) >= g.settings.cards_to_cure
        end
        for d in diseasesinpos
            push!(actions, DiscoverCure(d, []))
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
            # We can't share knowledge with ourself
            if l == pos && p != g.playerturn
                push!(actions, ShareKnowledge(p))
            end
        end
    end

    return actions
end

end
