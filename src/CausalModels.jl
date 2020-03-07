module CausalModels

using Distributions
using Statistics
export ExogenousVariable, EndogenousVariable, intervene, randomsample, prob

# Fill in the rest
struct ExogenousVariable
    name::Symbol
    dist::Bernoulli{Float64}
end

struct EndogenousVariable
    logical_operator
    args::Tuple
end

struct ModifiedEndoVar
    endo_var::EndogenousVariable
    dict::Dict
end

function (v::EndogenousVariable)(u::NamedTuple{(:courtorder, :nervous),Tuple{Int64,Int64}})
    total = u.courtorder + u.nervous
    if total == 0
        return 0
    else
        return 1
    end
end

function randomsample(var, calculated=Dict())
    if typeof(var) == ExogenousVariable 
        # if exogenous variable value was already sampled or determined
        if haskey(calculated, var.name)
            return calculated[var.name]
        else
            sample = rand(var.dist)
            calculated[var.name] = sample
            return sample
        end
    elseif typeof(var) == EndogenousVariable
        args = var.args
        logical_op = var.logical_operator
        # 2 arguments means |, 1 argument means identity
        if size(args,1) == 2
            return logical_op(randomsample(args[1], calculated), randomsample(args[2], calculated))
        elseif size(args,1) == 1
            return logical_op(randomsample(args[1],calculated))
        else
            return 0
        end
    else
        return var
    end
end

# calculating experimental probability of event when no variable value has been set.
function prob(var, numtrials = 100000)
    i = 0
    num_success = 0        
    while i < numtrials
        if randomsample(var, Dict()) == 1
            num_success += 1
        end
        i += 1
    end
    return num_success/i
end

# calculating experimental probability of event when an variable value has been set
function prob(mod_endo_var::ModifiedEndoVar)
    i = 0
    num_success = 0        
    while i < 1000000
        # copy preset values to a new dict so that non-preset values won't be permanently saved in dict
        dict_keys = collect(keys(mod_endo_var.dict))
        old_dict = mod_endo_var.dict
        new_dict = Dict()
        for key in dict_keys
            new_dict[key] = old_dict[key]
        end

        # run one trial and tally successes
        if randomsample(mod_endo_var.endo_var, new_dict) == 1
            num_success += 1
        end
        i += 1
    end
    return num_success/i
end

function randomsample(mod_endo_var::ModifiedEndoVar)
    # copy preset values to a new dict so that non-preset values won't be permanently saved in dict
    dict_keys = collect(keys(mod_endo_var.dict))
    old_dict = mod_endo_var.dict
    new_dict = Dict()
    for key in dict_keys
        new_dict[key] = old_dict[key]
    end
    return randomsample(mod_endo_var.endo_var, new_dict)
end

function intervene(endo_var::EndogenousVariable, var::ExogenousVariable, var_value::Int64)
    mod_endo_var = ModifiedEndoVar(endo_var, Dict(var.name => var_value))
    return mod_endo_var
end

function cond(var1, var2)
    return (var1, var2, Dict())
end

function randomsample(vars::Tuple)
    X = randomsample(vars[1])
    x_dict = X.dict
    Y = randomsample(vars[2])
end

function prob(vars::Tuple)
    var1 = vars[1]
    var2 = vars[2]
    i = 0
    num_success = 0   
    dict_keys = collect(keys(var1.dict))
    old_dict = var1.dict
    new_dict = Dict()
    for key in dict_keys
        new_dict[key] = old_dict[key]
    end 
    while i < 1000000
        # run one trial and tally successes
        if randomsample(var1, new_dict) == 1
            num_success += 1
        end
        i += 1
    end
    probvar1 =  num_success/i
    
    
end
 
end
