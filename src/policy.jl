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

