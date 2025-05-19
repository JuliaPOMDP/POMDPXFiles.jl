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

    pomdp_states = ordered_states(pomdp)
    pomdp_pstates = ordered_states(pomdp)
    acts = ordered_actions(pomdp)
    obs = ordered_observations(pomdp)
    # x = Number of next statement to track Progress
    # Added approximately after every four lines written to file, 14 next statements outside loops 
    x = 14 + length(pomdp_states) + length(pomdp_states)*length(acts)*length(obs) + length(pomdp_states)*length(acts) + length(acts)*length(pomdp_pstates)
    p1 = Progress(x, dt=0.01)

    # Header stuff for xml
    write(out_file, "<?xml version='1.0' encoding='ISO-8859-1'?>\n\n\n")
    write(out_file, "<pomdpx version='0.1' id='test' ")
    write(out_file, "xmlns:='http://www.w3.org/2001/XMLSchema-instance' ")
    write(out_file, "xsi:noNamespaceSchemaLocation='pomdpx.xsd'>\n\n\n")

    sleep(0.01)
    next!(p1)
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
    next!(p1)
    # State Variables
    str = state_xml(pomdp, pomdpx)
    write(out_file, str)
    next!(p1)
    # Action Variables
    str = action_xml(pomdp, pomdpx)
    write(out_file, str)
    next!(p1)
    # Observation Variables
    str = obs_var_xml(pomdp, pomdpx)
    write(out_file, str)
    next!(p1)
    # Reward Variable
    str = reward_var_xml(pomdp, pomdpx)
    write(out_file, str)
    write(out_file, "\t</Variable>\n\n\n")

    next!(p1)
    ############################################################################
    # INITIAL STATE BELIEF
    ############################################################################
    belief_xml(pomdp, pomdpx, out_file, p1)


    ############################################################################
    # STATE TRANSITION FUNCTION
    ############################################################################
    trans_xml(pomdp, pomdpx, out_file, p1)


    ############################################################################
    # OBS FUNCTION
    ############################################################################
    obs_xml(pomdp, pomdpx, out_file, p1)


    ############################################################################
    # REWARD FUNCTION
    ############################################################################
    reward_xml(pomdp, pomdpx, out_file, p1)


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
function belief_xml(pomdp::POMDP, pomdpx::POMDPXFile, out_file::IOStream, p1)
    belief = pomdpx.initial_belief
    var = pomdpx.state_name
    write(out_file, "\t<InitialStateBelief>\n")
    str = "\t\t<CondProb>\n"
    str = "$(str)\t\t\t<Var>$(var)0</Var>\n"
    str = "$(str)\t\t\t<Parent>null</Parent>\n"
    str = "$(str)\t\t\t<Parameter type = \"TBL\">\n"
    next!(p1)

    d = initialstate(pomdp)
    for (i, s) in enumerate(ordered_states(pomdp))
        p = pdf(d, s)
        str = "$(str)\t\t\t\t<Entry>\n"
        str = "$(str)\t\t\t\t\t<Instance>s$(i-1)</Instance>\n"
        str = "$(str)\t\t\t\t\t<ProbTable>$(p)</ProbTable>\n"
        str = "$(str)\t\t\t\t</Entry>\n"
        next!(p1)
    end
    str = "$(str)\t\t\t</Parameter>\n"
    str = "$(str)\t\t</CondProb>\n"
    write(out_file, str)
    write(out_file, "\t</InitialStateBelief>\n\n\n")
    next!(p1)
end
############################################################################



############################################################################
# function: trans_xml
# input: pomdp model, pomdpx type, output file
# output: None, writes the transition probability table to the output file
############################################################################
function trans_xml(pomdp::POMDP, pomdpx::POMDPXFile, out_file::IOStream, p1)
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
    next!(p1)
    for (i, s) in enumerate(pomdp_states)
        if isterminal(pomdp, s) # if terminal, just remain in the same state
            str = "\t\t\t\t<Entry>\n"
            str = "$(str)\t\t\t\t\t<Instance>* s$(i-1) s$(i-1)</Instance>\n"
            str = "$(str)\t\t\t\t\t<ProbTable>1.0</ProbTable>\n"
            str = "$(str)\t\t\t\t</Entry>\n"
            write(out_file, str)
            for i = 1:length(acts)*length(pomdp_pstates)
                next!(p1)
            end
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
                    next!(p1)
                end
            end
        end
    end
    str = "\t\t\t</Parameter>\n"
    str = "$(str)\t\t</CondProb>\n"
    write(out_file, str)
    write(out_file, "\t</StateTransitionFunction>\n\n\n")
    next!(p1)
    return nothing
