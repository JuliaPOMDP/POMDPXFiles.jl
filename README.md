# POMDPXFile

This module provides an interface for generating .pomdpx files that can be used with the [SARSOP](https://github.com/sisl/SARSOP.jl) [POMDPs.jl](https://github.com/sisl/POMDPs.jl) solver. 

## Installation

```julia
Pkg.clone("https://github.com/sisl/POMDPXFile.jl")
```

The module provides an interface for generating files for both POMDPs and MOMDPs. 

## Module Types

- `AbstractPOMDPX`
- `POMDPX`
- `MOMDPX`


## Usage 
Make sure that your model is defined according to the API in POMDPs.jl.

```julia
pomdp = YourPOMDP() # intialize your pomdp
pomdpx = POMDPX("my_pomdp.pomdpx") # for pomdp
pomdpx = MOMDPX("my_pomdp.pomdpx") # for momdp
write(pomdp, pomdpx) # creates a pomdpx file called my_pomdp.pomdpx
```

