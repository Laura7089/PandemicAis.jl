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
    used::Vector{T} = Vector(undef, 1)
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

    toret = PlayerAction(atype = atype)

#! format: off
    @match atype begin
        Drive || DirectFlight || CharterFlight || ShuttleFlight => begin
            toret.dest = kwargs[:dest]
        end
        DiscoverCure, if haskey(kwargs, :used) end => begin
            toret.used = kwargs[:used]
        end
        TreatDisease => begin toret.treated = kwargs[:treated] end
        ShareKnowledge => begin toret.target = kwargs[:target] end
    end
#! format: on

    return toret
end

"""
    possiblemoves(game)

Given `game`, find all possible legal moves for the current player.

Note that for the [`DiscoverCure`](@ref) action in particular, the returned [`PlayerAction`](@ref) does **not** contain the cards that will be used.
These must be added through some other means if desired.
"""
# TODO: add companion function which can cull the list after a move without reperforming all checks
function possiblemoves(g::Game)::Vec{PlayerAction}
    if g.state != Playing
        return []
    end

    playerpos = g.playerlocs[g.playerturn]
    hand = g.hands[g.playerturn]
    hasownpos = playerpos in hand
    stationcities = [c for (c, s) in g.stations if s]

    # NOTE: we create these without checks since they're derived from game state
    # TODO: test this

    # Movement
    drive = [
        PlayerAction(atype = Drive, dest = c) for
        c in allneighbors(g.world.cities, playerpos)
    ]
    direct = [PlayerAction(atype = DirectFlight, dest = c) for c in hand if c != playerpos]
    charter = if hasownpos
        [
            PlayerAction(atype = CharterFlight, dest = c) for
            c in g.world.cities if c != playerpos
        ]
    else
        []
    end
    shuttle = if g.stations[playerpos]
        [PlayerAction(atype = ShuttleFlight, dest = c) for c in cities if c != playerpos]
    else
        []
    end

    buildstation = if hasownpos
        [PlayerAction(atype = BuildStation)]
    else
        []
    end

    discovercure = [
        PlayerAction(atype = DiscoverCure, cured = dis) for
        dis in filter(instances(Disease)) do d
            numcards = count(hand) do c
                g.world.cities[c].colour == d
            end
            numcards >= CARDS_TO_CURE
        end
    ]

    treatdisease =
        [PlayerAction(atype = TreatDisease, disease = d) for d in g.cubes(playerloc, :)]

    shareknowledge = if hasownpos
        [
            PlayerAction(atype = ShareKnowledge, target = p) for
            (p, l) in g.playerlocs if l == playerloc
        ]
    else
        []
    end

    return vcat(
        drive,
        direct,
        charter,
        shuttle,
        buildstation,
        discovercure,
        treatdisease,
        shareknowledge,
        [Pass],
    )
end

end
