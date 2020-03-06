using CausalModels, Distributions, Test

# Construct an exogenous variable with name :courtorder and distribution Bernoulli
courtorder = ExogenousVariable(:courtorder, Bernoulli(0.5))
nervous = ExogenousVariable(:nervous, Bernoulli(0.5))
anot=ExogenousVariable(:anot,Bernoulli(0.5))
bnot=ExogenousVariable(:bnot,Bernoulli(0.5))
cnot=EndogenousVariable(&,(anot,bnot))
#  Construct an endogenous variable with function | (logical or)
# and arguments nervous and courtorder
Ashoots = EndogenousVariable(|, (nervous, courtorder))
Bshoots = EndogenousVariable(identity, (courtorder,))
dead = EndogenousVariable(|, (Ashoots, Bshoots))
dead5=EndogenousVariable(&,(cnot,dead))
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
k=prob(dead)
@test isapprox(prob(dead), 0.75; atol = 0.01)
# Construct intervention: what would dead have been if nervous was 0
dead2 = intervene(dead, nervous, 0)
@test isapprox(prob(dead2), 0.5; atol = 0.01)
dead3=intervene(dead,Ashoots,0)
@test isapprox(prob(dead3),0.5;atol=0.01)
@test isapprox(prob(dead5),3/16;atol=0.01)
dead6=intervene(dead5,cnot,1)
@test isapprox(prob(dead6),0.75,atol=0.01)
dead7=intervene(dead5,cnot,0)
@test isapprox(prob(dead7),0,atol=0.01)
dead8=intervene(dead5,dead,1)
@test isapprox(prob(dead8),0.25,atol=0.01)
dead_counterfactual = cond(dead2, dead)
randsample(dead_counterfactual)
prob_cf = prob(dead_counterfactual)
@test isapprox(prob(prob_cf), 0.67; atol = 0.01)
println("done")