module PandemicAIs

using Parameters
using Match
using Graphs
using SumTypes

using Pandemic
using Pandemic: Disease

export Pandemic

"""
    PlayerAction{C}

Sum type of actions available to a given player in a given game state.

Obtained with [`possibleactions`](@ref).
"""
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

# TODO: add companion function which can mutate the list after a move without reperforming all checks
"""
    possibleactions(game)

Given `game`, find all possible legal moves for the current player (`game.playerturn`).

# Notes

- For the [`DiscoverCure`](@ref) action in particular, the returned [`Action`](@ref) does **not** contain the cards that will be used.
  These must be added through some other means if desired.
"""
function possibleactions(g::Game)::Vector{PlayerAction}
    if g.state != Pandemic.Playing
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
    # TODO: test this

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
            push!(actions, DiscoverCure(dis))
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
