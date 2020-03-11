"Domain Specific Language for SEMs"
module SEMLang
using Distributions: Distribution
using Statistics
export @SEM, interpret, SEMSyntaxError
using ..CausalCore: ExogenousVariable, EndogenousVariable, prob

struct SEMSyntaxError <: Exception
  msg
end

SEMSyntaxError() = SEMSyntaxError("")

"Parse exogenous variable"
function parseexo(line)
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
  line0 = ""

  for line in sem.args
    if !(line isa LineNumberNode)
      expr = false
       if line.args[1] == :(~)
        # line.args[2] = ExogenousVariable(line.args[2], line.args[3])
        store = esc(:($(line.args[2]) = ExogenousVariable($(Meta.quot(line.args[2])), $(line.args[3]))))
        append!(semlines, [store])
      end
      if line.head == :(=)
        if line.args[2] isa Expr
          if length(line.args[2].args) == 3
            line0 = line.args[2]
            store = esc(:($(line.args[1]) = EndogenousVariable($(line.args[2].args[1]), ($(line.args[2].args[2]), $(line.args[2].args[3])))))
          end
          if length(line.args[2].args) == 2
            store = esc(:($(line.args[1]) = EndogenousVariable($(line.args[2].args[1]), ($(line.args[2].args[2])))))
          end
        else
          store = esc(:($(line.args[1]) = EndogenousVariable(identity, ($(line.args[2]),))))
        end
        append!(semlines, [store])
      end
    end
    # Hints:
    # ignore the line if lina isa LineNumberNode
    # Use esc to escape
    # Use Meta.quot to put a symbol
  end
  return Expr(:block, semlines...)
end

@macroexpand @SEM begin
    nervous ~ Bernoulli(0.5)
    courtorder ~ Bernoulli(0.5)
    Ashoots = nervous | courtorder
    Bshoots = courtorder
    dead = Ashoots | Bshoots
end

prob(dead)

end
