"Domain Specific Language for SEMs"
module SEMLang

# export @SEM, interpret, SEMSyntaxError
export @SEM
using ..CausalCore: ExogenousVariable, EndogenousVariable

struct SEMSyntaxError <: Exception
  msg
end

SEMSyntaxError() = SEMSyntaxError("")

"Parse exogenous variable `line`"
function parseexo(line)
  new_var = line.args[2]
  dist = line.args[3]
  esc(:($new_var = ExogenousVariable( $(Meta.quot(new_var)), $(dist))))
end

"Parse endogenous variable"
function parseendo(line)
  new_var = line.args[1] # name of new variable being defined
  args_expr = line.args[2] # expression of (nested) arguments for new variable
  operator = identity # initialize operator
  extracted_args_list = [] # list of argument expressions (un-nested)
  
  while typeof(args_expr) == Expr
    operator = args_expr.args[1]
    if (length(args_expr.args) == 3) # binary expression 
      extracted_arg = args_expr.args[3]
      push!(extracted_args_list, extracted_arg)
    end
    args_expr = args_expr.args[2]
  end

  push!(extracted_args_list, args_expr) # add last argument extracted from nested structure
  extracted_args = reverse(extracted_args_list) # reverse order of extracted arguments to match input expression

  if length(extracted_args) == 1
    esc(:($new_var = EndogenousVariable($(operator), ($(extracted_args[1]),))))
  else
    extracted_args_tuple = :($(extracted_args...),)
    esc(:($new_var = EndogenousVariable($operator, $extracted_args_tuple)))
  end 
end

"Structural Equation Model"
macro SEM(sem)
  if sem.head != :block
    throw(SEMSyntaxError("@SEM expects a block expression as input"))
  end
  semlines = Expr[]
  for line in sem.args
    if typeof(line) == Expr
      if line.head == :(=)
        expr = parseendo(line)
      elseif line.head == :call
        expr = parseexo(line)
      else
        throw(SEMSyntaxError())
      end
      push!(semlines, expr)
    end    
  end
  Expr(:block, semlines...)
end

end