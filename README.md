# POMDPXFiles

[![Build Status](https://github.com/JuliaPOMDP/POMDPXFiles.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/JuliaPOMDP/POMDPXFiles.jl/actions/workflows/CI.yml/)
[![codecov](https://codecov.io/gh/JuliaPOMDP/POMDPXFiles.jl/branch/master/graph/badge.svg?token=14YwrQvwbp)](https://codecov.io/gh/JuliaPOMDP/POMDPXFiles.jl)

This module provides an interface for generating .pomdpx files that can be used with the [SARSOP.jl](https://github.com/JuliaPOMDP/SARSOP.jl). This module leverages the API defined in [POMDPs.jl](https://github.com/JuliaPOMDP/POMDPs.jl). 

## Installation

```julia
Pkg.add("POMDPXFiles")
```

The module provides an interface for generating files for both POMDPs and MOMDPs.

## Usage 
Make sure that your model is defined according to the API in POMDPs.jl.

### Writing POMDPX files
#### POMDPs
```julia
pomdp = YourPOMDP() # intialize your pomdp
pomdpx = POMDPX("my_pomdp.pomdpx") 
write(pomdp, pomdpx) # creates a pomdpx file called my_pomdp.pomdpx
```

#### MOMDPs
Same process as for POMDPs:

```julia
momdp = YourMOMDP() # intialize your momdp
pomdpx = POMDPX("my_momdp.pomdpx")
write(momdp, pomdpx) # creates a pomdpx file called my_momdp.pomdpx
```

### Reading Policy files

#### POMDPs
```julia
pomdp_policy = "my_pomdp.policy"
am, av = read_pomdp(pomdp_policy)
```

#### MOMDPs
```julia
momdp_policy = "my_momdp.policy"
am, av, ov = read_momdp(momdp_policy)
```