end
############################################################################



############################################################################
# function: obs_xml
# input: pomdp model, pomdpx type, output file
# output: None, writes the observation probability table to the output file
############################################################################
function obs_xml(pomdp::POMDP, pomdpx::POMDPXFile, out_file::IOStream, p1)
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
    next!(p1)

    try observation(pomdp, first(acts), first(pomdp_states))
    catch ex
        if ex isa MethodError
            @warn("""POMDPXFiles only supports observation distributions conditioned on a and sp.

                  Check that there is an `observation(::M, ::A, ::S)` method available (or an (::A, ::S) method of the observation function for a QuickPOMDP).
                  
                  This warning is designed to give a helpful hint to fix errors, but may not always be relevant.
                  """, M=typeof(pomdp), S=typeof(first(pomdp_states)), A=typeof(first(acts)))
        end
        rethrow(ex)
    end

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
                next!(p1)
            end
        end
    end
    write(out_file, "\t\t\t</Parameter>\n")
    write(out_file, "\t\t</CondProb>\n")
    write(out_file, "\t</ObsFunction>\n")
    next!(p1)
end
############################################################################



############################################################################
# function: reward_xml
# input: pomdp model, pomdpx type, output file
# output: None, writes the reward function to the output file
############################################################################
function reward_xml(pomdp::POMDP, pomdpx::POMDPXFile, out_file::IOStream, p1)
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
    next!(p1)

    for (i, s) in enumerate(pomdp_states)
        if !isterminal(pomdp, s)
            for (ai, a) in enumerate(acts)
                r = rew(s, a)
                str = "\t\t\t\t<Entry>\n"
                str = "$(str)\t\t\t\t\t<Instance>a$(ai-1) s$(i-1)</Instance>\n"
                str = "$(str)\t\t\t\t\t<ValueTable>$(r)</ValueTable>\n"
                str = "$(str)\t\t\t\t</Entry>\n"
                write(out_file, str)
                next!(p1)
            end
        else
            for i = 1:length(acts)
                next!(p1)
            end
        end
    end

    write(out_file, "\t\t\t</Parameter>\n\t\t</Func>\n")
    write(out_file, "\t</RewardFunction>\n\n")
    next!(p1)
end
############################################################################

"""
    write(momdp::MOMDP, pomdpx::AbstractPOMDPXFile)

Write a MOMDP to a POMDPXFile. This file is very similar to 
Base.write(::POMDP, ::AbstractPOMDPXFile) as defined in POMDPXFiles.jl with the only 
difference being the formatting and counting of lines to be written.
"""
function Base.write(momdp::MOMDP, pomdpx::AbstractPOMDPXFile)
    file_name = pomdpx.file_name
    discount_factor = discount(momdp)

    # Open file to write to
    out_file = open("$file_name", "w")

    n_xs = length(ordered_states_x(momdp))
    n_ys = length(ordered_states_y(momdp))
    n_as = length(ordered_actions(momdp))
    n_os = length(ordered_observations(momdp))
    
    if is_x_prime_dependent_on_y(momdp)
        n_belief_xml = n_xs + n_xs * n_ys
    else
        n_belief_xml = n_xs + n_ys
    end
    if is_x_prime_dependent_on_y(momdp)
        n_trans_xml_x = n_xs * n_ys * n_as * n_xs
    else
        n_trans_xml_x = n_xs * n_as * n_xs
    end
    
    if is_y_prime_dependent_on_x_prime(momdp)
        n_trans_xml_y = n_xs * n_ys * n_as * n_xs * n_ys
    else
        n_trans_xml_y = n_xs * n_ys * n_as * n_ys 
    end
    n_obs_xml = n_xs * n_ys * n_as * n_os
    n_reward_xml = n_xs * n_ys * n_as
    
    # Not true number, but the large majority for progress awareness
    n_xml_lines = n_belief_xml + n_trans_xml_x + n_trans_xml_y + n_obs_xml + n_reward_xml
    p1 = Progress(n_xml_lines, dt=0.1)

    # Header for xml
    write(out_file, "<?xml version='1.0' encoding='ISO-8859-1'?>\n\n\n")
    write(out_file, "<pomdpx version='0.1' id='test' ")
    write(out_file, "xmlns:='http://www.w3.org/2001/XMLSchema-instance' ")
    write(out_file, "xsi:noNamespaceSchemaLocation='pomdpx.xsd'>\n\n\n")
    write(out_file, "\t<Description> $(pomdpx.description)</Description>\n\n\n")
    
    write(out_file, "\t<Discount>$(discount_factor)</Discount>\n\n\n")
    
    write(out_file, "\t<Variable>\n")
    write(out_file, state_xml(momdp, pomdpx))
    write(out_file, POMDPXFiles.action_xml(momdp, pomdpx))
    write(out_file, POMDPXFiles.obs_var_xml(momdp, pomdpx))
    write(out_file, POMDPXFiles.reward_var_xml(momdp, pomdpx))
    write(out_file, "\t</Variable>\n\n\n")
    
    belief_xml(momdp, pomdpx, out_file, p1)
    trans_xml(momdp, pomdpx, out_file, p1)
    obs_xml(momdp, pomdpx, out_file, p1)
    reward_xml(momdp, pomdpx, out_file, p1)
    
    finish!(p1)

    write(out_file, "</pomdpx>")
    close(out_file)
    
    println("POMDPX file written successfully.")
