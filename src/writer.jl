#################################################################
# This file implements a .pomdpx file generator using the
# POMDPs.jl interface.
#################################################################

abstract type AbstractPOMDPXFile end

mutable struct POMDPXFile <: AbstractPOMDPXFile
    file_name::AbstractString
    description::AbstractString

    state_name::AbstractString
    action_name::AbstractString
    reward_name::AbstractString
    obs_name::AbstractString

    initial_belief::Vector{Float64}

    #initial_belief::Vector{Float64} # belief over partially observed vars

    function POMDPXFile(file_name::AbstractString; description::AbstractString="",
                    initial_belief::Vector{Float64}=Float64[])

        if isempty(description)
            description = "This is a pomdpx file for a partially observable MDP"
        end

        self = new()
        self.file_name = file_name
        self.description = description

        self.state_name = "state"
        self.action_name = "action"
        self.reward_name = "reward"
        self.obs_name = "observation"

        self.initial_belief = initial_belief

        return self
    end

end


function Base.write(pomdp::POMDP, pomdpx::AbstractPOMDPXFile)
    file_name = pomdpx.file_name
    description = pomdpx.description
    discount_factor = discount(pomdp)

    # Open file to write to
    out_file = open("$file_name", "w")

    # Header stuff for xml
    write(out_file, "<?xml version='1.0' encoding='ISO-8859-1'?>\n\n\n")
    write(out_file, "<pomdpx version='0.1' id='test' ")
    write(out_file, "xmlns:='http://www.w3.org/2001/XMLSchema-instance' ")
    write(out_file, "xsi:noNamespaceSchemaLocation='pomdpx.xsd'>\n\n\n")

    ############################################################################
    # DESCRIPTION
    ############################################################################
    write(out_file, "\t<Description> $(description)</Description>\n\n\n")

    ############################################################################
    # DISCOUNT
    ############################################################################
    write(out_file, "\t<Discount>$(discount_factor)</Discount>\n\n\n")

    ############################################################################
    # VARIABLES
    ############################################################################
    write(out_file, "\t<Variable>\n")
    # State Variables
    str = state_xml(pomdp, pomdpx)
    write(out_file, str)
    # Action Variables
    str = action_xml(pomdp, pomdpx)
    write(out_file, str)
    # Observation Variables
    str = obs_var_xml(pomdp, pomdpx)
    write(out_file, str)
    # Reward Variable
    str = reward_var_xml(pomdp, pomdpx)
    write(out_file, str)
    write(out_file, "\t</Variable>\n\n\n")


    ############################################################################
    # INITIAL STATE BELIEF
    ############################################################################
    belief_xml(pomdp, pomdpx, out_file)


    ############################################################################
    # STATE TRANSITION FUNCTION
    ############################################################################
    trans_xml(pomdp, pomdpx, out_file)


    ############################################################################
    # OBS FUNCTION
    ############################################################################
    obs_xml(pomdp, pomdpx, out_file)


    ############################################################################
    # REWARD FUNCTION
    ############################################################################
    reward_xml(pomdp, pomdpx, out_file)


    # CLOSE POMDPX TAG AND FILE
    write(out_file, "</pomdpx>")
    close(out_file)
end


############################################################################
# function: state_xml
# input: pomdp model, pomdpx type
# output: string in xml format the defines the state varaibles
############################################################################
function state_xml(pomdp::POMDP, pomdpx::POMDPXFile)
    # defines state vars for a POMDP
    n_s = length(states(pomdp))
    sname = pomdpx.state_name
    str = "\t\t<StateVar vnamePrev=\"$(sname)0\" vnameCurr=\"$(sname)1\" fullyObs=\"false\">\n"
    str = "$(str)\t\t\t<NumValues>$(n_s)</NumValues>\n"
    str = "$(str)\t\t</StateVar>\n\n"
    return str
end
############################################################################



