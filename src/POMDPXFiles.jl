module POMDPXFiles

using POMDPs
using POMDPTools
using ProgressMeter
using Parameters

import EzXML
import EzXML: Node, XMLDocument, ElementNode, addelement!, link!, write, readxml, root, findfirst, findall, nodecontent, setroot!, prettyprint

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