end

function state_xml(momdp::MOMDP, pomdpx::POMDPXFile)
    n_xs = length(states_x(momdp))
    n_ys = length(states_y(momdp))
    xname = pomdpx.state_name * "x"
    yname = pomdpx.state_name * "y"
    
    str = ""
    # visible states
    str *= "\t\t<StateVar vnamePrev=\"$(xname)0\" vnameCurr=\"$(xname)1\" fullyObs=\"true\">\n"
    str *= "\t\t\t<NumValues>$(n_xs)</NumValues>\n"
    str *= "\t\t</StateVar>\n\n"
    
    # hidden states
    str *= "\t\t<StateVar vnamePrev=\"$(yname)0\" vnameCurr=\"$(yname)1\" fullyObs=\"false\">\n"
    str *= "\t\t\t<NumValues>$(n_ys)</NumValues>\n"
    str *= "\t\t</StateVar>\n\n"
    
    return str
end

function belief_xml(momdp::MOMDP, pomdpx::POMDPXFile, out_file::IOStream, p1)
    xname = pomdpx.state_name * "x"
    yname = pomdpx.state_name * "y"
    
    # Initial belief distribution for visible states
    write(out_file, "\t\t<InitialStateBelief>\n")
    str = "\t\t\t<CondProb>\n"
    str *= "\t\t\t\t<Var>$(xname)0</Var>\n"
    str *= "\t\t\t\t<Parent>null</Parent>\n"
    str *= "\t\t\t\t<Parameter type = \"TBL\">\n"
    
    dx = initialstate_x(momdp)
    for (i, xi) in enumerate(ordered_states_x(momdp))
        p_xi = pdf(dx, xi)
        if p_xi > 0.0
            str *= "\t\t\t\t\t<Entry>\n"
            str *= "\t\t\t\t\t\t<Instance>s$(i-1)</Instance>\n"
            str *= "\t\t\t\t\t\t<ProbTable>$(p_xi)</ProbTable>\n"
            str *= "\t\t\t\t\t</Entry>\n"
        end
        next!(p1)
    end
    str *= "\t\t\t\t</Parameter>\n"
    str *= "\t\t\t</CondProb>\n"
    write(out_file, str)
    
    # Initial belief distribution for hidden states
    str = "\t\t\t<CondProb>\n"
    str *= "\t\t\t\t<Var>$(yname)0</Var>\n"
    if !is_initial_distribution_independent(momdp)
        str *= "\t\t\t\t<Parent>$(xname)0</Parent>\n"
    else
        str *= "\t\t\t\t<Parent>null</Parent>\n"
    end
    str *= "\t\t\t\t<Parameter type = \"TBL\">\n"
    
    if is_initial_distribution_independent(momdp)
        dy = initialstate_y(momdp, first(ordered_states_x(momdp)))
        for (j, yi) in enumerate(ordered_states_y(momdp))
            p_yi = pdf(dy, yi)
            if p_yi > 0.0
                str *= "\t\t\t\t\t<Entry>\n"
                str *= "\t\t\t\t\t\t<Instance>s$(j-1)</Instance>\n"
                str *= "\t\t\t\t\t\t<ProbTable>$(p_yi)</ProbTable>\n"
                str *= "\t\t\t\t\t</Entry>\n"
            end
            next!(p1)
        end
    else
        for (i, xi) in enumerate(ordered_states_x(momdp))
            dy = initialstate_y(momdp, xi)
            p_xi = pdf(dx, xi)
            if p_xi > 0.0
                for (j, yi) in enumerate(ordered_states_y(momdp))
                    p_yi = pdf(dy, yi)
                    if p_yi > 0.0
                        str *= "\t\t\t\t\t<Entry>\n"
                        str *= "\t\t\t\t\t\t<Instance>s$(i-1) s$(j-1)</Instance>\n"
                        str *= "\t\t\t\t\t\t<ProbTable>$(p_yi)</ProbTable>\n"
                        str *= "\t\t\t\t\t</Entry>\n"
                    end
                    next!(p1)
                end
            else
                # Initial state has probability 0, so these probabilites don't matter.
                # However, we need to write something to the file as the C++ SARSOP code checks
                # the make sure appropriate probabilties are written for all states.
                pt = 1 / length(ordered_states_y(momdp))
                str *= "\t\t\t\t\t<Entry>\n"
                str *= "\t\t\t\t\t\t<Instance>s$(i-1) *</Instance>\n"
                str *= "\t\t\t\t\t\t<ProbTable>$(pt)</ProbTable>\n"
                str *= "\t\t\t\t\t</Entry>\n"
                for _ in 1:length(ordered_states_y(momdp))
                    next!(p1)
                end
            end
        end
    end 
        
    str *= "\t\t\t\t</Parameter>\n"
    str *= "\t\t\t</CondProb>\n"
    write(out_file, str)
    
    write(out_file, "\t\t</InitialStateBelief>\n\n\n")