############################################################################
# function: obs_var_xml
# input: pomdp model, pomdpx type
# output: string in xml format the defines the observation varaibles
############################################################################
function obs_var_xml(pomdp::POMDP, pomdpx::AbstractPOMDPXFile)
    # defines observation vars for POMDP and MOMDP
    n_o = length(observations(pomdp))
    oname = pomdpx.obs_name
    str = "\t\t<ObsVar vname=\"$(oname)\">\n"
    str = "$(str)\t\t\t<NumValues>$(n_o)</NumValues>\n"
    str = "$(str)\t\t</ObsVar>\n\n"
    return str
end
############################################################################



############################################################################
# function: action_xml
# input: pomdp model, pomdpx type
# output: string in xml format the defines the action varaibles
############################################################################
function action_xml(pomdp::POMDP, pomdpx::AbstractPOMDPXFile)
    # defines action vars for MDP, POMDP and MOMDP
    n_a = length(actions(pomdp))
    aname = pomdpx.action_name
    str = "\t\t<ActionVar vname=\"$(aname)\">\n"
    str = "$(str)\t\t\t<NumValues>$(n_a)</NumValues>\n"
    str = "$(str)\t\t</ActionVar>\n\n"
    return str
end
############################################################################



############################################################################
# function: reward_var_xml
# input: pomdp model, pomdpx type
# output: string in xml format the defines the reward varaible
############################################################################
function reward_var_xml(pomdp::POMDP, pomdpx::AbstractPOMDPXFile)
    # defines reward var for MDP, POMDP and MOMDP
    rname = pomdpx.reward_name
    str = "\t\t<RewardVar vname=\"$(rname)\"/>\n\n"
    return str
end
############################################################################



############################################################################
# function: belief_xml
# input: pomdp model, pomdpx type, output file
# output: None, writes the initial belief to the output file
############################################################################
function belief_xml(pomdp::POMDP, pomdpx::POMDPXFile, out_file::IOStream)
    belief = pomdpx.initial_belief
    var = pomdpx.state_name
    write(out_file, "\t<InitialStateBelief>\n")
    str = "\t\t<CondProb>\n"
    str = "$(str)\t\t\t<Var>$(var)0</Var>\n"
    str = "$(str)\t\t\t<Parent>null</Parent>\n"
    str = "$(str)\t\t\t<Parameter type = \"TBL\">\n"

    d = initialstate(pomdp)
    for (i, s) in enumerate(ordered_states(pomdp))
        p = pdf(d, s)
        str = "$(str)\t\t\t\t<Entry>\n"
        str = "$(str)\t\t\t\t\t<Instance>s$(i-1)</Instance>\n"
        str = "$(str)\t\t\t\t\t<ProbTable>$(p)</ProbTable>\n"
        str = "$(str)\t\t\t\t</Entry>\n"
    end
    str = "$(str)\t\t\t</Parameter>\n"
    str = "$(str)\t\t</CondProb>\n"
    write(out_file, str)
    write(out_file, "\t</InitialStateBelief>\n\n\n")
end
############################################################################



############################################################################
# function: trans_xml
# input: pomdp model, pomdpx type, output file
# output: None, writes the transition probability table to the output file
############################################################################
function trans_xml(pomdp::POMDP, pomdpx::POMDPXFile, out_file::IOStream)
    pomdp_states = ordered_states(pomdp)
    pomdp_pstates = ordered_states(pomdp)
    acts = ordered_actions(pomdp)

    aname = pomdpx.action_name
    var = pomdpx.state_name

    write(out_file, "\t<StateTransitionFunction>\n")
    str = "\t\t<CondProb>\n"
    str = "$(str)\t\t\t<Var>$(var)1</Var>\n"
    str = "$(str)\t\t\t<Parent>$(aname) $(var)0</Parent>\n"
    str = "$(str)\t\t\t<Parameter>\n"
    write(out_file, str)
    for (i, s) in enumerate(pomdp_states)
        if isterminal(pomdp, s) # if terminal, just remain in the same state
            str = "\t\t\t\t<Entry>\n"
            str = "$(str)\t\t\t\t\t<Instance>* s$(i-1) s$(i-1)</Instance>\n"
            str = "$(str)\t\t\t\t\t<ProbTable>1.0</ProbTable>\n"
            str = "$(str)\t\t\t\t</Entry>\n"
            write(out_file, str)
        else
            for (ai, a) in enumerate(acts)
                d = transition(pomdp, s, a)
                for (j, sp) in enumerate(pomdp_pstates)
                    p = pdf(d, sp)
                    if p > 0.0
                        str = "\t\t\t\t<Entry>\n"
                        str = "$(str)\t\t\t\t\t<Instance>a$(ai-1) s$(i-1) s$(j-1)</Instance>\n"
                        str = "$(str)\t\t\t\t\t<ProbTable>$(p)</ProbTable>\n"
                        str = "$(str)\t\t\t\t</Entry>\n"
                        write(out_file, str)
                    end
                end
            end
        end
    end
    str = "\t\t\t</Parameter>\n"
    str = "$(str)\t\t</CondProb>\n"
    write(out_file, str)
    write(out_file, "\t</StateTransitionFunction>\n\n\n")
    return nothing
