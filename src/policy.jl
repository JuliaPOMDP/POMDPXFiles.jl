# this is taken from Louis Dressel's POMDPs.jl. Thanks Louis!

# Abstract Type representing alpha vectors
abstract type Alphas end


mutable struct POMDPAlphas <: Alphas
    alpha_vectors::Matrix{Float64}
    alpha_actions::Vector{Int64}

    POMDPAlphas(av::Matrix{Float64}, aa::Vector{Int64}) = new(av, aa)

    # Constructor if no action list is given
    # Here, we 0-index actions, to match sarsop output
    function POMDPAlphas(av::Matrix{Float64})
        numActions = size(av, 1)
        alist = [0:(numActions-1)]
        return new(av, alist)
    end

    # Constructor reading policy from file
    function POMDPAlphas(filename::AbstractString)
        alpha_vectors, alpha_actions = read_pomdp(filename)
        return new(alpha_vectors, alpha_actions)
    end

    # Default constructor
    function POMDPAlphas()
        return new(zeros(0,0), zeros(Int64,0))
    end
end

"""
    MOMDPAlphas

A structure representing alpha vectors for a MOMDP.

# Fields
- `alpha_vectors::Matrix{Float64}`: Matrix of alpha vectors, where each column represents an alpha vector
- `alpha_actions::Vector{Int64}`: Vector of actions associated with each alpha vector (0-indexed)
- `alpha_visible_states::Vector{Int64}`: Vector of visible states associated with each alpha vector

# Constructors
- `MOMDPAlphas(av::Matrix{Float64}, aa::Vector{Int64}, avs::Vector{Int64})`: Create with explicit alpha vectors, actions, and visible states
- `MOMDPAlphas(av::Matrix{Float64})`: Create with alpha vectors only, automatically generating 0-indexed actions
- `MOMDPAlphas(filename::AbstractString)`: Create by reading policy from a file
- `MOMDPAlphas()`: Create an empty structure with zero-sized arrays

# Notes
- The actions are 0-indexed to match SARSOP output format
- Each alpha vector is associated with a specific action and a specific visible state
"""
mutable struct MOMDPAlphas <: Alphas
    alpha_vectors::Matrix{Float64}
    alpha_actions::Vector{Int64}
    alpha_visible_states::Vector{Int64}

    MOMDPAlphas(av::Matrix{Float64}, aa::Vector{Int64}, avs::Vector{Int64}) = new(av, aa, avs)

    # Constructor if no action list is given
    # Here, we 0-index actions, to match sarsop output
    function MOMDPAlphas(av::Matrix{Float64})
        numActions = size(av, 1)
        alist = [0:(numActions-1)]
        return new(av, alist, Int64[])
    end

    # Constructor reading policy from file
    function MOMDPAlphas(filename::AbstractString)
        alpha_vectors, alpha_actions, alpha_visible_states = read_momdp(filename)
        return new(alpha_vectors, alpha_actions, alpha_visible_states)
    end

    # Default constructor
    function MOMDPAlphas()
        return new(zeros(0,0), zeros(Int64,0), zeros(Int64,0))
    end
end
