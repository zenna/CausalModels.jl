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
  :($(line.args[1]) = ExogenousVariable($(Meta.quot(line.args[1])),$(line.args[2])))
end

"Parse endogenous variable `line`"
function parseendo(line)
end

"Structural Equation Model"
macro SEM(sem)
  if sem.head != :block
    throw(SEMSyntaxError("@SEM expects a block expression as input but was passed a "))
  end
  semlines = Expr[]
  for line in sem.args
    # Hints:
    # ignore the line if lina isa LineNumberNode
    # Use esc to escape
    # Use Meta.quot to put a symbol
  end
  Expr(:block, semlines...)
end

end