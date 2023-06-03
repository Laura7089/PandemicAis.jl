#!/bin/julia --project

using MCTS
using PandemicAIs
using PandemicAIs.Actions
using POMDPs
using POMDPTools
using SumTypes

function basicreward(prevstate, action, state)::Float64
    gs = Pandemic.checkstate(state)

    if state == Pandemic.Lost
        return -100.0
    end
    if state == Pandemic.Won
        return 1000.0
    end

    return @cases action begin
        Pass => -5.0
        CharterFlight => -2.0
        DirectFlight => -2.0
        Drive => -1.0
        ShuttleFlight => -1.0
        TreatDisease => 5.0
        BuildStation => 10.0
        ShareKnowledge => 10.0
        DiscoverCure => 50.0
    end

    # if action == Actions.Pass
    #     return -2.0
    # end
    # if action == Actions.DiscoverCure
	# return 100.0
    # end

    # return -1.0
end

g = Pandemic.newgame(Pandemic.Maps.vanillamap(), Pandemic.Heroic, 4)
mdp = PandemicAIs.PODMPAdaptors.getquickmdp(basicreward)
solver = MCTSSolver(reuse_tree=true)
planner = solve(solver, mdp)

# sim = HistoryRecorder(max_steps=30)
# res = simulate(sim, mdp, planner, g)

for (s, a, _, r) in stepthrough(mdp, planner, g)
    println("took action $a for reward $r, state: $(Pandemic.checkstate(s))")
end

# while !PandemicAIs.isterminal(g)
#     next_act = action(planner, g)
#     println(next_act)
#     PandemicAIs.Actions.resolve!(g, next_act)
# end
