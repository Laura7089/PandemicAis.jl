#!/bin/julia

using MCTS
using PandemicAIs

g = Pandemic.newgame(Pandemic.Maps.vanillamap(), Pandemic.Heroic, 4)
mdp = PandemicAIs.PODMPAdaptors.getquickmdp()
solver = MCTSSolver()
planner = solve(solver, mdp)

actions = []

while Pandemic.checkstate!(g) == Pandemic.Playing
    next_act = action(planner, g)
    push!(actions, next_act)
    println(next_act)
    PandemicAIs.Actions.resolve!(g, next_act)
end
