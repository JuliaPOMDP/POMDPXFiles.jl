# this is taken from Louis Dressel's POMDPs.jl. Thanks Louis!

typealias Belief Vector{Float64}

###########################################################################
# ALPHA POLICY
# Each row of alpha_vectors is an alpha_vector
###########################################################################
# TODO: Give alpha_actions a type
#  I think so far, it will most likely be a Vector{Int}
#  QMDP, FIB, SARSOP all produce something amenable to this
#  I just have to make sure I don't assume it is something else later
type MOMDPAlphas 

    alpha_vectors::Matrix{Float64}
    alpha_actions::Vector{Int64}
    observable_states::Vector{Int64}

    MOMDPAlphas(av::Matrix{Float64}, aa::Vector{Int64}, os::Vector{Int64}) = new(m, av, aa, os)

    # Constructor if no action list is given
    # Here, we 0-index actions, to match sarsop output
    function MOMDPAlphas(av::Matrix{Float64})
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



function action(policy::MOMDPAlphas, b::Belief, x::Int64)

    vectors = policy.alpha_vectors
    actions = policy.alpha_actions
    states = policy.observable_states
    o = x - 1 # julia obs: 1-100, sarsop obs: 0-99

    utilities = vectors * b

    chunk = actions[find(s -> s == o, states)]
    a = chunk[indmax(utilities[find(s -> s == o, states)])] + 1
    return a
end


function value(policy::MOMDPAlphas, b::Belief, x::Int64)
    
end
