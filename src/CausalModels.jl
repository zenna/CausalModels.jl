module CausalModels
using Distributions
using Statistics
export ExogenousVariable, EndogenousVariable, randomsample, prob, intervene

# Fill in the rest
struct ExogenousVariable
    name
    distribution
end

struct EndogenousVariable
    operator
    parents
end

function (u::EndogenousVariable)(u_)
    evaluated_vars = map(parent -> (parent)(u_), u.parents)
    return reduce(u.operator, evaluated_vars)
end

function (u::ExogenousVariable)(u_)
    for val in keys(u_)
        if u.name == val
            return getindex(u_, val)
        end
    end
end

function randomsample(u::EndogenousVariable)
    sample_values = map(parent -> randomsample(parent), u.parents)
    reduce(u.operator, sample_values)
end

function randomsample(u::ExogenousVariable)
    rand(u.distribution)
end

function prob(u::EndogenousVariable)
    total = 0
    for i=1:10000
        total += randomsample(u)
    end
    total/10000
    #=
    # The below calculates the exact probability.

    parent_probs = map(parent -> prob(parent), u.parents)
    println("parent_probs")
    println(parent_probs)
    if u.operator == |
        complement_parent_probs = map(val -> 1 - val, parent_probs)
        1 - reduce(*, complement_parent_probs) 
    elseif u.operator == &
        reduce(*, parent_probs)
    elseif u.operator == identity
        parent_probs[1]
    end
    =#
end

function prob(u::ExogenousVariable)
    params(u.distribution)[1] # get probability that exogenous variable is 1
end

function intervene(u1::EndogenousVariable, u2::ExogenousVariable, val) 
    new_parents = map(parent -> intervene(parent, u2, val), u1.parents)
    EndogenousVariable(u1.operator, new_parents)
end

function intervene(u1::ExogenousVariable, u2::ExogenousVariable, val) 
    if (u1.name == u2.name)
        if val == 0
            ExogenousVariable(u1.name, Bernoulli(0))
        else
            ExogenousVariable(u1.name, Bernoulli(1))
        end        
    else
        u1
    end
end

end