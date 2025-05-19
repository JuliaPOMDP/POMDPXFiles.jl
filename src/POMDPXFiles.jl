module POMDPXFiles

using POMDPs
using POMDPTools
using MOMDPs
using ProgressMeter


# import to avoid naming conflict in POMDPs.jl (value is overloaded in LightXML)
import LightXML: parse_file, root, get_elements_by_tagname, attribute, content


export
    AbstractPOMDPXFile,
    POMDPXFile,
    Alphas,
    POMDPAlphas,
    MOMDPAlphas,

    read_pomdp,
    read_momdp


include("writer.jl")
include("policy.jl")
include("read.jl")

end # module
