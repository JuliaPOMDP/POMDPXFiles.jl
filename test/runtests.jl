using POMDPs
using POMDPModelTools
using POMDPXFiles
using POMDPModels
using Test

# write your own tests here

file_name = "tiger_test.pomdpx"
pomdp = TigerPOMDP()
pomdpx = POMDPXFile(file_name)
write(pomdp, pomdpx)
av, aa = read_pomdp("mypolicy.policy")

@test av ≈ [-81.5975 3.01448 24.6954 28.4025 19.3711; 28.4025 24.6954 3.01452 -81.5975 19.3711]
@test aa == [1,0,0,2,0]

@testset begin "a, sp observation warning"
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
