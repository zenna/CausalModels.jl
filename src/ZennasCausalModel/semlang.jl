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
  :($new_var = ExogenousVariable( $(Meta.quot(new_var)), $(dist)))
end

"Parse endogenous variable; code currently does not support multiple different
 operators in a single expression, but rather only the same operator:
 e.g. AShoots | BShoots | CShoots | ... is acceptable, but not
      AShoots * BShoots + CShoots ... (throws an error)
"
function parseendo(line)
  newvar = line.args[1] # name of new variable being defined
  argsExpr = line.args[2] # expression of (nested) arguments for new variable
  binary_op = undef; # initialize binary operator
  unary_op = undef; # initialize unary operator
  
  # initialize un-nested list of arguments in string form; this is used
  # to construct an un-nested argument tuple in the final return expression
  extracted_args_list = []

  while typeof(argsExpr) == Expr
    if (length(argsExpr.args) == 2) # unary expression 
      unary_op = argsExpr.args[1]
    else # binary expression
      if (binary_op != undef && binary_op != argsExpr.args[1])
        throw(SEMSyntaxError("@SEM expects uniform operator in input line"))
      end
      binary_op = argsExpr.args[1]
      extracted_arg = argsExpr.args[3]
      if (typeof(extracted_arg) == Symbol)
        extracted_arg_str = repr(extracted_arg)
        extracted_arg_str = extracted_arg_str[2:length(extracted_arg_str)]
        push!(extracted_args_list, extracted_arg_str)
      else
        push!(extracted_args_list, repr(extracted_arg))
      end
    end
    argsExpr = argsExpr.args[2]
  end

  # handle last argument extracted from nested structure
  if typeof(argsExpr) == Symbol
    push!(extracted_args_list, (repr(argsExpr))[2:length(repr(argsExpr))])
  else # argList is a constant
    push!(extracted_args_list, argsExpr)
  end
  # reverse order of extracted arguments to match input expression
  extracted_args = reverse(extracted_args_list)

  if binary_op == undef # expression is unary
    extracted_arg = Meta.parse(extracted_args[1])
    if unary_op == undef # operator is identity
      :($newvar = EndogenousVariable(identity, ($extracted_arg,)))
    else # operator is not identity (!)
      :($newvar = EndogenousVariable($unary_op, ($extracted_arg,)))
    end  
  else # expression is binary
    extracted_args_str = join(extracted_args, ",")
    extracted_args = Meta.parse(extracted_args_str)
    :($newvar = EndogenousVariable($binary_op, $extracted_args))
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
      else
        expr = parseexo(line)
      end
      push!(semlines, expr)
    end    
  end
  Expr(:block, semlines...)
end

end