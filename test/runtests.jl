using POMDPXFiles
using POMDPModels
using Base.Test

# write your own tests here

file_name = "tiger_test.pomdpx"
pomdp = TigerPOMDP()
pomdpx = POMDPXFile(file_name)
write(pomdp, pomdpx)
av, aa = read_pomdp("mypolicy.policy")

@test_approx_eq av [-81.5975 3.01448 24.6954 28.4025 19.3711; 28.4025 24.6954 3.01452 -81.5975 19.3711]
@test aa == [1,0,0,2,0]
