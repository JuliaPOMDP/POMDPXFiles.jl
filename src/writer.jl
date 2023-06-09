abstract type AbstractPOMDPXFile end

@with_kw struct POMDPXFile <: AbstractPOMDPXFile
    filename::String
    description::String = "This is a POMDPX file for a POMDP"

    s_var_name::String = "state"
    a_var_name::String = "action"
    o_var_name::String = "observation"
    r_var_name::String = "reward"

    s_name::Function = normalize
    a_name::Function = normalize
    o_name::Function = normalize

    pretty::Bool = false
end

POMDPXFile(filename::String, pretty::Bool) = POMDPXFile(; filename=filename, pretty=pretty)
POMDPXFile(filename::String) = POMDPXFile(filename, false)

a_var_name( px::POMDPXFile) = px.action_var_name
s_var_name( px::POMDPXFile) = "$(px.state_var_name)0"
sp_var_name(px::POMDPXFile) = "$(px.state_var_name)1"
o_var_name( px::POMDPXFile) = px.obs_var_name
r_var_name( px::POMDPXFile) = px.reward_var_name

function build_xml(p::POMDP, px::POMDPXFile)
    n_states = length(states(p))
    n_actions = length(actions(p))
    n_obs = length(observations(p))
    n_nodes = 14 + n_states + n_states * n_actions * n_obs + n_states * n_actions * 2
    pbar = Progress(n_nodes; dt=0.01)

    doc  = XMLDocument()
    root = ElementNode("pomdpx")
    root["version"] = 0.1
    root["id"] = replace(px.filename, ".pomdpx" => "")
    root["xmlns:xsi"] = "http://www.w3.org/2001/XMLSchema-instance"
    root["xsi:noNamespaceSchemaLocation"] = "https://raw.githubusercontent.com/JuliaPOMDP/sarsop/master/doc/POMDPX/pomdpx.xsd"
    setroot!(doc, root)

    addelement!(root, "Description", px.description)
    addelement!(root, "Discount", "$(discount(p))")
    next!(pbar)

    build_variables!(root, p, px, pbar)
    build_initial_beliefs(root, p, px, sname, pbar)
    build_transitions!(root, p, px, sname, aname, pbar)
    build_observations!(root, p, px, sname, aname, oname, pbar)
    build_rewards!(root, p, px, sname, aname, pbar)

    return doc
end

function build_variables!(root::Node, p::POMDP, px::POMDPXFile, pbar)
    variables = ElementNode("Variable")
    link!(root, variables)

    states_node = ElementNode("StateVar")
    states_node["vnamePrev"] = s_var_name(px)
    states_node["vnameCurr"] = sp_var_name(px)
    states_node["fullyObs" ] = "false"
    link!(variables, states_node)

    actions_node = ElementNode("ActionVar")
    actions_node["vname"] = a_var_name(px)
    link!(variables, actions_node)

    obs_node = ElementNode("ObsVar")
    obs_node["vname"] = o_var_name(px)
    link!(variables, obs_node)

    reward_node = ElementNode("RewardVar")
    reward_node["vname"] = r_var_name(px)
    link!(variables, reward_node)
    next!(pbar)

    if px.pretty
        all_states = join(["s_$(px.s_name(s))" for s=ordered_states(p)], " ")
        addelement!(states_node, "ValueEnum", all_states)

        all_actions = join(["a_$(px.a_name(a))" for a=ordered_actions(p)], " ")
        addelement!(actions_node, "ValueEnum", all_actions)

        all_observations = join(["o_$(px.o_name(o))" for o=ordered_observations(p)], " ")
        addelement!(obs_node, "ValueEnum", all_observations)
    else
        addelement!(states_node, "NumValues", "$(length(states(p)))")
        addelement!(actions_node, "NumValues", "$(length(actions(p)))")
        addelement!(obs_node, "NumValues", "$(length(observations(p)))")
    end
end

function param(label::String; prob::Real = -1, value::Real = -Inf)
    entry = ElementNode("Entry")
    addelement!(entry, "Instance", label)
    if prob != -1
        addelement!(entry, "ProbTable", "$(prob)")
    end
    if !isinf(value)
        addelement!(entry, "ValueTable", "$(value)")
    end
    return entry
end

function build_initial_beliefs(root::Node, p::POMDP, px::POMDPXFile, pbar)
    ibstate = ElementNode("InitialStateBelief")
    link!(root, ibstate)

    condprob = ElementNode("CondProb")
    link!(ibstate, condprob)

    addelement!(condprob, "Var", s_var_name(px))
    addelement!(condprob, "Parent", "null")

    parameter = ElementNode("Parameter")
    parameter["type"] = "TBL"
    link!(condprob, parameter)
    next!(pbar)

    init_states = initialstate(p)
    for s in states(p)
        if px.pretty
            label = "s_$(px.s_name(s))"
        else
            label = "s$(stateindex(p, s))"
        end

        link!(parameter, param(label; prob=pdf(init_states, s)))
        next!(pbar)
    end
