module POMDPXFiles

using POMDPs
using POMDPTools
using ProgressMeter
import POMDPs: action, value

# import o avoid naming conflict in POMDPs.jl (value is overloaded in LightXML)
import LightXML: parse_file, root, get_elements_by_tagname, attribute, content


export
    AbstractPOMDPXFile,
    POMDPXFile,
    MOMDPXFile,
    Alphas,
    POMDPAlphas,

    read_pomdp,
    action,
    value


include("writer.jl")
include("policy.jl")
include("read.jl")

end # module
