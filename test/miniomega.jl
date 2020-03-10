using CausalModels.MiniOmega: Ω, logpdf, TAG, Tagged
using Distributions

x = ω -> Normal(ω, 0, 1)
ω = Ω(Dict())
x(ω)

f(x::Int) = 3
f(x::TAG{Int}) = 4

f(1)
f(Tagged(3, :data))