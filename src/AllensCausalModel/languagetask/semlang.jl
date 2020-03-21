

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
  :($(line.args[2]) = ExogenousVariable($(Meta.quot(line.args[2])),$(line.args[3])))
end
"""
parse endogenous variable
"""
function parseendo(line)
  subexpr = line.args[2]
  if typeof(subexpr) == Symbol
    return :($(line.args[1]) = EndogenousVariable(identity,($(subexpr),)))
  elseif length(subexpr.args) == 2
    return :($(line.args[1]) = EndogenousVariable($(subexpr.args[1]),($(subexpr.args[2]),)))
  else
    return :($(line.args[1]) = EndogenousVariable($(subexpr.args[1]),($(subexpr.args[2]),$(subexpr.args[3]))))
  end
  #:($(line.args[1])=ExogenousVariable())
  line.args[2]
end
"""
Structural Equation Model
"""
macro SEM(sem)
  if sem.head != :block
    throw(SEMSyntaxError("@SEM expects a block expression as input but was passed a "))
  end
  semlines = Expr[]
  for line in sem.args
    if !(line isa LineNumberNode)
      if line.args[1] == :~
        push!(semlines,parseexo(line))
      elseif line.head == :(=)
        push!(semlines,parseendo(line))
      else
        throw(SEMSyntaxError("invalid line in block"))
      end
    end
  end
  esc(Expr(:block, semlines...))
end

# # Grammar  FINISHME
# An SEM model is an `expr` defiend by the following grammar:

"""
Prim        := Bernoulli | Uniform | Normal | ...
Dist        := Prim(Number)
Variable    := Symbol|Number
unaryop     := !,-
binaryop    := + | - | * | / | > | >= | <= | < | ...
line        := Symbol=unaryop Variable| Symbol=Variable binaryop Variable|Symbol~Dist
expr        := line|line \n expr
"""
