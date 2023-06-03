#!/bin/julia --project

using MCTS
using PandemicAIs
using PandemicAIs.SingleActions
using POMDPs
using POMDPTools
using SumTypes
using Logging

# global_logger(SimpleLogger(Logging.Debug))

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
        CharterFlight => -5.0
        DirectFlight => -5.0
        Drive => -1.0
        ShuttleFlight => -1.0
        TreatDisease => 10.0
        BuildStation => 30.0
        ShareKnowledge => 100.0
        DiscoverCure => 500.0
    end
end

g = Pandemic.newgame(Pandemic.Maps.vanillamap(), Pandemic.Settings(2, Pandemic.Introductory))
mdp = PandemicAIs.PODMPAdaptors.quickmdpcompound(basicreward)
solver = MCTSSolver()
planner = solve(solver, mdp)

# Remove epidemics
# g.drawpile = [c for c in g.drawpile if c != 0]

# sim = HistoryRecorder(max_steps=30)
# res = simulate(sim, mdp, planner, g)

@info "Starting sim"
for (n, (s, a, _, r)) in enumerate(stepthrough(mdp, planner, g))
    p = s.playerturn
    println("p$p: $a (reward $r)")

    nextstate = with_logger(SimpleLogger(Logging.Debug)) do
        resolveandbranch(s, a)[1]
    end
    gs = with_logger(SimpleLogger(Logging.Debug)) do
        Pandemic.checkstate(nextstate)
    end

    if n % s.settings.actions_per_turn == 0
        println()
        println(nextstate)
        println("lasted $n actions")
        println()
    end
end

# while !PandemicAIs.isterminal(g)
#     next_act = action(planner, g)
#     println(next_act)
#     resolve!(g, next_act)
# end