end
############################################################################



############################################################################
# function: obs_xml
# input: pomdp model, pomdpx type, output file
# output: None, writes the observation probability table to the output file
############################################################################
function obs_xml(pomdp::POMDP, pomdpx::POMDPXFile, out_file::IOStream)
    pomdp_states = ordered_states(pomdp)
    acts = ordered_actions(pomdp)
    obs = ordered_observations(pomdp)

    aname = pomdpx.action_name
    oname = pomdpx.obs_name
    var = pomdpx.state_name

    write(out_file, "\t<ObsFunction>\n")
    str = "\t\t<CondProb>\n"
    str = "$(str)\t\t\t<Var>$(oname)</Var>\n"
    str = "$(str)\t\t\t<Parent>$(aname) $(var)1</Parent>\n"
    str = "$(str)\t\t\t<Parameter>\n"
    write(out_file, str)

    for (i, s) in enumerate(pomdp_states)
        for (ai, a) in enumerate(acts)
            d = observation(pomdp, a, s)
            for (oi, o) in enumerate(obs)
                p = pdf(d, o)
                if p > 0.0
                    str = "\t\t\t\t<Entry>\n"
                    str = "$(str)\t\t\t\t\t<Instance>a$(ai-1) s$(i-1) o$(oi-1)</Instance>\n"
                    str = "$(str)\t\t\t\t\t<ProbTable>$(p)</ProbTable>\n"
                    str = "$(str)\t\t\t\t</Entry>\n"
                    write(out_file, str)
                end
            end
        end
    end
    write(out_file, "\t\t\t</Parameter>\n")
    write(out_file, "\t\t</CondProb>\n")
    write(out_file, "\t</ObsFunction>\n")
end
############################################################################



############################################################################
# function: reward_xml
# input: pomdp model, pomdpx type, output file
# output: None, writes the reward function to the output file
############################################################################
function reward_xml(pomdp::POMDP, pomdpx::POMDPXFile, out_file::IOStream)
    pomdp_states = ordered_states(pomdp)
    acts = ordered_actions(pomdp)
    rew = StateActionReward(pomdp)

    aname = pomdpx.action_name
    var = pomdpx.state_name
    rname = pomdpx.reward_name

    write(out_file, "\t<RewardFunction>\n")
    str = "\t\t<Func>\n"
    str = "$(str)\t\t\t<Var>$(rname)</Var>\n"
    str = "$(str)\t\t\t<Parent>$(aname) $(var)0</Parent>\n"
    str = "$(str)\t\t\t<Parameter>\n"
    write(out_file, str)

    for (i, s) in enumerate(pomdp_states)
        if !isterminal(pomdp, s)
            for (ai, a) in enumerate(acts)
                r = rew(s, a)
                str = "\t\t\t\t<Entry>\n"
                str = "$(str)\t\t\t\t\t<Instance>a$(ai-1) s$(i-1)</Instance>\n"
                str = "$(str)\t\t\t\t\t<ValueTable>$(r)</ValueTable>\n"
                str = "$(str)\t\t\t\t</Entry>\n"
                write(out_file, str)
            end
        end
    end

    write(out_file, "\t\t\t</Parameter>\n\t\t</Func>\n")
    write(out_file, "\t</RewardFunction>\n\n")
end
############################################################################
