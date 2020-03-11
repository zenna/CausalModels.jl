# Construct an exogenous variable with name :courtorder and distribution Bernoulli
courtorder = ExogenousVariable(:courtorder, Bernoulli(0.5))
nervous = ExogenousVariable(:nervous, Bernoulli(0.5))
Ashoots = EndogenousVariable(|, (nervous, courtorder))
Bshoots = EndogenousVariable(identity, (courtorder,))
dead = EndogenousVariable(|, (Ashoots, Bshoots))

# Construct some values for exogenous variables (using namedtuple)
u1 = (courtorder = 0, nervous = 1)

# dedd(u1) is value of dead given these values of exogenous variables
@test dead(u1) == 1

u2 = (courtorder = 0, nervous = 0)
@test dead(u2) == 0

u3 = (courtorder = 1, nervous = 0)
@test dead(u3) == 1

# Return a random sample from `dead`
@test randomsample(dead) ∈ [0, 1]

# Compute probability that `dead` is 1
@test isapprox(prob(dead), 0.75; atol = 0.01)

# Construct intervention: what would dead have been if nervous was 0
dead2 = intervene(dead, nervous, 0)

@test isapprox(prob(dead2), 0.5; atol = 0.01)


dead_counterfactual = cond(dead2, dead)
randomsample(dead_counterfactual)
prob_cf = prob(dead_counterfactual)
@test isapprox(prob_cf, 0.67; atol = 0.01)