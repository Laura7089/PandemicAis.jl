using PandemicAIs
using PandemicAIs.Rewards
using PandemicAIs.Rewards.CubeSaturation
using Test

@testset "cure_progress" begin
    game = testgame()
    @test cure_progress(game) == 0.0
    game.diseases[2] = Pandemic.Cured
    @test cure_progress(game) == 0.25
end

@testset "num_outbreaks" begin
    game = testgame()
    @test num_outbreaks(game) == 1.0
    game.outbreaks += 1
    @test num_outbreaks(game) == 0.875
    game.outbreaks += 7
    @test num_outbreaks(game) == 0.0
end

@testset "num_stations" begin
    game = testgame()
    @test num_stations(game) ≈ 0.16 atol=0.01
    game.stations[5] = true
    @test num_stations(game) ≈ 0.33 atol=0.01
end

@testset "cs.for_disease" begin
    game = testgame()
    for_disease(game, Pandemic.Yellow)
end

@testset "avg_all" begin
    game = testgame()
    avg_all(game)
end

@testset "max_all" begin
    game = testgame()
    max_all(game)
end

@testset "min_all" begin
    game = testgame()
    min_all(game)
end
