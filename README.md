# POMDPXFiles

This module provides an interface for generating .pomdpx files that can be used with the [SARSOP.jl](https://github.com/JuliaPOMDP/SARSOP.jl). This module leverages the API defined in [POMDPs.jl](https://github.com/JuliaPOMDP/POMDPs.jl). 

## Installation

```julia
Pkg.clone("https://github.com/JuliaPOMDP/POMDPXFiles.jl")
```

The module provides an interface for generating files for both POMDPs and MOMDPs. 

## Module Types

- `AbstractPOMDPXFile`
- `POMDPXFile`
- `MOMDPXFile`


## Usage 
Make sure that your model is defined according to the API in POMDPs.jl.

```julia
pomdp = YourPOMDP() # intialize your pomdp
pomdpx = POMDPX("my_pomdp.pomdpx") # for pomdp
pomdpx = MOMDPX("my_pomdp.pomdpx") # for momdp
write(pomdp, pomdpx) # creates a pomdpx file called my_pomdp.pomdpx
```

## MOMDPs (Depricated)

While MOMDPs are no longer officially supported, you can look at how they were handled in an older version of POMDPs.jl
in [this branch](https://github.com/altiscope/prototype/blob/develop/scenarios/memos/2/analysis.json) 
