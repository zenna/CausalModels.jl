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
  name = line.args[2]
  distr = line.args[3]
  return :($(name) = ExogenousVariable($(Meta.quot(name)),$(distr)))
end

"Parse endogenous variable `line`"
function parseendo(line)
  #if using identity function (will change if other unaryops need to be accounted for)
  name = line.args[1]
  causality = line.args[2]
  #if caused by one variable
  if typeof(causality) == Symbol
    #assumes only identity func will be used, will modify if other unaryops need to be accounted for
    return :($(name) = EndogenousVariable($(identity), ($(causality),)))
  else
    logicalop = causality.args[1]
    var1 = causality.args[2]
    var2 = causality.args[3]
    return :($(name) = EndogenousVariable($(logicalop), ($(var1), $(var2))))
  end
end

"Structural Equation Model"
macro SEM(sem)
  if sem.head != :block
    throw(SEMSyntaxError("@SEM expects a block expression as input but was passed a "))
  end
  semlines = Expr[]
  for line in sem.args
    #if line is an expression and not a LineNumberNode 
    if typeof(line) == Expr
      # if is symbol call and uses exogenous var assignment ~
      if line.head == :call && line.args[1] == :~
        push!(semlines,parseexo(line))
      # if is assignment
      else if line.head == :(=)
        push!(semlines,parseendo(line))
      else 
        throw(SEMSyntaxError("@SEM expected an endogenous or exogenous variable but was passed neither"))
      end
    end
  end
  return esc(Expr(:block, semlines...))
end

end #end module
