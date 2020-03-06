module CausalModels
using Distributions
using Statistics
export ExogenousVariable, EndogenousVariable, intervene, randomsample, prob,cond,randsample
	#represent as function with id
	function ExogenousVariable(name,dist)
		id=rand(1)[1]+1
		function d(x;calculated=Dict())
			if x=="id"
				return id
			elseif x=="cond"
				return false
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
		id=rand(1)[1]
		function d(x;calculated=Dict())
			y=x
			if x=="calculated"
				x=(aqwreqwe=true,)
			elseif x=="cond"
				return false
			elseif x=="id"
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
			value=func(vals...)
			push!(calculated,id=>value)
			if y=="calculated"
				return (value,calculated)
			end
			value
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
			if var("cond")
				count+=randsample(var)
			else
				count+=randomsample(var)
			end
		end
		count/NSAMPS
	end
	function cond(var1,var2)
		function d(x)
			if x=="cond"
				return true
			else
				return (var1,var2)
			end
		end
	end
	function randsample(counterfactual)
		cf=counterfactual("aqwreqwe")
		MAX_TRIES=100
		n=0
		a=(0,0)
		while a[1]==0 && n<MAX_TRIES
			a=cf[2]("calculated")
			n+=1
		end
		if n==MAX_TRIES
			println(4)
		end
		newdict=Dict()
		for id in keys(a[2])
			if id>1
				push!(newdict,id=>get(a[2],id,0))
			end
		end
		cf[1]((aqwreqwe=true,),calculated=newdict)
	end
	function intervene(wanted,change,val)
		function d(x;calculated=Dict())
			push!(calculated,change("id")=>val)
			return wanted(x,calculated=calculated)
		d
		end
	end
end
