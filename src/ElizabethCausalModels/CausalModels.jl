module CausalModels

 using Distributions
 using Statistics
 export ExogenousVariable, EndogenousVariable, intervene, randomsample, prob


 """ """


 """Exogenous variables have a symbolic name and a stat which
 is their distibution"""
 struct ExogenousVariable
   name::Symbol
   stat
 end

 """Returns the"""
 function (v::ExogenousVariable)(tuple)
   if haskey(tuple, v.name)
     tuple[v.name]
   else
     rand(v.stat)
   end
 end

 function (v::ExogenousVariable)(tuple, procedure::Symbol)
   if procedure == :prob
     return (v.name, mean(v.stat))
   end
   if procedure == :use_stat
     return rand(v.stat)
   end
 end

 """ """
 struct EndogenousVariable
   func
   inputs
   use_values
   value_dict
 end

 EndogenousVariable(func, inputs) = EndogenousVariable(func, inputs, false, Dict())

 function (v::EndogenousVariable)(tuple)
   new_inputs = [i(tuple) for i in v.inputs]
   v.func(new_inputs...)
 end

 function (v::EndogenousVariable)(tuple, procedure::Symbol)
   if procedure==:use_stat
     new_inputs = [i(tuple, procedure) for i in v.inputs]
     return v.func(new_inputs...)
   end
   if procedure == :prob
     new_inputs = []
         for i in v.inputs
           append!(new_inputs, i(tuple, procedure))
         end
         return new_inputs
       end

 end

 #reduces the function with the given input and returns a random value
 function randomsample(input)
   input((), :use_stat)
 end

 #finds the probability of the event happening with constant_key and contant_val
 #being set as given if given
 function prob(input::EndogenousVariable)
   prob_endo(input)
 end

 function prob(input::CondVariable)
   input((), :prob)
 end

 function prob_endo(input)
   prob_dict, permutations = create_permutations(input)
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
       if input.use_values
         return probability*2
       end
       return probability

   end

 #creates all of the possible permutations of the given variables
 #if constant_key is given then uses that as substitution for that variable
 function create_permutations(endo_var)
   vars = endo_var((), :prob)
   prob_dict = Dict()
   var_length = length(vars)
   if mod(var_length, 2)!=0
     var_length += 1
   end
   for i in (1, convert(UInt8, var_length/2))
     prob_dict[vars[i*2-1]]= vars[i*2]
   end

   permutations = [Dict()]
   if endo_var.use_values
     permutations = [copy(endo_var.value_dict)]
   end

   for key in keys(prob_dict)
     if !(key in keys(endo_var.value_dict))
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
   return prob_dict, permutations
 end


 #currently returns the probability of what happens with this intervention
 #needs to be changed
 function intervene(input, name, value)
   return EndogenousVariable(input.func, input.inputs, true, Dict(name.name => value))
 end

 struct CondVariable
   A
   B
 end

 function cond(A, B)
   return CondVariable(A, B)
 end

 function (v::CondVariable)(input, procedure::Symbol)
     prob_dictA, permutationsA = create_permutations(v.A)
     prob_dictB, permutationsB = create_permutations(v.B)
     if procedure==:use_stat
       index = convert(UInt8, round(rand(1)[1]*length(permutationsB)+.5))
       if permutationsB[index] in permutationsA
         return 1
       end
       return 0
     end
     if procedure==:prob
       perm_AandB = []
       intersect_prob = 0
       for dict_A in permutationsA
         if dict_A in permutationsB
           append!(perm_AandB, [dict_A])
           current_prob = 1
           for key in keys(dict_A)
             if dict_A[key]==1
               current_prob*= mean(prob_dictA[key])
             else
               current_prob*=(1-mean(prob_dictA[key]))
             end
           end
           intersect_prob += current_prob
         end
       end
       return intersect_prob/prob(v.B)
     end
   end



 courtorder = ExogenousVariable(:courtorder, Bernoulli(0.5))
 courtorder.name
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
 prob(dead)

 dead2 = intervene(dead, nervous, 0)
 dead2.value_dict
 prob(dead2)

 dead_counterfactual = cond(dead2, dead)

 prob(dead2)

 prob(dead_counterfactual.B)
 randomsample(dead_counterfactual)
 prob_cf = prob(dead_counterfactual)


 #throw error if B is false in random sampling or applying to values
 prob(cond(courtorder, dead))
 #should be able to do this
