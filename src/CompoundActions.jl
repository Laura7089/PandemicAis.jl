# TODO: should this be a submodule of `Actions`?
"""
    CompoundActions

Logic for creating "compound actions" from regular [`PandemicAIs.PlayerAction`](@ref)s.

Inspired by the "macro actions" found in the work of Sfikas and Liapis[1].

[1] K. Sfikas and A. Liapis, “Collaborative Agent Gameplay in the Pandemic Board Game,” in Proceedings of the 15th International Conference on the Foundations of Digital Games, in FDG ’20. New York, NY, USA: Association for Computing Machinery, Sep. 2020, pp. 1–11. doi: 10.1145/3402942.3402943.
"""
module CompoundActions

using SumTypes
using Pandemic
using PandemicAIs
using PandemicAIs.Actions
using Pandemic.Graphs

"""
    possiblecompounds(game)

Calculate all possible "compound actions" available to the current player in `game`.

# Notes

- All sequences consist of zero or more move actions, followed by an optional other action
- If a move sequence which spends no cards for a particular destination is found, only that sequence will be used to move there
- No sequences which lead beyond the end of the player's turn will be examined
"""
function possiblecompounds(game)
    acts = []
    foundmoves = []

    # TODO
end
export possiblecompounds
end
