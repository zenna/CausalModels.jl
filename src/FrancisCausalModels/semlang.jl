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
    assignment,name,dist=line.args
    return :(name=ExogenousVariable(name,dist))
end
##handles case where we have variable operator variable

"Parse endogenous variable `line`"
function parseendo(line)
    var_name,exp=line.args
    if exp isa Symbol
        return :(var_name=EndogenousVariable(var_name,(exp,)))
    else
        arguments=exp.args
        test= :(var_name=EndogenousVariable(arguments[1],(arguments[2],arguments[3])))
        return test
    end
end

"Structural Equation Model"
macro SEM(sem)
  if sem.head != :block
    throw(SEMSyntaxError("@SEM expects a block expression as input but was passed a "))
  end
  semlines = Expr[]
  for line in sem.args
    # # Hints:
    # # ignore the line if lina isa LineNumberNode
    # # Use esc to escape
    # # Use Meta.quot to put a symbol
    if line isa LineNumberNode
        continue 
    
    elseif line.head==:(=)
        test2=parseendo(line)
        push!(semlines,parseendo(line))
    elseif line.args[1]==:(~)

        push!(semlines,parseexo(line))
    else
        throw(SEMSyntaxError("@SEM expects an expression with some form of equality "))
    end
  end
  Expr(:block, semlines...)
end

end