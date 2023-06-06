### A Pluto.jl notebook ###
# v0.19.26

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ 0f87af60-048d-11ee-09b0-9fc4afb47557
begin
	import Pkg

	Pkg.add(["MCTS", "POMDPs", "POMDPTools", "SumTypes", "DataFrames"])
	Pkg.add(["PlutoUI", "WGLMakie"])
	Pkg.add(url="https://github.com/Laura7089/Pandemic.jl")
	Pkg.add(url="https://github.com/Laura7089/PandemicAis.jl")

	using MCTS
	using PandemicAIs
	using PandemicAIs.SingleActions
	using PandemicAIs.CompoundActions
	using POMDPs
	using POMDPTools
	using SumTypes

	using PlutoUI
	using DataFrames
end

# ╔═╡ 0dda3960-d304-47e4-ac87-877453db1f79
md"""# Pandemic Monte Carlo Tree Search
"""

# ╔═╡ 6a77f3c8-bd39-4c13-8c85-18f3c4e008bd
md"## Setup"

# ╔═╡ 9edd1af7-57a5-4bce-b424-1f1ee71ecd13
md"""### Game Parameters

Set parameters for the game here.

Map: $(@bind mapt Select(["vanillamap" => "Vanilla", "circle12" => "'12-Circle'"]))

Players: $(@bind players Slider(2:4, show_value=true))

Difficulty: $(@bind dif Select(["Introductory", "Normal", "Heroic"]))

$(@bind regen Button("Generate Game State"))
"""

# ╔═╡ 0b7b1af4-1220-4467-ac2d-fcf00a6a29a4
begin
	regen
	difficulty = getproperty(Pandemic, Symbol(dif))
	game = Pandemic.newgame(
		getproperty(Pandemic.Maps, Symbol(mapt))(),
		Pandemic.Settings(
			players,
			difficulty,
		)
	)
end

# ╔═╡ a6267fcb-1472-4d3d-9084-2912623041dd
md"""### Solver Parameters

Set parameters for the [`MCTS.jl` Solver](https://juliapomdp.github.io/MCTS.jl/stable/vanilla/#MCTS.MCTSSolver).

Maximum CPU Time: $(@bind max_time Slider(50.0: 1.0 : 1000.0, show_value=true, default=100.0))

\# of Iterations per Action: $(@bind n_iterations Slider(5:200, show_value=true, default=30))

Rollout Horizon Depth: $(@bind depth Slider(5:20, show_value=true))
"""

# ╔═╡ f576dd96-bf35-4100-8b05-ef6505f03014
solver = MCTSSolver(
	max_time=max_time,
	n_iterations=n_iterations,
	depth=depth,
)

# ╔═╡ 97305b58-16b1-4008-bdd1-294d4453c8f4
md"""### Rewards and Weighting
"""

# ╔═╡ a13d79cd-fdbd-454d-9a6f-92dda4384ff7
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

# ╔═╡ bff932fa-1160-42fa-aea6-516f406aff47
compoundreward(caction) = map(basicreward, caction) |> sum

# ╔═╡ b7c8c7ff-b6a3-41ff-b702-d440f910ecf3
md"""### MDP Type

There are currently three options for the granularity of actions in the final MDP:

Option | Action Type | Notes
---|---|---
`singleaction` | `PandemicAIs.SingleActions.PlayerAction` | None
`compound` | `PandemicAIs.CompoundActions.CompoundAction` | Compound action length ranges from `1` to the remaining actions for the current player
`compoundfull` |`PandemicAIs.CompoundActions.CompoundAction` | Compount action length is fixed at exactly the remaining actions for the current player

$(@bind mdptype Select(["singleaction", "compound", "fullcompound"]))
"""

# ╔═╡ b0cbc6e4-fcd0-40e6-837f-ef4dc802c0d7
begin
	mdp = if mdptype == "singleaction"
		PandemicAIs.POMDPAdaptors.singleaction((_, a, _) -> basicreward(a))
	elseif mdptype == "compound"
		PandemicAIs.POMDPAdaptors.compound((_, a, _) -> compoundreward(a))
	elseif mdptype == "compoundfull"
		PandemicAIs.POMDPAdaptors.compoundfull((_, a, _) -> compoundreward(a))
	end
end

# ╔═╡ 008a98a1-0d0b-4958-a36e-135583c6d42b
planner = solve(solver, mdp)

# ╔═╡ cc58dcc5-e605-4695-a7c9-45f56e304885
md"""## Simulation

Number of (parallel) simulations to run: $(@bind numsims Slider(1:20, show_value=true))
"""

# ╔═╡ e586142f-157c-48a8-8853-0fbf9fb47945
function getstats(history)
	finalstate = history[end].sp
	return (
		finalgame=finalstate,
		state = Pandemic.checkstate(finalstate),
		nsteps = length(history),
	)
end

# ╔═╡ 19ee46e2-21fb-4961-8023-d755c91740f5
simulator = HistoryRecorder()

# ╔═╡ 211c06ac-c41f-472a-8238-19a9c8749a58
getstats(simulate(simulator, mdp, planner, game))

# ╔═╡ 4baf1733-ad01-401c-9307-a663446eb6ee
to_run = [Sim(mdp, planner, deepcopy(game)) for _ in 1:numsims]

# ╔═╡ 25f71a03-2a73-43cf-a4fd-7faf7fae12c0
# ╠═╡ disabled = true
#=╠═╡
run((_, h) -> getstats(h), to_run, show_progress=false)
  ╠═╡ =#

# ╔═╡ Cell order:
# ╠═0f87af60-048d-11ee-09b0-9fc4afb47557
# ╟─0dda3960-d304-47e4-ac87-877453db1f79
# ╟─6a77f3c8-bd39-4c13-8c85-18f3c4e008bd
# ╟─9edd1af7-57a5-4bce-b424-1f1ee71ecd13
# ╠═0b7b1af4-1220-4467-ac2d-fcf00a6a29a4
# ╟─a6267fcb-1472-4d3d-9084-2912623041dd
# ╠═f576dd96-bf35-4100-8b05-ef6505f03014
# ╟─97305b58-16b1-4008-bdd1-294d4453c8f4
# ╠═a13d79cd-fdbd-454d-9a6f-92dda4384ff7
# ╠═bff932fa-1160-42fa-aea6-516f406aff47
# ╟─b7c8c7ff-b6a3-41ff-b702-d440f910ecf3
# ╠═b0cbc6e4-fcd0-40e6-837f-ef4dc802c0d7
# ╠═008a98a1-0d0b-4958-a36e-135583c6d42b
# ╟─cc58dcc5-e605-4695-a7c9-45f56e304885
# ╠═e586142f-157c-48a8-8853-0fbf9fb47945
# ╠═19ee46e2-21fb-4961-8023-d755c91740f5
# ╠═211c06ac-c41f-472a-8238-19a9c8749a58
# ╠═4baf1733-ad01-401c-9307-a663446eb6ee
# ╠═25f71a03-2a73-43cf-a4fd-7faf7fae12c0
