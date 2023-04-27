# POMDPXFiles

[![Build Status](https://github.com/JuliaPOMDP/POMDPXFiles.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/JuliaPOMDP/POMDPXFiles.jl/actions/workflows/CI.yml/)
[![codecov](https://codecov.io/gh/JuliaPOMDP/POMDPXFiles.jl/branch/master/graph/badge.svg?token=14YwrQvwbp)](https://codecov.io/gh/JuliaPOMDP/POMDPXFiles.jl)

This module provides an interface for generating .pomdpx files that can be used with the [SARSOP.jl](https://github.com/JuliaPOMDP/SARSOP.jl). This module leverages the API defined in [POMDPs.jl](https://github.com/JuliaPOMDP/POMDPs.jl). 

## Installation

```julia
Pkg.add("POMDPXFiles")
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

## MOMDPs (Deprecated)

While MOMDPs are no longer officially supported, you can look at how they were handled in an older version of POMDPs.jl
in [this branch](https://github.com/altiscope/prototype/blob/develop/scenarios/memos/2/analysis.json) 
