# this is taken from Louis Dressel's POMDPs.jl. Thanks Louis!

###########################################################################
# ALPHA POLICY
# Each row of alpha_vectors is an alpha_vector
###########################################################################
# TODO: Give alpha_actions a type
#  I think so far, it will most likely be a Vector{Int}
#  QMDP, FIB, SARSOP all produce something amenable to this
#  I just have to make sure I don't assume it is something else later

abstract Alphas

type MOMDPAlphas <: Alphas

    alpha_vectors::Matrix{Float64}
    alpha_actions::Vector{Int64}
    observable_states::Vector{Int64}

    MOMDPAlphas(av::Matrix{Float64}, aa::Vector{Int64}, os::Vector{Int64}) = new(av, aa, os)

    # Constructor if no action list is given
    # Here, we 0-index actions, to match sarsop output
    function MOMDPAlphas(av::Matrix{Float64})
        # TODO: this is broken, actions and observations need to be obtained from pomdp
        numActions = size(av, 1)
        alist = [0:(numActions-1)]
        ostates = [0:(numActions-1)]
        return new(av, alist, ostates)
    end

    # Constructor reading policy from file
    function MOMDPAlphas(filename::String)
        alpha_vectors, alpha_actions, observable_states = read_momdp(filename)
        return new(alpha_vectors, alpha_actions, observable_states)
    end
end

type POMDPAlphas <: Alphas
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
    function POMDPAlphas(filename::String)
        alpha_vectors, alpha_actions = read_pomdp(filename)
        return new(alpha_vectors, alpha_actions)
    end
end


function action(policy::MOMDPAlphas, b::Belief, x::Int64)
    vectors = policy.alpha_vectors
    actions = policy.alpha_actions
    states = policy.observable_states
    o = x - 1 # julia obs: 1-100, sarsop obs: 0-99
    utilities = prod(vectors, b) 
    chunk = actions[find(s -> s == o, states)]
    a = chunk[indmax(utilities[find(s -> s == o, states)])] + 1
    return a
end

function value(policy::MOMDPAlphas, b::Belief, x::Int64)
    vectors = policy.alpha_vectors
    actions = policy.alpha_actions
    states = policy.observable_states
    o = x - 1 # 1 indexing in julia 
    utilities = prod(vectors, b) 
    chunk = actions[find(s -> s == o, states)]
    v =  maximum(utilities[find(s -> s == o, states)])
    return v
end

function prod(alphas::Matrix{Float64}, b::Belief)
    @assert size(alphas, 1) == length(b) "Alpha and belief sizes not equal"
    n = size(alphas, 2)
    util = zeros(n)
    for i = 1:n
        s = 0.0
        for j = 1:length(b)
            s += alphas[j,i]*weight(b,j)
        end
        util[i] = s
    end
    return util
end


