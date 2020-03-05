module CausalModels

using Distributions: Distribution
using Statistics
export ExogenousVariable, EndogenousVariable, intervene, randomsample, prob, cond

"An exogenous variable with `dist` as prior distribution"
struct ExogenousVariable{D <: Distribution}
  name::Symbol
  dist::D
end

Base.show(io::IO, u::ExogenousVariable) = Base.print(io, "$(u.name) ~ $(u.dist)")

"""
Endogenous variable `f(args)` where a ∈ args is:
constant, exogenous or endogenous variable
"""
struct EndogenousVariable{F, ARGS}
  func::F 
  args::ARGS
end

Base.show(io::IO, v::EndogenousVariable) = Base.print(io, "$(v.func)($(v.args...))")

# Treat constants as constant functions, i.e. f(x) = c
apply(constant, u) = constant

# u(u_)
apply(u::ExogenousVariable, u_) = u_[u.name] 

"`v(u)` -- apply `v` to context `u`"
apply(v::EndogenousVariable, u_) =
  v.func(map(parent -> apply(parent, u_), v.args)...)

# f(x) = apply(f, x)
(v::EndogenousVariable)(u) = apply(v, u)

intervene(U::ExogenousVariable, X, x) = U

function intervene(V::EndogenousVariable, X, x)
  if V == X
    EndogenousVariable(identity, (x,))
  else
    newargs = map(V.args) do parent
      if parent == X
        x
      else
        intervene(parent, X, x)
      end
    end
    EndogenousVariable(V.func, newargs)
  end
end

## Sampling
struct SampleU
  vals::Dict{Symbol, Any}
end

function apply(u::ExogenousVariable, u_::SampleU)
  get!(() -> rand(u.dist), u_.vals, u.name)
end

"Sample estimate of probability using `n` samples"
prob(v; n = 1000000) = Statistics.mean([randomsample(v) for i = 1:n])

"Conditional Endogenous Variable `A | B`"
struct CondEndogenousVariable{A, B}
  a::A    # Arbitrary endogenous variable
  b::B    # Boolean valued endogenous variable
end

"`a | b` -- `a` given that `b` is true"
cond(a, b) = CondEndogenousVariable(a, b)

"Error to be thrown when `v(u)` violates conditions`"
struct UnsatisfiedCondition <: Exception
end

apply(v::CondEndogenousVariable, u) =
  if Bool(v.b(u)); v.a(u); throw(UnsatisfiedCondition()) end

(v::CondEndogenousVariable)(u) = apply(v, u)

"Sample from `v`"
function randomsample(v)
  # rejection sampling -- retry if unsatcondition thrown
  while true
    try
      return v(SampleU(Dict()))
    catch UnsatisfiedCondition
      @show "UnsatisfiedCondition"
    end
  end
end
  
end
