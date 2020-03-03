module CausalModels
using Distributions
using Statistics
export ExogenousVariable, EndogenousVariable, randomsample, prob, intervene

"""
Struct for an exogenous variable.
@param name: name of variable.
@param distribution: distribution of variable.
"""
struct ExogenousVariable
    name
    distribution
end

"""
Struct for an endogenous variable.
@param operator: relation between parent variables (e.g. |, identity, &).
@param parents: parent variables on which given variable depends.
"""
struct EndogenousVariable
    operator
    parents
end

"""
Evalutes an endogenous variable given values of parent exogenous variables.
@param u_: named tuple of exogenous variable values.
"""
function (u::EndogenousVariable)(u_)
    evaluated_vars = map(parent -> (parent)(u_), u.parents)
    return reduce(u.operator, evaluated_vars)
end

"""
Finds exogenous variable value from list of exogenous variable values.
@param u_: named tuple of exogenous variable values.
"""
function (u::ExogenousVariable)(u_)
    for name in keys(u_)
        if u.name == name
            return getindex(u_, name)
        end
    end
end

"""
Randomly samples value from an endogenous variable.
@param u: endogenous variable to sample.
"""
function randomsample(u::EndogenousVariable)
    sample_values = map(parent -> randomsample(parent), u.parents)
    reduce(u.operator, sample_values)
end

"""
Randomly samples value from an exogenous variable.
@param u: exogenous variable to sample.
"""
function randomsample(u::ExogenousVariable)
    rand(u.distribution)
end

"""
Compute probability that endogenous variable = 1.
@param u: endogenous variable of which to compute probability.
"""
function prob(u::EndogenousVariable)
    NSAMPS = 10000
    total = 0
    for i=1:NSAMPS
        total += randomsample(u)
    end
    total/NSAMPS
end

"""
Compute probability that exogenous variable = 1.
@param u: exogenous variable of which to compute probability.
"""
function prob(u::ExogenousVariable)
    params(u.distribution)[1] # get probability that exogenous variable is 1
end

"""
Constructs new endogenous variable based on an intervention of an existing variable.
@param u1: endogenous variable that undergoes intervention.
@param u2: exogenous variable that takes deterministic value under intervention.
@param val: value of exogenous variable under intervention.
"""
function intervene(u1::EndogenousVariable, u2::ExogenousVariable, val) 
    new_parents = map(parent -> intervene(parent, u2, val), u1.parents)
    EndogenousVariable(u1.operator, new_parents)
end

"""
Constructs new, deterministic exogenous variable based on an intervention.
@param u1: exogenous variable that undergoes intervention.
@param u2: exogenous variable that takes deterministic value under intervention.
@param val: value of exogenous variable under intervention.
"""
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