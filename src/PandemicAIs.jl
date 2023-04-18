module PandemicAIs

using Parameters
using Match
using Graphs

using Pandemic
using Pandemic: Disease

export Pandemic

module PlayerActions
    using Pandemic: Disease

    """
        Action

    Some action taken by a player, costing one action point.

    See also [`Drive`](@ref), [`DirectFlight`](@ref), [`CharterFlight`](@ref), [`ShuttleFlight`](@ref), [`BuildStation`](@ref), [`DiscoverCure`](@ref), [`TreatDisease`](@ref), [`ShareKnowledge`](@ref), [`Pass`](@ref).
    """
    abstract type Action end
    export Action

    struct Drive{C} <: Action
        dest::C
    end
    struct DirectFlight{C} <: Action
        dest::C
    end
    struct CharterFlight{C} <: Action
        dest::C
    end
    struct ShuttleFlight{C} <: Action
        dest::C
    end
    struct BuildStation <: Action end
    struct DiscoverCure{C} <: Action
        usedcards::Union{Vector{C},Nothing}
    end
    struct TreatDisease <: Action
        disease::Disease
    end
    struct ShareKnowledge <: Action
        targetplayer::Int
    end
    struct Pass <: Action end
end
using .PlayerActions
export PlayerActions

# TODO: add companion function which can mutate the list after a move without reperforming all checks
"""
    possibleactions(game)

Given `game`, find all possible legal moves for the current player (`game.playerturn`).

# Notes

- For the [`DiscoverCure`](@ref) action in particular, the returned [`Action`](@ref) does **not** contain the cards that will be used.
  These must be added through some other means if desired.
"""
function possibleactions(g::Game)::Vector{Action}
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

    actions = Vector{Action}(undef, 0)
    push!(actions, PlayerActions.Pass)

    # Movement
    # Drive
    for c in neighbours
        push!(actions, PlayerActions.Drive(c))
    end
    # Direct Flight
    for c in filter(nc, hand)
        push!(actions, PlayerActions.DirectFlight(c))
    end
    # Charter Flight
    if hasownpos
        for c in filter(nc, cities)
            push!(actions, PlayerActions.CharterFlight(c))
        end
    end
    # Shuttle Flight
    if g.stations[pos]
        for c in filter(nc, stationcities)
            push!(actions, PlayerActions.ShuttleFlight(c))
        end
    end

    # Build Station
    if hasownpos && !(pos in stationcities)
        push!(actions, Act(atype = BuildStation))
    end

    # Discover Cure
    if g.stations[pos]
        # Check if relevant cards in hand
        diseasesinpos = filter(instances(Disease)) do d
            count(c -> cities[c].colour == d, hand) >= Pandemic.CARDS_TO_CURE
        end
        for d in diseasesinpos
            push!(actions, PlayerActions.DiscoverCure(dis))
        end
    end

    # Treat Disease
    for (d, c) in enumerate(g.cubes[pos, :])
        if c > 0
            push!(actions, Act(atype = TreatDisease, treated = Disease(d)))
        end
    end

    # Share Knowledge
    if hasownpos
        for (p, l) in enumerate(g.playerlocs)
            if l == pos
                push!(actions, PlayerActions.ShareKnowledge(p))
            end
        end
    end

    return actions
end
export possibleactions

end