end

function trans_xml(momdp::MOMDP, pomdpx::POMDPXFile, out_file::IOStream, p1)
    xname = pomdpx.state_name * "x"
    yname = pomdpx.state_name * "y"
    aname = pomdpx.action_name
    
    xs = ordered_states_x(momdp)
    ys = ordered_states_y(momdp)
    acts = ordered_actions(momdp)

    write(out_file, "\t<StateTransitionFunction>\n")
    
    # Transition probability table for visible states
    str = "\t\t<CondProb>\n"
    str *= "\t\t\t<Var>$(xname)1</Var>\n"
    if is_x_prime_dependent_on_y(momdp)
        str *= "\t\t\t<Parent>$(aname) $(xname)0 $(yname)0</Parent>\n"
    else
        str *= "\t\t\t<Parent>$(aname) $(xname)0</Parent>\n"
    end
    str *= "\t\t\t<Parameter type = \"TBL\">\n"
    write(out_file, str)
    
    if is_x_prime_dependent_on_y(momdp)
        for (i, xi) in enumerate(xs)
            for (j, yi) in enumerate(ys)
                if isterminal(momdp, (xi, yi))
                    str = "\t\t\t\t<Entry>\n"
                    str *= "\t\t\t\t\t<Instance>* s$(i-1) s$(j-1) s$(i-1)</Instance>\n"
                    str *= "\t\t\t\t\t<ProbTable>1.0</ProbTable>\n"
                    str *= "\t\t\t\t</Entry>\n"
                    write(out_file, str)
                    for _ in 1:(length(acts) * length(xs))
                        next!(p1)
                    end
                else
                    str = ""
                    for (k, ai) in enumerate(acts)
                        dx = transition_x(momdp, (xi, yi), ai)
                        for (l, xip) in enumerate(xs)
                            p = pdf(dx, xip)
                            if p > 0.0
                                str *= "\t\t\t\t<Entry>\n"
                                str *= "\t\t\t\t\t<Instance>a$(k-1) s$(i-1) s$(j-1) s$(l-1)</Instance>\n"
                                str *= "\t\t\t\t\t<ProbTable>$(p)</ProbTable>\n"
                                str *= "\t\t\t\t</Entry>\n"
                            end
                            next!(p1)
                        end
                    end
                    write(out_file, str)
                end
            end
        end
    else
        for (i, xi) in enumerate(xs)
            if isterminal(momdp, (xi, first(ys)))
                str = "\t\t\t\t<Entry>\n"
                str *= "\t\t\t\t\t<Instance>* s$(i-1) s$(i-1)</Instance>\n"
                str *= "\t\t\t\t\t<ProbTable>1.0</ProbTable>\n"
                str *= "\t\t\t\t</Entry>\n"
                write(out_file, str)
                for _ in 1:length(acts)
                    next!(p1)
                end
            else
                str = ""
                for (k, ai) in enumerate(acts)
                    dx = transition_x(momdp, (xi, first(ys)), ai)
                    for (l, xip) in enumerate(xs)
                        p = pdf(dx, xip)
                        if p > 0.0
                            str *= "\t\t\t\t<Entry>\n"
                            str *= "\t\t\t\t\t<Instance>a$(k-1) s$(i-1) s$(l-1)</Instance>\n"
                            str *= "\t\t\t\t\t<ProbTable>$(p)</ProbTable>\n"
                            str *= "\t\t\t\t</Entry>\n"
                        end
                        next!(p1)
                    end
                end
                write(out_file, str)
            end
        end
    end
    str = "\t\t\t</Parameter>\n"
    str *= "\t\t</CondProb>\n"
    write(out_file, str)
    
    # Transition probability table for hidden states
    str = "\t\t<CondProb>\n"
    str *= "\t\t\t<Var>$(yname)1</Var>\n"
    if is_y_prime_dependent_on_x_prime(momdp)
        str *= "\t\t\t<Parent>$(aname) $(xname)0 $(yname)0 $(xname)1</Parent>\n"
    else
        str *= "\t\t\t<Parent>$(aname) $(xname)0 $(yname)0</Parent>\n"
    end
    str *= "\t\t\t<Parameter type = \"TBL\">\n"
    write(out_file, str)
    
    if is_y_prime_dependent_on_x_prime(momdp)
        for (i, xi) in enumerate(xs)
            for (j, yi) in enumerate(ys)
                if isterminal(momdp, (xi, yi))
                    str = "\t\t\t\t<Entry>\n"
                    str *= "\t\t\t\t\t<Instance>* s$(i-1) s$(j-1) * s$(j-1)</Instance>\n"
                    str *= "\t\t\t\t\t<ProbTable>1.0</ProbTable>\n"
                    str *= "\t\t\t\t</Entry>\n"
                    write(out_file, str)
                    for _ in 1:(length(acts) * length(xs) * length(ys))
                        next!(p1)
                    end
                else
                    str = ""
                    for (k, ai) in enumerate(acts)
                        dx = transition_x(momdp, (xi, yi), ai)
                        for (l, xip) in enumerate(xs)
                            p_xip = pdf(dx, xip)
                            if p_xip > 0.0
                                dy = transition_y(momdp, (xi, yi), ai, xip)
                                for (m, yip) in enumerate(ys)
                                    p_yip = pdf(dy, yip)
                                    if p_yip > 0.0
                                        str *= "\t\t\t\t<Entry>\n"
                                        str *= "\t\t\t\t\t<Instance>a$(k-1) s$(i-1) s$(j-1) s$(l-1) s$(m-1)</Instance>\n"
                                        str *= "\t\t\t\t\t<ProbTable>$(p_yip)</ProbTable>\n"
                                        str *= "\t\t\t\t</Entry>\n"
                                    end
                                    next!(p1)
                                end
                            else
                                # These probabilities don't matter since p_xip = 0, but required
                                # by the C++ SARSOP code.
                                pt = 1 / length(ys)
                                str *= "\t\t\t\t<Entry>\n"
                                str *= "\t\t\t\t\t<Instance>a$(k-1) s$(i-1) s$(j-1) s$(l-1) *</Instance>\n"
                                str *= "\t\t\t\t\t<ProbTable>$(pt)</ProbTable>\n"
                                str *= "\t\t\t\t</Entry>\n"
                                for _ in 1:length(ys)
                                    next!(p1)
                                end
                            end
                        end    
                    end
                    write(out_file, str)
                end
            end
        end
    else
        for (i, xi) in enumerate(xs)
            for (j, yi) in enumerate(ys)
                if isterminal(momdp, (xi, yi))
                    str = "\t\t\t\t<Entry>\n"
                    str *= "\t\t\t\t\t<Instance>* s$(i-1) s$(j-1) s$(j-1)</Instance>\n"
                    str *= "\t\t\t\t\t<ProbTable>1.0</ProbTable>\n"
                    str *= "\t\t\t\t</Entry>\n"
                    write(out_file, str)
                    for _ in 1:(length(acts) * length(xs) * length(ys))
                        next!(p1)
                    end
                else
                    str = ""
                    for (k, ai) in enumerate(acts)    
                        dy = transition_y(momdp, (xi, yi), ai, first(xs))
                        for (m, yip) in enumerate(ys)
                            p_yip = pdf(dy, yip)
                            if p_yip > 0.0
                                str *= "\t\t\t\t<Entry>\n"
                                str *= "\t\t\t\t\t<Instance>a$(k-1) s$(i-1) s$(j-1) s$(m-1)</Instance>\n"
                                str *= "\t\t\t\t\t<ProbTable>$(p_yip)</ProbTable>\n"
                                str *= "\t\t\t\t</Entry>\n"
                            end
                            next!(p1)
                        end
                    end
                    write(out_file, str)
                end
            end
        end
    end
        
    str = "\t\t\t</Parameter>\n"
    str *= "\t\t</CondProb>\n"
    write(out_file, str)
    write(out_file, "\t</StateTransitionFunction>\n\n\n")
