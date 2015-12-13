module POMDPXFile

if isdir(Pkg.dir("MOMDPs"))
    using MOMDPs
    import MOMDPs: action, value
else
    using POMDPs
    import POMDPs: action, value
end

# import o avoid naming conflict in POMDPs.jl (value is overloaded in LightXML)
import LightXML: parse_file, root, get_elements_by_tagname, attribute, content

export 
    AbstractPOMDPX,
    POMDPX,
    MOMDPX,
    Alphas,
    POMDPAlphas,
    MOMDPAlphas,

    read_momdp,
    read_pomdp,
    action,
    value


include("writer.jl")
include("policy.jl")
include("read.jl")

end # module
