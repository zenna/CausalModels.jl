

"Domain Specific Language for SEMs"
module SEMLang

export @SEM, interpret, SEMSyntaxError
using ..CausalCore: ExogenousVariable, EndogenousVariable

struct SEMSyntaxError <: Exception
  msg
end

SEMSyntaxError() = SEMSyntaxError("")
"""
parse exogenous variable
"""
function parseexo(line)
  :($(line.args[2])=ExogenousVariable($(Meta.quot(line.args[2])),$(line.args[3])))
end
"""
parse endogenous variable
"""
function parseendo(line)
  subexpr=line.args[2]
  if typeof(subexpr)==Symbol
    return :($(line.args[1])=EndogenousVariable(identity,($(subexpr),)))
  elseif length(subexpr.args)==2
    return :($(line.args[1])=EndogenousVariable($(subexpr.args[1]),($(subexpr.args[2]),)))
  else
    return :($(line.args[1])=EndogenousVariable($(subexpr.args[1]),($(subexpr.args[2]),$(subexpr.args[3]))))
  end
  #:($(line.args[1])=ExogenousVariable())
  line.args[2]
end
macro SEM(sem)
  for i in 1:length(sem.args)
    if i%2==0
      line=sem.args[i]
      if line.args[1]==:~
        println(parseexo(line))
      else
        println(parseendo(line))
      end
    end
  end
end
"""
Structural Equation Model
"""
macro SEM(sem)
  if sem.head != :block
    throw(SEMSyntaxError("@SEM expects a block expression as input but was passed a "))
  end
  semlines = Expr[]
  for i in 1:length(sem.args)
    if i%2==0
      line=sem.args[i]
      if line.args[1]==:~
        push!(semlines,parseexo(line))
      else
        push!(semlines,parseendo(line))
      end
    end
  end
  esc(Expr(:block, semlines...))
end

end
# # Grammar  FINISHME
# An SEM model is an `expr` defiend by the following grammar:

"""
Prim        := Bernoulli | Uniform | Normal | ...
Variable    := Symbol|Number
unaryop     := !,-
binaryop    := + | - | * | / | > | >= | <= | < | ...
expr        := Symbol=unaryop Variable| Symbol=Variable binaryop Variable|Symbol~Prim
"""
