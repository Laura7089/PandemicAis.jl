module PandemicAIs

using Parameters
using Match
using Graphs

using Pandemic
using Pandemic: Disease

export Pandemic

Option{T} = Union{T,Nothing}

"""
    PlayerActionType

The type of a player action.

Can be any of `Drive`, `DirectFlight`, `CharterFlight`, `ShuttleFlight`, `BuildStation`, `DiscoverCure`, `TreatDisease`, `Pass` or `ShareKnowledge`.

See also [`PlayerAction`](@ref).
"""
@enum PlayerActionType begin
    Drive
    DirectFlight
    CharterFlight
    ShuttleFlight
    BuildStation
    DiscoverCure
    TreatDisease
    ShareKnowledge
    Pass
end
export PlayerActionType

"""
    PlayerAction{T}

Represents an action from a player.

This struct coupled with the game state of an in-progress game contain the required context to perform the action.
On it's own, this struct is not enough.

`T` is the type referring to any cities that are relevant to the action.
"""
@with_kw struct PlayerAction{T}
    atype::PlayerActionType
    dest::Option{T} = nothing
    used::Vector{T} = Vector(undef, 0)
    treated::Option{Disease} = nothing
    shared::Option{T} = nothing
    target::Option{Int} = nothing
end
export PlayerAction

"""
    PlayerAction(actiontype; kwargs...)

Create a checked player action.

You should observe the following checks:

- If creating a move action (any of [`Drive`](@ref), [`DirectFlight`](@ref), [`CharterFlight`](@ref) or [`ShuttleFlight`](@ref)), you **must** provide the `dest =` keyword argument.
- If curing ([`DiscoverCure`](@ref)) you may pass the `used =` keyword argument to control which cards from the player's hand will be used; otherwise they will be selected automatically.
- If treating a disease ([`TreatDisease`](@ref)) you **must** pass the `treated =` keyword argument to indicate which disease is to be treated.
- If sharing knowledge with another player ([`ShareKnowledge`](@ref)) you **must** provide the `target =` argument for the target player.

Using this function otherwise will result in an error.
"""
function PlayerAction(atype; kwargs...)
    kwargs = Dict(kwargs)

#! format: off
    @match atype begin
        Drive || DirectFlight || CharterFlight || ShuttleFlight =>
            PlayerAction(atype = atype, dest = kwargs[:dest])
        DiscoverCure => if haskey(kwargs, :used)
            PlayerAction(atype = atype, used = kwargs[:used])
        else
            PlayerAction(atype = atype)
        end
        TreatDisease => PlayerAction(atype = atype, treated = kwargs[:treated])
        ShareKnowledge => PlayerAction(atype = atype, target = kwargs[:target])
        _ => PlayerAction(atype = atype)
    end
#! format: on
end

# TODO: the matches in the above and below functions are bugged

function Base.show(io::IO, act::PlayerAction)
    show(io, act.atype)

#! format: off
    @match act.atype begin
        Drive || DirectFlight || CharterFlight || ShuttleFlight => print(io, " dest=$(act.dest)")
        DiscoverCure => if haskey(kwargs, :used)
            print(io, " used=$(act.used)")
        else
            print(io, " used=auto")
        end
        TreatDisease => print(io, " treated=$(act.treated)")
        ShareKnowledge => print(io, " target=$(act.target)")
    end
#! format: on
end

# TODO: add companion function which can mutate the list after a move without reperforming all checks
"""
    possiblemoves(game)

Given `game`, find all possible legal moves for the current player (`game.playerturn`).

# Notes

- For the [`DiscoverCure`](@ref) action in particular, the returned [`PlayerAction`](@ref) does **not** contain the cards that will be used.
  These must be added through some other means if desired.
"""
function possiblemoves(g::Game)::Vector{PlayerAction}
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
    Act = PlayerAction # type alias
    neighbours = all_neighbors(g.world.graph, pos)

    # NOTE: we create these without checks since they're derived from game state
    # TODO: test this

    actions = [PlayerAction(atype = Pass)]

    # Movement
    # Drive
    for c in neighbours
        push!(actions, Act(atype = Drive, dest = c))
    end
    # Direct Flight
    for c in filter(nc, hand)
        push!(actions, Act(atype = DirectFlight, dest = c))
    end
    # Charter Flight
    if hasownpos
        for c in filter(nc, cities)
            push!(actions, Act(atype = CharterFlight, dest = c))
        end
    end
    # Shuttle Flight
    if g.stations[pos]
        for c in filter(nc, stationcities)
            push!(actions, Act(atype = ShuttleFlight, dest = c))
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
            push!(actions, Act(atype = DiscoverCure, cured = dis))
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
                push!(actions, Act(atype = ShareKnowledge, target = p))
            end
        end
    end

    return actions
end
export possiblemoves

end
