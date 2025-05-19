using POMDPs
using POMDPTools
using MOMDPs
using POMDPXFiles
using POMDPModels
using RockSample
using Test

include("rocksample_momdp.jl")

@testset "basic" begin
    file_name = "tiger_test.pomdpx"
    pomdp = TigerPOMDP()
    pomdpx = POMDPXFile(file_name)
    write(pomdp, pomdpx)
    av, aa = read_pomdp("mypolicy.policy")

    @test av ≈ [-81.5975 3.01448 24.6954 28.4025 19.3711; 
                 28.4025 24.6954 3.01452 -81.5975 19.3711]
    @test aa == [1,0,0,2,0]
end

@testset "MOMDP" begin
    
    @testset "Writing MOMDP to POMDPX file" begin
        rocksample_pomdp = RockSamplePOMDP()
        rocksample_pomdp = RockSample.RockSamplePOMDP(
            map_size=(1, 3),
            rocks_positions=[(1, 1)],
            init_pos=(1, 2),
            sensor_efficiency=0.5
        )
        rocksample_momdp = RockSampleMOMDP(rocksample_pomdp)
        
        MOMDPs.is_y_prime_dependent_on_x_prime(::RockSampleMOMDP) = false
        MOMDPs.is_x_prime_dependent_on_y(::RockSampleMOMDP) = false
        MOMDPs.is_initial_distribution_independent(::RockSampleMOMDP) = true
            
        # Create a POMDPXFile
        pomdpx = POMDPXFile("test_momdp.pomdpx"; description="Test MOMDP")
        
        # Write MOMDP to POMDPX file
        write(rocksample_momdp, pomdpx)
        
        # Number of lines in the POMDPX file
        n_lines_momdp = countlines("test_momdp.pomdpx")
        
        # Test file exists
        @test isfile("test_momdp.pomdpx")
        
        isfile("test_momdp.pomdpx") && rm("test_momdp.pomdpx")
        
        # Chnage the dependencies in the MOMDP and check that the new POMDPX file is larger
        MOMDPs.is_y_prime_dependent_on_x_prime(::RockSampleMOMDP) = true
        
        pomdpx = POMDPXFile("test_momdp.pomdpx")
        write(rocksample_momdp, pomdpx)
        n_lines_tft = countlines("test_momdp.pomdpx")
        @test n_lines_tft > n_lines_momdp
        
        MOMDPs.is_x_prime_dependent_on_y(::RockSampleMOMDP) = true
        write(rocksample_momdp, pomdpx)
        n_lines_ttt = countlines("test_momdp.pomdpx")
        @test n_lines_ttt > n_lines_tft
        
        MOMDPs.is_initial_distribution_independent(::RockSampleMOMDP) = false
        write(rocksample_momdp, pomdpx)
        n_lines_ttf = countlines("test_momdp.pomdpx")
        @test n_lines_ttf > n_lines_ttt
        
        # Clean up
        isfile("test_momdp.pomdpx") && rm("test_momdp.pomdpx")
    end
    
    @testset "Reading MOMDP from POMDPX file" begin
        av, aa, oo = read_momdp("momdp_policy.out")
        @test size(av) = size(av) == (4, 13)
        @test length(aa) == 13
        @test length(oo) == 13
        @test av == [19.025 18.0737 24.5887  10.0 23.3593 17.5987 9.5 17.5987 23.3593  10.0 19.5 18.525 0.0;
                    -0.975  9.025   15.8829  10.0 15.0887 17.5987 9.5 17.5987 15.0887  10.0 19.5 18.525 0.0;
                    19.025 18.0737  17.2378  10.0 16.3759  9.025  9.5 9.025   16.3759  10.0 -0.5  9.5   0.0;
                    -0.975  9.025    8.14506 10.0 7.73781  9.025  9.5 9.025    7.73781 10.0 -0.5  9.5   0.0]
        @test aa == [0, 5, 5, 2, 4, 1, 2, 2, 3, 2, 0, 6, 6]
        @test oo == [0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4]
    end
end

@testset "a, sp observation warning" begin 
    struct BadObsPOMDP <: POMDP{Int,Int,Int} end
    POMDPs.states(m::BadObsPOMDP) = 1:2
    POMDPs.actions(m::BadObsPOMDP) = 1:2
    POMDPs.observations(m::BadObsPOMDP) = 1:2
    POMDPs.transition(m::BadObsPOMDP, s, a) = Deterministic(clamp(s+a, 1, 2))
    POMDPs.reward(m::BadObsPOMDP, s, a, o) = s
    POMDPs.observation(m::BadObsPOMDP, s, a, sp) = Deterministic(sp)
    POMDPs.discount(m::BadObsPOMDP) = 0.99
    POMDPs.initialstate(m::BadObsPOMDP) = Deterministic(1)
    POMDPs.stateindex(m::BadObsPOMDP, s) = s
    POMDPs.actionindex(m::BadObsPOMDP, s) = s
    POMDPs.obsindex(m::BadObsPOMDP, s) = s

    @test_throws MethodError cd(mktempdir()) do
        write(BadObsPOMDP(), POMDPXFile("bad_obs_test.pomdpx"))
    end

    POMDPs.observation(m::BadObsPOMDP, a, sp) = Deterministic(1)
    cd(mktempdir()) do
        write(BadObsPOMDP(), POMDPXFile("bad_obs_test.pomdpx"))
    end
end
