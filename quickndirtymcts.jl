#!/bin/julia --project

using MCTS
using PandemicAIs
using PandemicAIs.SingleActions
using PandemicAIs.CompoundActions
using POMDPs
using POMDPTools
using SumTypes
using Logging

function basicreward(action)::Float64
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

function compoundreward(prevstate, caction, state)::Float64
    map(basicreward, caction) |> sum
end

g = Pandemic.newgame(
    Pandemic.Maps.vanillamap(),
    Pandemic.Settings(
        2,
        Pandemic.Introductory;
        cards_to_cure=2,
    ),
)
mdp = PandemicAIs.POMDPAdaptors.compound(compoundreward)
solver = MCTSSolver(
    max_time=100.0,
    n_iterations=30,
    depth=5,
    estimate_value=(_, s, _) -> PandemicAIs.Rewards.CubeSaturation.max_all(s),
)
planner = solve(solver, mdp)

# Remove epidemics
# g.drawpile = [c for c in g.drawpile if c != 0]

# sim = HistoryRecorder(max_steps=30)
# res = simulate(sim, mdp, planner, g)

@info "Starting sim"
for (n, (s, a, _, r)) in enumerate(stepthrough(mdp, planner, g))
    p = s.playerturn
    println("p$p: $a (reward $r)")

    nextstate, gs = with_logger(SimpleLogger(Logging.Info)) do
        ns = resolveandbranch(s, a)[1]
        (ns, Pandemic.checkstate(ns))
    end
    println(nextstate)
    println("$n turns taken")
    println()
end
