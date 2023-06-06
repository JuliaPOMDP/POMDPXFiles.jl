module POMDPXFiles

using POMDPs
using POMDPTools
using ProgressMeter

import EzXML: Node, XMLDocument, ElementNode, addelement!, link!, write, readxml, root, findfirst, findall, nodecontent

export
    AbstractPOMDPXFile,
    POMDPXFile,
    Alphas,
    POMDPAlphas,

    read_pomdp


include("writer.jl")
include("policy.jl")
include("reader.jl")

end # module
