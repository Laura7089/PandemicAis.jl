"""
    CompoundActions

Logic for creating "compound actions" from regular [`PandemicAIs.PlayerAction`](@ref)s.

Inspired by the "macro actions" found in the work of Sfikas and Liapis[1].

See also [`PandemicAIs.SingleActions`](@ref).

[1] K. Sfikas and A. Liapis, “Collaborative Agent Gameplay in the Pandemic Board Game,” in Proceedings of the 15th International Conference on the Foundations of Digital Games, in FDG ’20. New York, NY, USA: Association for Computing Machinery, Sep. 2020, pp. 1–11. doi: 10.1145/3402942.3402943.
"""
module CompoundActions

using SumTypes
using Pandemic
using PandemicAIs
using PandemicAIs.SingleActions
using Pandemic.Graphs

CompoundAction = Vector{SingleActions.PlayerAction}
export CompoundAction

"""
    possiblecompounds(game)

Calculate all possible "compound actions" available to the current player in `game`.

# Notes

- All sequences consist of zero or more move actions (see [`SingleActions.ismove`](@ref)), followed by an optional other action
- If a move sequence which spends no cards for a particular destination is found, only that sequence will be used to move there unless shorter, costlier routes are found
- No sequences which lead beyond the end of the player's turn will be examined
"""
function possiblecompounds(game; ignorecities = Set())::Vector{CompoundAction}
    acts = []
    numacts = game.actionsleft
    pl = game.playerlocs[game.playerturn]
    push!(ignorecities, pl)

    # Stay where we are
    for act in PandemicAIs.SingleActions.possiblenonmoves(game)
        push!(acts, [act])
    end

    # Shuttle Flights
    if game.stations[pl]
        otherstations = filter(!=(pl), Pandemic.stations(game))
        svisit = setdiff(otherstations, ignorecities)
        push!.(Ref(ignorecities), svisit)
        for c in svisit
            push!(acts, [ShuttleFlight(c)])
        end
        if numacts > 1
            for dest in svisit
                next = resolveandbranch(game, ShuttleFlight(dest))[1]
                for act in possiblecompounds(next, ignorecities = ignorecities)
                    push!(acts, vcat([ShuttleFlight(dest)], act))
                end
            end
        end
    end

    # Driving
    drvisit = setdiff(Graphs.neighbors(game.world, pl), ignorecities)
    push!.(Ref(ignorecities), drvisit)
    for c in drvisit
        push!(acts, [Drive(c)])
    end
    if numacts > 1
        for dest in drvisit
            next = resolveandbranch(game, Drive(dest))[1]
            for act in possiblecompounds(next, ignorecities = ignorecities)
                push!(acts, vcat([Drive(dest)], act))
            end
        end
    end

    hand = game.hands[game.playerturn]

    # Direct Flights
    dvisit = setdiff(filter(!=(pl), hand), ignorecities)
    push!.(Ref(ignorecities), dvisit)
    for c in dvisit
        push!(acts, [DirectFlight(c)])
    end
    if numacts > 1
        for dest in dvisit
            next = resolveandbranch(game, DirectFlight(dest))[1]
            for act in possiblecompounds(next, ignorecities = ignorecities)
                push!(acts, vcat([DirectFlight(dest)], act))
            end
        end
    end

    # Charter Flights
    if pl in hand
        cvisit = collect(1:length(game.world.cities))
        popat!(cvisit, pl)
        setdiff!(cvisit, ignorecities)
        for c in cvisit
            push!(acts, [CharterFlight(c)])
        end
        if numacts > 1
            for dest in cvisit
                next = resolveandbranch(game, CharterFlight(dest))[1]
                for act in possiblecompounds(next, ignorecities = ignorecities)
                    push!(acts, vcat([CharterFlight(dest)], act))
                end
            end
        end
    end

    return acts
end
export possiblecompounds

# TODO: this isn't very useful, it needs to allow multiple non-movement actions per round but it doesn't
"""
    possiblefullcompounds(g)

As with [`possiblecompounds`](@ref), but only return actions which would end the player's turn.
"""
function possiblefullcompounds(g)
    na = g.actionsleft
    acts = possiblecompounds(g)
    filter!(ca -> length(ca) == na, acts)
    return acts
end

"""
    terminalact(comaction)

Get the final [`SingleActions.PlayerAction`] from `comaction`.
"""
terminalact(ca::CompoundAction) = last(ca)
export terminalact

"""
    finalcity(comaction)

Get the city that a player would end up in after taking `comaction`.

Returns `nothing` if there are no movement actions in `comaction`.
"""
function finalcity(ca::CompoundAction)
    ind = findlast(ca) do act
        SingleActions.ismove(act)
    end
    ca[ind] |> dest
end
export finalcity

# TODO: test this
"""
    cull(game, comaction)

Remove components of a compound action that would happen after the game ended.

If the game wouldn't end, returns the action as-is.
This has no effect on the output of [`possiblecompounds`](@ref).
"""
function cull(game, ca::CompoundAction)::CompoundAction
    culled = []

    g = deepcopy(game)
    for act in acts
        l, r = resolve!(g, act; rng = rng)
        push!(culled, act)
        if l && isterminal(g)
            break
        end
    end

    return culled
end

end