end

function build_transitions!(root::Node, p::POMDP, px::POMDPXFile, pbar)
    statetrans = ElementNode("StateTransitionFunction")
    link!(root, statetrans)

    condprob = ElementNode("CondProb")
    link!(statetrans, condprob)

    addelement!(condprob, "Var", sp_var_name(px))
    addelement!(condprob, "Parent", "$(a_var_name(px)) $(s_var_name(px))")

    parameter = ElementNode("Parameter")
    link!(condprob, parameter)
    next!(pbar)

    for s=states(p)
        if isterminal(p, s)
            if px.pretty
                label = "* s_$(px.s_name(s)) s_$(px.s_name(s))"
            else
                label = "* s$(stateindex(p, s)) s$(stateindex(p, s))"
            end

            link!(parameter, param(label; prob=1.0))
            for _=1:(length(actions(p)) * length(states(p)))
                next!(pbar)
            end

            continue
        end

        for a=actions(p), sp=states(p)
            if px.pretty
                label = "a_$(px.a_name(a)) s_$(px.s_name(s)) s_$(px.s_name(sp))"
            else
                label = "a$(actionindex(p, a)) s$(stateindex(p, s)) s$(stateindex(p, sp))"
            end

            T = transition(p, s, a)
            if pdf(T, sp) > 0.0
                link!(parameter, param(label; prob=pdf(T, sp)))
            end
            next!(pbar)
        end
    end
end

function build_observations!(root::Node, p::POMDP, px::POMDPXFile, pbar)
    obsfun = ElementNode("ObsFunction")
    link!(root, obsfun)

    condprob = ElementNode("CondProb")
    link!(obsfun, condprob)

    addelement!(condprob, "Var", o_var_name(px))
    addelement!(condprob, "Parent", "$(a_var_name(px)) $(sp_var_name(px))")

    parameter = ElementNode("Parameter")
    link!(condprob, parameter)
    next!(pbar)

    try observation(p, first(actions(p)), first(states(p)))
    catch ex
        if ex isa MethodError
            @warn("""POMDPXFiles only supports observation distributions conditioned on `a` and `sp`.

                  Check that there is an `observation(::P, ::A, ::S)` method available (or an (::A, ::S) method of the observation function for a QuickPOMDP).

                  This warning is designed to give a helpful hint to fix errors, but may not always be relevant.
                  """, P=typeof(p), S=eltype(states(p)), A=eltype(actions(p)))
        end
        rethrow(ex)
    end

    for a=actions(p), sp=states(p), o=observations(p)
        if px.pretty
            label = "a_$(px.a_name(a)) s_$(px.s_name(sp)) o_$(px.o_name(o))"
        else
            label = "a$(actionindex(p, a)) s$(stateindex(p, sp)) o$(obsindex(p, o))"
        end

        O = observation(p, a, sp)
        if pdf(O, o) > 0.
            link!(parameter, param(label; prob=pdf(O, o)))
        end
        next!(pbar)
    end
end

function build_rewards!(root::Node, p::POMDP, px::POMDPXFile, pbar)
    rewardfunc = ElementNode("RewardFunction")
    link!(root, rewardfunc)

    func = ElementNode("Func")
    link!(rewardfunc, func)

    addelement!(func, "Var", r_var_name(px))
    addelement!(func, "Parent", "$(a_var_name(px)) $(s_var_name(px))")

    parameter = ElementNode("Parameter")
    link!(func, parameter)
    next!(pbar)

    reward_fn = StateActionReward(p)
    for a=actions(p), s=states(p)
        if px.pretty
            label = "a_$(px.a_name(a)) s_$(px.s_name(s))"
        else
            label = "a$(actionindex(p, a)) s$(stateindex(p, s))"
        end

        if !isterminal(p, s)
            link!(parameter, param(label; value=reward_fn(s, a)))
        end
        next!(pbar)
    end
end

function Base.write(p::POMDP, px::POMDPXFile)
    file = open(px.filename, "w")
    doc = build_xml(p, px)
    EzXML.prettyprint(file, doc)
    close(file)
end

function normalize(s)
	s = string(s)
	clean = replace(s, r"[^a-zA-Z0-9]" => "_")
	return replace(clean, r"_+" => "_")
end

function prettyprint(p::POMDP, px::POMDPXFile)
    file = open(px.filename, "w")
    doc = build_xml(p, px)
    EzXML.prettyprint(file, doc)
    close(file)
end
