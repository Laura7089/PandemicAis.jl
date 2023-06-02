# TODO: should this be a submodule of `Actions`?
"""
    CompoundActions

Contains logic for creating "compound actions"([`CompoundActions.CompoundAction`](@ref)) from regular [`PandemicAIs.PlayerAction`](@ref)s.

Inspired by the "macro actions" found in the work of Sfikas and Liapis[1].

[1] K. Sfikas and A. Liapis, “Collaborative Agent Gameplay in the Pandemic Board Game,” in Proceedings of the 15th International Conference on the Foundations of Digital Games, in FDG ’20. New York, NY, USA: Association for Computing Machinery, Sep. 2020, pp. 1–11. doi: 10.1145/3402942.3402943.
"""
module CompoundActions

using SumTypes
using Pandemic
using PandemicAIs

@sum_type CompoundAction{C} begin

end

end
