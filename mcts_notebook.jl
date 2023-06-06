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
	using Dates
end

# ╔═╡ 0dda3960-d304-47e4-ac87-877453db1f79
md"""# Pandemic Monte Carlo Tree Search
"""

# ╔═╡ 6a77f3c8-bd39-4c13-8c85-18f3c4e008bd
md"## Setup"

# ╔═╡ 9edd1af7-57a5-4bce-b424-1f1ee71ecd13
@bind game_params confirm(PlutoUI.combine() do Child
	md"""### Game Parameters
	
	Set parameters for the game here.
	
	Map: $(Child("mapt", Select(["vanillamap" => "Vanilla", "circle12" => "'12-Circle'"])))
	
	Players: $(Child("players", Slider(2:4, show_value=true)))
	
	Difficulty: $(Child("dif", Select(["Introductory", "Normal", "Heroic"])))
	
	Extra settings, command separated. See `Pandemic.Settings`:
	
	$(Child("setargs", TextField((50, 5))))
	"""
end)

# ╔═╡ 0b7b1af4-1220-4467-ac2d-fcf00a6a29a4
begin
	local kwargs = isempty(game_params.setargs) ? () : eval(Meta.parse("($(game_params.setargs),)"))
	local difficulty = getproperty(Pandemic, Symbol(game_params.dif))
	local map = getproperty(Pandemic.Maps, Symbol(game_params.mapt))()
	game = Pandemic.newgame(
		map,
		Pandemic.Settings(
			game_params.players,
			difficulty;
			kwargs...
		)
	)
end

# ╔═╡ a6267fcb-1472-4d3d-9084-2912623041dd
@bind solver_params confirm(PlutoUI.combine() do Child
	md"""### Solver Parameters

Set parameters for the [`MCTS.jl` Solver](https://juliapomdp.github.io/MCTS.jl/stable/vanilla/#MCTS.MCTSSolver).

Maximum CPU Time: $(Child("max_time", Slider(1.0 : 1.0 : 30.0, show_value=true, default=2.0))) seconds

\# of Iterations per Action: $(Child("n_iterations", Slider(5:200, show_value=true, default=30)))

Rollout Horizon Depth: $(Child("depth", Slider(5:20, show_value=true)))
"""
end)

# ╔═╡ f576dd96-bf35-4100-8b05-ef6505f03014
solver = MCTSSolver(
	max_time=solver_params.max_time,
	n_iterations=solver_params.n_iterations,
	depth=solver_params.depth,
	timer= () -> millisecond(now()) / 1000,
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

$(@bind mdptype Select(["singleaction", "compound", "fullcompound"]; default="compound"))
"""

# ╔═╡ b0cbc6e4-fcd0-40e6-837f-ef4dc802c0d7
mdp = if mdptype == "singleaction"
	PandemicAIs.POMDPAdaptors.singleaction((_, a, _) -> basicreward(a))
elseif mdptype == "compound"
	PandemicAIs.POMDPAdaptors.compound((_, a, _) -> compoundreward(a))
elseif mdptype == "compoundfull"
	PandemicAIs.POMDPAdaptors.compoundfull((_, a, _) -> compoundreward(a))
end

# ╔═╡ 008a98a1-0d0b-4958-a36e-135583c6d42b
planner = solve(solver, mdp)

# ╔═╡ cc58dcc5-e605-4695-a7c9-45f56e304885
md"""## Simulation

Number of (parallel) simulations to run: $(@bind numsims confirm(Slider(1:20, show_value=true, default=8)))
"""

# ╔═╡ 4baf1733-ad01-401c-9307-a663446eb6ee
to_run = [Sim(deepcopy(mdp), deepcopy(planner), deepcopy(game)) for _ in 1:numsims]

# ╔═╡ e586142f-157c-48a8-8853-0fbf9fb47945
function getstats(history)
	finalstate = history[end].sp
	return (
		finalgame=finalstate,
		state = Pandemic.checkstate(finalstate),
		nsteps = length(history),
	)
end

# ╔═╡ 211c06ac-c41f-472a-8238-19a9c8749a58
s = @time simulate(HistoryRecorder(), mdp, planner, game)

# ╔═╡ b6bf0f91-361d-4c4d-820a-45a2a07c4653
getstats(s)

# ╔═╡ 25f71a03-2a73-43cf-a4fd-7faf7fae12c0
# ╠═╡ disabled = true
#=╠═╡
run_parallel((_, h) -> getstats(h), to_run, show_progress=false)
  ╠═╡ =#

# ╔═╡ Cell order:
# ╠═0f87af60-048d-11ee-09b0-9fc4afb47557
# ╟─0dda3960-d304-47e4-ac87-877453db1f79
# ╟─6a77f3c8-bd39-4c13-8c85-18f3c4e008bd
# ╟─9edd1af7-57a5-4bce-b424-1f1ee71ecd13
# ╟─0b7b1af4-1220-4467-ac2d-fcf00a6a29a4
# ╟─a6267fcb-1472-4d3d-9084-2912623041dd
# ╠═f576dd96-bf35-4100-8b05-ef6505f03014
# ╟─97305b58-16b1-4008-bdd1-294d4453c8f4
# ╠═a13d79cd-fdbd-454d-9a6f-92dda4384ff7
# ╠═bff932fa-1160-42fa-aea6-516f406aff47
# ╟─b7c8c7ff-b6a3-41ff-b702-d440f910ecf3
# ╠═b0cbc6e4-fcd0-40e6-837f-ef4dc802c0d7
# ╠═008a98a1-0d0b-4958-a36e-135583c6d42b
# ╟─cc58dcc5-e605-4695-a7c9-45f56e304885
# ╠═4baf1733-ad01-401c-9307-a663446eb6ee
# ╠═e586142f-157c-48a8-8853-0fbf9fb47945
# ╠═211c06ac-c41f-472a-8238-19a9c8749a58
# ╠═b6bf0f91-361d-4c4d-820a-45a2a07c4653
# ╠═25f71a03-2a73-43cf-a4fd-7faf7fae12c0
