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
    return :($(name)=ExogenousVariable($(Meta.quot(name)),$(dist)))
end
##handles case where we have variable operator variable

"Parse endogenous variable `line`"
function parseendo(line)
    # line=line.args[1]
    var_name,exp=line.args
    if typeof(exp)== Symbol
        return :($(var_name)=EndogenousVariable($(identity),($(exp),)))
    else
        arg1=exp.args[1]
        arg2=exp.args[2]
        arg3=exp.args[3]
        return :($(var_name)=EndogenousVariable($(arg1),($(arg2),$(arg3))))
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
        push!(semlines,parseendo(line))
    elseif line.args[1]==:(~)
        push!(semlines,parseexo(line))
    else
        throw(SEMSyntaxError("@SEM expects an expression with some form of equality "))
    end
  end
  println("before last command")
  return esc(Expr(:block, semlines...))

end

end