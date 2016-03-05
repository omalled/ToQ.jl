using ToQ

model = ToQ.Model("modelname", "laptop", "c4-sw_sample", "workingdir")

@defparam model color
@defparam model neighbor

provinces = ["BC", "YK", "NW", "AB", "SK", "NV", "MT", "ON", "QB", "NB", "NS", "PE", "NL"]
#province2index = Dict(zip(provinces, 1:length(provinces)))
neighbors = Dict()
neighbors["BC"] = ["YK", "NW", "AB"]
neighbors["YK"] = ["BC", "NW"]
neighbors["NW"] = ["YK", "BC", "AB", "SK", "NV"]
neighbors["AB"] = ["BC", "YK", "NW", "SK"]
neighbors["SK"] = ["AB", "NW", "MT"]
neighbors["NV"] = ["NW", "MT"]
neighbors["MT"] = ["NV", "SK", "ON"]
neighbors["ON"] = ["MT", "QB"]
neighbors["QB"] = ["ON", "NB", "NL"]
neighbors["NB"] = ["QB", "NS"]
neighbors["NS"] = ["NB"]
neighbors["PE"] = []
neighbors["NL"] = ["QB"]

q = macroexpand(:(@defvar model province_rgb[1:length(provinces), 1:3]))
@show q
@defvar model province_rgb[1:length(provinces), 1:3]

#add color penalties
for i = 1:length(provinces)
	for j = 1:3
		@addterm model -1 * color * province_rgb[i, j]
		for k = 1:j - 1
			@addterm model 2 * color * province_rgb[i, j] * province_rgb[i, k]
		end
	end
end

#add neighbor penalties
for j = 1:length(provinces)
	for k = 1:j - 1
		if provinces[k] in neighbors[provinces[j]]
			for i = 1:3
				@addterm model neighbor * province_rgb[j, i] * province_rgb[k, i]
			end
		end
	end
end

#solve the system
ToQ.solve!(model; color=1, neighbor=5, param_chain=2, numreads=100, doembed=true)

#load the solutions
i = 1
solutions = Array{Float64, 2}[]
energies = Float64[]
occurrences = Float64[]
while true
	try
		@loadsolution model energy occurrencesi i
		push!(solutions, copy(province_rgb.value))
		push!(energies, energy)
		push!(occurrences, occurrencesi)
	catch
		break#break once solution i no longer exists
	end
	i += 1
end

#print the solutions
validcount = 0
for i = 1:length(energies)
	isvalid = true
	for j = 1:length(provinces)
		for k = 1:j - 1
			if provinces[k] in neighbors[provinces[j]] && norm(solutions[i][j, :] - solutions[i][k, :]) == 0
				@show k, provinces[k]
				@show j, provinces[j]
				isvalid = false
			end
		end
	end
	if isvalid
		validcount += 1
	end
	println("Solution #$i (valid = $isvalid)")
	println("Energy: $(energies[i])")
	println("Occurrences: $(occurrences[i])")
	println("Solution:\n$(solutions[i])\n")
end
@show validcount / length(solutions)
