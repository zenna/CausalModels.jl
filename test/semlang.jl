using CausalModels

using Test

approxeq(x, y) = isapprox(x, y; atol = 0.01)

@SEM begin
    nervous ~ Bernoulli(0.5)
    courtorder ~ Bernoulli(0.5)
    Ashoots = nervous | courtorder
    Bshoots = courtorder
    dead = Ashoots | Bshoots
end

prob(dead)
randomsample(dead)

@SEM begin
    n ~ Poisson(0.5)
    x = n + 10
    z = n > 3
end

@test approxeq(prob(z), .001)
@test approxeq(prob(cond(z, z); n = 100), 1.0)

@SEM begin
    x ~ Normal(0.0, 1.0)
    y = -x
    ispos = x > 0
    isneg = x < 0
end

xsamples = [randomsample(cond(y, ispos)) for i = 1:10]
@test all(x -> x < 0, xsamples)
@test prob(cond(isneg, ispos); n = 10) == 0.0

# # Grammar  FINISHME
# An SEM model is an `expr` defiend by the following grammar:

"""
Prim        := Bernoulli | Uniform | Normal | ...
unaryop     := !
binaryop    := + | - | * | / | > | >= | <= | < | ...
expr        := symbol ~ Prim | symbol = [Prim | expr] binaryop [Prim| expr] |
                symbol = unaryop [Prim | expr] | symbol = [Prim | expr]
"""
