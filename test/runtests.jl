using POMDPXFiles
using POMDPModels
using Base.Test

# write your own tests here

file_name = "tiger_test.pomdpx"
pomdp = TigerPOMDP()
pomdpx = POMDPXFile(file_name)
write(pomdp, pomdpx)
av, aa = read_pomdp("mypolicy.policy")

@test 1 == 1
