module CausalModels
using Distributions
using Statistics
export ExogenousVariable, EndogenousVariable, intervene, randomsample, prob
	#represent as function with id
	function ExogenousVariable(name,dist)
		id=rand(1)
		function d(x;calculated=Dict())
			if x=="id"
				return id
			elseif haskey(calculated,d("id"))
				return get(calculated,d("id"),0)
			elseif name in keys(x)
				return x[name]
			else
				return rand(dist,1)[1]
			end
		end
		return d
	end
	#represent as function with id
	function EndogenousVariable(func, args)
		id=rand(1)
		function d(x;calculated=Dict())
			if x=="id"
				return id
			elseif haskey(calculated,d("id"))
				return get(calculated,d("id"),0)
			end
			function eval(f)
				retval=f(x,calculated=calculated)
				push!(calculated,f("id")=>retval)
				retval
			end
			vals=[eval(a) for a in args]
			func(vals...)
		end
		return d
	end
	function randomsample(var)
		return var((aqwreqwe=true,))
	end
	function prob(var)
		NSAMPS=100000
		count=0
		for i in 1:NSAMPS
			count+=randomsample(var)
		end
		count/NSAMPS
	end
	function intervene(wanted,change,val)
		function d(x;calculated=Dict())
			return wanted(x,calculated=Dict([(change("id"),val)]))
		d
		end
	end
end
