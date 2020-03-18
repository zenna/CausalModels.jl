"Domain Specific Language for SEMs"
module SEMLang

export @SEM, interpret, SEMSyntaxError
using ..CausalCore: ExogenousVariable, EndogenousVariable

struct SEMSyntaxError <: Exception
  msg
end

SEMSyntaxError() = SEMSyntaxError("")

"Parse exogenous variable"
function parseexo(line)
  # name stored in line.args[2], distr in line.args[3]
  # question: Is it bad practice to store line.args[2] in a named variable so macro is easier to understand?
  return :($(line.args[2]) = ExogenousVariable($(Meta.quot(line.args[2])),$(line.args[3])))
end

"Parse endogenous variable `line`"
function parseendo(line)
  #if using identity function (will change if other unaryops need to be accounted for)
  if typeof(line.args[2]) == Symbol
    return :($(line.args[1]) = EndogenousVariable($(identity), ($(line.args[2]),)))
  else
    return :($(line.args[1]) = EndogenousVariable($(line.args[2].args[1]), ($(line.args[2].args[2]), $(line.args[2].args[3]))))
  end
end

"Structural Equation Model"
macro SEM(sem)
  if sem.head != :block
    throw(SEMSyntaxError("@SEM expects a block expression as input but was passed a "))
  end
  semlines = Expr[]
  for lineNum in 1:length(sem.args)
    #if line isn't a LineNUmberNode 
    if lineNum%2 == 0
      line = sem.args[lineNum]
      if line.args[1] == :~
        push!(semlines,parseexo(line))
      else
        push!(semlines,parseendo(line))
      end
    end
  end
  return esc(Expr(:block, semlines...))
end

end #end module