end

function obs_xml(momdp::MOMDP, pomdpx::POMDPXFile, out_file::IOStream, p1)
    xname = pomdpx.state_name * "x"
    yname = pomdpx.state_name * "y"
    aname = pomdpx.action_name
    oname = pomdpx.obs_name

    xs = ordered_states_x(momdp)
    ys = ordered_states_y(momdp)
    acts = ordered_actions(momdp)
    obs = ordered_observations(momdp)
    
    write(out_file, "\t<ObsFunction>\n")
    str = "\t\t<CondProb>\n"
    str *= "\t\t\t<Var>$(oname)</Var>\n"
    str *= "\t\t\t<Parent>$(aname) $(xname)1 $(yname)1</Parent>\n"
    str *= "\t\t\t<Parameter type = \"TBL\">\n"
    write(out_file, str)
    
    try observation(momdp, first(acts), (first(xs), first(ys)))
    catch ex
        if ex isa MethodError
            @warn("""POMDPXFiles only supports observation distributions conditioned on a and sp.

                  Check that there is an `observation(::M, ::A, ::S)` method available (or an (::A, ::S) method of the observation function for a QuickPOMDP).
                  
                  This warning is designed to give a helpful hint to fix errors, but may not always be relevant.
                  """, M=typeof(pomdp), S=typeof(first(pomdp_states)), A=typeof(first(acts)))
        end
        rethrow(ex)
    end
    
    for (i, xi) in enumerate(xs)
        for (j, yi) in enumerate(ys)
            str = ""
            for (k, ai) in enumerate(acts)
                d_o = observation(momdp, ai, (xi, yi))
                for (l, oi) in enumerate(obs)
                    p = pdf(d_o, oi)
                    if p > 0.0
                        str *= "\t\t\t\t<Entry>\n"
                        str *= "\t\t\t\t\t<Instance>a$(k-1) s$(i-1) s$(j-1) o$(l-1)</Instance>\n"
                        str *= "\t\t\t\t\t<ProbTable>$(p)</ProbTable>\n"
                        str *= "\t\t\t\t</Entry>\n"
                    end
                    next!(p1)
                end
            end
            write(out_file, str)
        end
    end
    str = "\t\t\t</Parameter>\n"
    str *= "\t\t</CondProb>\n"
    write(out_file, str)
    write(out_file, "\t</ObsFunction>\n\n\n")
