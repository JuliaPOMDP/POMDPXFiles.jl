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
#

function read_momdp(filename::String)

    # Parse the xml file
    # TODO: Check that the file exists and handle the case that it doesn't
    xdoc = parse_file(filename)

    # Get the root of the document (the Policy tag in this case)
    policy_tag = root(xdoc)
    #println(name(policy_tag))      # print the name of this tag

    # Determine expected number of vectors and their length
    alphavector_tag = get_elements_by_tagname(policy_tag, "AlphaVector")[1]     #length of 1 anyway
    num_vectors = int(attribute(alphavector_tag, "numVectors"))
    vector_length = int(attribute(alphavector_tag, "vectorLength"))
    num_full_obs_states = int(attribute(alphavector_tag, "numObsValue"))

    # For debugging purposes...
    #println("AlphaVector tag: # vectors, vector length: $(num_vectors), $(vector_length)")

    # Arrays with vector and sparse vector tags
    vector_tags = get_elements_by_tagname(alphavector_tag, "Vector")
    sparsevector_tags = get_elements_by_tagname(alphavector_tag, "SparseVector")

    num_vectors_check = length(vector_tags) + length(sparsevector_tags)         # should be same as num_vectors

    # Initialize the gamma matrix. This is basically a matrix with the alpha
    #   vectors as rows.
    #alpha_vectors = Array(Float64, num_vectors, vector_length)
    alpha_vectors = Array{Float64}(vector_length, num_vectors)
    alpha_actions = Array{String}(num_vectors)
    observable_states = Array{String}(num_vectors)
    gammarow = 1

    # Fill in gamma
    for vector in vector_tags
        alpha = float(split(content(vector)))
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
    return alpha_vectors, int(alpha_actions), int(observable_states)
end


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
