using CausalModels, Distributions, Test

# # Construct an exogenous variable with name :courtorder and distribution Bernoulli
# courtorder = ExogenousVariable(:courtorder, Bernoulli(0.5))
# nervous = ExogenousVariable(:nervous, Bernoulli(0.5))

# #  Construct an endogenous variable with function | (logical or)
# # and arguments nervous and courtorder
# Ashoots = EndogenousVariable(|, (nervous, courtorder))
# Bshoots = EndogenousVariable(identity, (courtorder,))
# dead = EndogenousVariable(|, (Ashoots, Bshoots))

# # Construct some values for exogenous variables (using namedtuple)
# u1 = (courtorder = 0, nervous = 1)

# # dedd(u1) is value of dead given these values of exogenous variables
# @test dead(u1) == 1

# u2 = (courtorder = 0, nervous = 0)
# @test dead(u2) == 0

# u3 = (courtorder = 1, nervous = 0)
# @test dead(u3) == 1

# # Return a random sample from `dead`
# @test randomsample(dead) ∈ [0, 1]

# # Compute probability that `dead` is 1
# @test isapprox(prob(dead), 0.75; atol = 0.01)

# # Construct intervention: what would dead have been if nervous was 0
# dead2 = intervene(dead, nervous, 0)

# @test isapprox(prob(dead2), 0.5; atol = 0.01)


# dead_counterfactual = cond(dead2, dead)
# randomsample(dead_counterfactual)
# prob_cf = prob(dead_counterfactual)
# @test isapprox(prob_cf, 0.67; atol = 0.01)

# approxeq(x, y) = isapprox(x, y; atol = 0.01)

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