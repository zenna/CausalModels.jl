module CausalModels

using Distributions
using Statistics
export ExogenousVariable, EndogenousVariable, intervene, randomsample, prob

# notes for how to do the functions for objects
# struct ExogenousVariable2
#   name
#   stat
# end
#
# courtorder = ExogenousVariable2(:courtorder, Bernoulli(0.5))
# function (v::ExogenousVariable2)(input)
#   return input
# end
# courtorder(1)

#Returns a function that takes in inputs and returns different values
#based on whether use_stat, prob, or get_name are true
#use_stat returns a random value from the distribution'
#prob returns the name and mean to be use for probability calculations
#get_name returns the symbolic name of the var
#otherwise uses the given variable substitution or returns random value
function ExogenousVariable(name, stat)
  function insert_tuples(tuple, use_stat=false, prob=false, get_name=false)
    if get_name
      return name
    end
    if use_stat
      return rand(stat)
    end
    if prob
      return (name, mean(stat))
    end
    if haskey(tuple, name)
      tuple[name]
    else
      rand(stat)
    end
  end
end


#Returns a function that evaluates the given inputs and will return
#either the value with the inputs substituted in
#or the random value generated with use_stat
#or the probability of the event happening with prob
function EndogenousVariable(func, inputs)
  function apply(tuple, use_stat=false, prob=false)
    new_inputs = []
    for i in inputs
      append!(new_inputs, i(tuple, use_stat, prob))
    end
    #[i(tuple, use_stat, prob) for i in inputs]
    #new_inputs
    if prob
      return new_inputs
    end
    func(new_inputs...)
  end
end

#reduces the function with the given input and returns a random value
function randomsample(input)
  input((), true)
end

#finds the probability of the event happening with constant_key and contant_val
#being set as given if given
function prob(input, constant_key=-1, constant_val=-1)
  vars = input((), false, true)
  prob_dict = Dict()
  for i in (1, convert(UInt8, length(vars)/2))
    prob_dict[vars[i*2-1]]= vars[i*2]
  end
  #     append!(list_names, vars[2*i])
  #     append!(list_prob, vars[2*i+1])
  # end
  # list_names
  permutations = create_permutations(prob_dict, constant_key, constant_val)
  probability = 0
  for perm_dict in permutations
    if input(perm_dict)==1
      current_prob = 1
      for key in keys(perm_dict)
        if perm_dict[key]==1
          current_prob*= mean(prob_dict[key])
        else
          current_prob*=(1-mean(prob_dict[key]))
        end
      end
      probability += current_prob
      end
      end
      if constant_val!=-1
        return probability*2
      end
      return probability

  end

#creates all of the possible permutations of the given variables
#if constant_key is given then uses that as substitution for that variable
function create_permutations(prob_dict, constant_key, constant_val=-1)
  permutations = [Dict()]
  if constant_val != -1
    permutations = [Dict(constant_key=>constant_val)]
  end
  for key in keys(prob_dict)
    if key!=constant_key
      to_add = []
      for perm in permutations
        perm_copy = Dict(copy(perm))
        perm[key] = 0
        perm_copy[key] = 1
        append!(to_add, [perm_copy])
      end
      append!(permutations, to_add)
    end
  end

  return permutations
end


#currently returns the probability of what happens with this intervention
#needs to be changed
function intervene(input, name, value)
  prob(input, name((), false, false, true), value)
end


courtorder = ExogenousVariable(:courtorder, Bernoulli(0.5))
nervous = ExogenousVariable(:nervous, Bernoulli(0.5))
Ashoots = EndogenousVariable(|, (nervous, courtorder))
Bshoots = EndogenousVariable(identity, (courtorder,))
dead = EndogenousVariable(|, (Ashoots, Bshoots))
u1 = (courtorder = 0, nervous = 1)

u2 = (courtorder = 0, nervous = 0)
dead(u2) == 0

u3 = (courtorder = 1, nervous = 0)
dead(u3) == 1

randomsample(dead)
courtorder((), false, true)
nervous((), false, true)
Ashoots((), false, true)
Bshoots((), false, true)
prob(dead)

dead2 = intervene(dead, nervous, 0)
intervene(dead, courtorder, 0)
