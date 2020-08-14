# write to .pomdp file

"""
    Base.write(pomdp::POMDP, file::POMDPFile)
write a pomdp to a file in the .pomdp format
To read more about the .pomdp format visit https://www.pomdp.org/code/pomdp-file-spec.html
"""
function Base.write(pomdp::POMDP, file::POMDPFile)
    ss = ordered_states(pomdp)
    as = ordered_actions(pomdp)
    os = ordered_observations(pomdp)

    open(file.filename, "w") do io
        
        # headers 
        write(io, "discount: ", discount(pomdp))
        write(io, "values: reward")
        write(io, "states: ", length(ss))
        write(io, "actions: ", length(as))
        write(io, "observations: ", length(os), "\n")
        
        # initial belief 
        # start: 0.3 0.1 0.0 0.2 0.5 (example)
        write(io, "start: ")
        b0 = initialstate(pomdp)
        for (si, s) in enumerate(pomdp, s)
            write(io, pdf(b0, s), " ")
        end
        write(io, "\n\n")

        # transition
        # T: <action> : <start-state> : <end-state> %f
        for (ai, a) in enumerate(as)
            for (si, s) in enumerate(ss)
                td = transition(pomdp, s, a)
                for (sp, p) in weighted_iterator(td)
                    spi = stateindex(pomdp, sp)
                    write(io, "T: ", ai - 1, " : ", si - 1, " : ", spi - 1, " ", p, "\n")
                end
            end
        end
        write(io, "\n\n")

        # observation
        # O : <action> : <end-state> : <observation> %f
        for (ai, a) in enumerate(as)
            for (si, s) in enumerate(ss)
                od = observation(pomdp, a, sp)
                for (o, p) in weighted_iterator(od)
                    oi = obsindex(pomdp, o)
                    write(io, "O: ", ai - 1, " : ", si - 1, " : ", oi - 1, " ", p, "\n")
                end
            end
        end

        # rewards 
        for (ai, a) in enumerate(as)
            for (si, s) in enumerate(ss)
                for (spi, sp) in enumerate(ss)
                    r = reward(pomdp, s, a, sp)
                    if r != 0.0
                        write(io, "R: ", ai - 1, " : ", si - 1, 
                              " : ", spi - 1, " : ", " * ", r)
                    end
                end
            end
        end
    end
end

mutable struct POMDPFile
    file_name::AbstractString
end
