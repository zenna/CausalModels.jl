module CausalModels
using Distributions
using Statistics
export ExogenousVariable, EndogenousVariable, randomsample, prob

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
    reduce(u.operator, evaluated_vars)
end

function (u::ExogenousVariable)(u_)
    for val in u_
        if u.name == val
            val
        end
    end
end

function randomsample(u::EndogenousVariable)
    sample_values = map(parent -> randomsample(parent.distribution), u.parents)
    reduce(u.operator, sample_values)
end

function randomsample(u::ExogenousVariable)
    rand(u.distribution)
end

function prob(u::EndogenousVariable)
    parent_probs = map(parent -> prob(parent), u.parents)
    if u.operator == |
        complement_parent_probs = map(val -> 1 - val, parent_probs)
        1 - reduce(*, complement_parent_probs) 
    elseif u.operator == &
        reduce(*, parent_probs)
    end
end

function prob(u::ExogenousVariable)
    params(u.distribution)[1] # get probability that exogenous variable is 1
end

end