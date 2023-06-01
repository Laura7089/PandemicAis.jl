using Test
using PandemicAIs
using Random
using SumTypes

# TODO: this definitely needs more testing
@testset "possibleactions" begin
    using PandemicAIs.Actions

    map = Pandemic.Maps.circle12()
    map_starter_locs = [
        Drive(3),
        Drive(4),
        Drive(5),
        Drive(9),
    ]

    # Pre-tested setup
    begin
        rng = MersenneTwister(8756890)
        game = Pandemic.newgame(map, Pandemic.Introductory, 4, rng)

        # Starting state
        @test [
            Pass,
            Drive(3),
            Drive(4),
            Drive(5),
            Drive(9),
            DirectFlight(2),
            DirectFlight(11),
            TreatDisease(Pandemic.Yellow),
        ] == possibleactions(game)

        # Make a move
        Pandemic.Actions.move_one!(game, 1, 3)
        @test [
            Pass,
            Drive(1),
            Drive(2),
            Drive(6),
            Drive(12),
            DirectFlight(2),
            DirectFlight(11),
        ] == possibleactions(game)

    end

    # Random setup, test properties we always know are there
    # TODO: is there some kind of property testing framework we can use?
    begin
        game = Pandemic.newgame(map, Pandemic.Introductory, 4)

        first_moves = possibleactions(game)
        @test Pass in first_moves
        @test map_starter_locs ⊆ first_moves

        old_loc = game.playerlocs[1]
        # TODO: yikes, MLStyle.jl might fix this
        isdirect(m::PandemicAIs.PlayerAction) = @cases m begin
            DirectFlight => true
            Drive => false
            CharterFlight => false
            ShuttleFlight => false
            BuildStation => false
            DiscoverCure => false
            TreatDisease => false
            ShareKnowledge => false
            Pass => false
        end
        direct_flights = [m for m in first_moves if isdirect(m)]

        Pandemic.Actions.move_one!(game, 1, 5)
        next_moves = possibleactions(game)
        @test Drive(old_loc) in next_moves
        @test direct_flights ⊆ next_moves
    end
end
