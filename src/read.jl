# Parses policy xml file and returns alpha vectors and alpha actions
# Should handle any policy in the .policy format
# Should handle policies written by POMDPs.jl or APPL
#
# alpha_vectors is a matrix containing the alpha vectors
#   Each row corresponds to a different alpha vector
#
# alpha_actions is a vector containing the list of action indices
#   Each index corresponds to action associated with the alpha vector of this row
#   These are 0-indexed... 0 means it is the first action
#
# TODO: Check that the input file exists and handle the case that it doesn't
# TODO: Handle sparse vectors

function read_pomdp(filename::String)

    # Parse the xml file
    # TODO: Check that the file exists and handle the case that it doesn't
    xdoc = parse_file(filename)

    # Get the root of the document (the Policy tag in this case)
    policy_tag = root(xdoc)
    #println(name(policy_tag))      # print the name of this tag

    # Determine expected number of vectors and their length
    alphavector_tag = get_elements_by_tagname(policy_tag, "AlphaVector")[1]     #length of 1 anyway
    num_vectors = parse(Int64, attribute(alphavector_tag, "numVectors"))
    vector_length = parse(Int64, attribute(alphavector_tag, "vectorLength"))
    num_full_obs_states = parse(Int64, attribute(alphavector_tag, "numObsValue"))

    # For debugging purposes...
    #println("AlphaVector tag: # vectors, vector length: $(num_vectors), $(vector_length)")

    # Arrays with vector and sparse vector tags
    vector_tags = get_elements_by_tagname(alphavector_tag, "Vector")
    sparsevector_tags = get_elements_by_tagname(alphavector_tag, "SparseVector")

    num_vectors_check = length(vector_tags) + length(sparsevector_tags)         # should be same as num_vectors

    # Initialize the gamma matrix. This is basically a matrix with the alpha
    #   vectors as columns.
    #alpha_vectors = Array(Float64, num_vectors, vector_length)
    alpha_vectors = Array{Float64}(undef, vector_length, num_vectors)
    alpha_actions = Array{String}(undef, num_vectors)
    observable_states = Array{String}(undef, num_vectors)
    gammarow = 1

    # Fill in gamma
    for vector in vector_tags
        alpha = parse.(Float64, split(content(vector)))
        #alpha_vectors[gammarow, :] = alpha
        alpha_vectors[:,gammarow] = alpha
        alpha_actions[gammarow] = attribute(vector, "action")
        observable_states[gammarow] = attribute(vector, "obsValue")
        gammarow += 1
    end

    # TODO: Handle sparse vectors
    for vector in sparsevector_tags
        # Turn these into vectors as well
    end

    # Return alpha vectors and indices of actions
    return alpha_vectors, [parse(Int64,s) for s in alpha_actions]
end

"""
    read_momdp(filename::String)

Read a MOMDP policy from a POMDPX file containing alpha vectors.

This function parses a POMDPX file that contains a policy represented as alpha vectors. The file should have a structure with `Policy` as the root tag, containing `AlphaVector` tags with associated `Vector` elements.

# Arguments
- `filename::String`: Path to the POMDPX file containing the policy

# Returns
- `alpha_vectors::Matrix{Float64}`: Matrix of alpha vectors, where each column represents an alpha vector
- `action_indices::Vector{Int64}`: Vector of action indices associated with each alpha vector
- `observable_indices::Vector{Int64}`: Vector of observable state indices associated with each alpha vector

# Notes
- The function expects the POMDPX file to have a specific structure with `Policy`, `AlphaVector`, and `Vector` tags
- Action and observable state values are converted from strings to integers
- The alpha vectors are stored as columns in the returned matrix
- The number of vectors and their length are determined from the XML attributes `numVectors` and `vectorLength`
"""
function read_momdp(filename::String)
    xdoc = parse_file(filename)

    # Get the root of the document (the Policy tag in this case)
    policy_tag = root(xdoc)

    # Determine expected number of vectors and their length
    alphavector_tag = get_elements_by_tagname(policy_tag, "AlphaVector")[1]
    num_vectors = parse(Int64, attribute(alphavector_tag, "numVectors"))
    vector_length = parse(Int64, attribute(alphavector_tag, "vectorLength"))

    # Arrays with vector tags
    vector_tags = get_elements_by_tagname(alphavector_tag, "Vector")

    # Initialize the gamma matrix. This is basically a matrix with the alpha vectors as columns.
    alpha_vectors = Array{Float64}(undef, vector_length, num_vectors)
    alpha_actions = Array{String}(undef, num_vectors)
    observable_states = Array{String}(undef, num_vectors)
    gammarow = 1

    # Fill in gamma
    for vector in vector_tags
        alpha = parse.(Float64, split(content(vector)))
        alpha_vectors[:,gammarow] = alpha
        alpha_actions[gammarow] = attribute(vector, "action")
        observable_states[gammarow] = attribute(vector, "obsValue")
        gammarow += 1
    end
    
    action_indices = [parse(Int64,a) for a in alpha_actions]
    observable_indices = [parse(Int64,s) for s in observable_states]
    
    return alpha_vectors, action_indices, observable_indices
end