end

function reward_xml(momdp::MOMDP, pomdpx::POMDPXFile, out_file::IOStream, p1)
    xname = pomdpx.state_name * "x"
    yname = pomdpx.state_name * "y"
    aname = pomdpx.action_name
    rname = pomdpx.reward_name
    
    xs = ordered_states_x(momdp)
    ys = ordered_states_y(momdp)
    acts = ordered_actions(momdp)
    
    write(out_file, "\t<RewardFunction>\n")
    str = "\t\t<Func>\n"
    str *= "\t\t\t<Var>$(rname)</Var>\n"
    str *= "\t\t\t<Parent>$(aname) $(xname)0 $(yname)0</Parent>\n"
    str *= "\t\t\t<Parameter type = \"TBL\">\n"
    write(out_file, str)

    for (i, xi) in enumerate(xs)
        for (j, yi) in enumerate(ys)
            str = ""
            for (k, ai) in enumerate(acts)
                r = reward(momdp, (xi, yi), ai)
                str *= "\t\t\t\t<Entry>\n"
                str *= "\t\t\t\t\t<Instance>a$(k-1) s$(i-1) s$(j-1)</Instance>\n"
                str *= "\t\t\t\t\t<ValueTable>$(r)</ValueTable>\n"
                str *= "\t\t\t\t</Entry>\n"
                next!(p1)
            end
            write(out_file, str)
        end
    end
    str = "\t\t\t</Parameter>\n"
    str *= "\t\t</Func>\n"
    write(out_file, str)
    write(out_file, "\t</RewardFunction>\n\n\n")
end
