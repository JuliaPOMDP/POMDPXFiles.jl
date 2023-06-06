"""Parses a Policy XML file and returns `alphavectors` and `alphaactions`
This should be able to handle any policy in the `.policy` format, which includes
  policies written by `POMDPs.jl` or `APPL`.

`alphavectors` is a matrix containing the alpha vectors where each row corresponds to a
  different alpha vector.

`alphaactions` is a vector containing the list of action indices, where ach index
  corresponds to action associated with the alpha vector row.
These are `0-indexed`, so `0` maps to the first action.
"""

function read_pomdp(filename::String)
    xml = readxml(open(filename, "r"))
    policy = root(xml)  # The <Polciy ..> node

    av_node = findfirst("AlphaVector", policy)

    alphavectors = Array{Real}[]
    alphaactions = []

    # Create alpha vector and alpha action lists
    vectors = findall("Vector", av_node)
    for vector in vectors
        push!(alphavectors, parse.(Float64, split(nodecontent(vector))))
        push!(alphaactions, vector["action"])
    end
    alphavectors = mapreduce(permutedims, vcat, alphavectors)

    n_vectors  = parse(Int, av_node["numVectors"])
    vector_len = parse(Int, av_node["vectorLength"])
    @assert size(alphavectors) == (n_vectors, vector_len)

    # TODO handle sparsevectors
    sparsevectors = findall("SparseVector", av_node)
    for vector in sparsevectors
        # Turn these into vectors
    end

    return (alphavectors=alphavectors, alphaactions=parse.(Int64, alphaactions))
end