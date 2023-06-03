using Test
using Random
using SumTypes
using PandemicAIs
using PandemicAIs.SingleActions

# TODO: this definitely needs more testing
# TODO: make these order independent
@testset "possibleactions" begin
    MAP_STARTER_LOCS = [Drive(3), Drive(4), Drive(5), Drive(9)]

    # Pre-tested setup
    begin
        game = testgame(8756890)

        # Starting state
        @test [
            Drive(3),
            Drive(4),
            Drive(5),
            Drive(9),
            DirectFlight(2),
            DirectFlight(11),
            Pass,
            TreatDisease(Pandemic.Yellow),
        ] == possibleactions(game)

        # Make a move
        Pandemic.Actions.move_one!(game, 1, 3)
        @test [
            Drive(1),
            Drive(2),
            Drive(6),
            Drive(12),
            DirectFlight(2),
            DirectFlight(11),
            Pass,
        ] == possibleactions(game)

    end

    # Random setup, test properties we always know are there
    # TODO: is there some kind of property testing framework we can use?
    begin
        game = testgame(8756890)

        first_moves = possibleactions(game)
        @test Pass in first_moves
        @test MAP_STARTER_LOCS ⊆ first_moves

        old_loc = game.playerlocs[1]
        # TODO: yikes, MLStyle.jl might fix this and similar issues
        isdirect(m::SingleActions.PlayerAction) = @cases m begin
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
