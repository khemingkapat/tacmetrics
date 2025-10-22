### A Pluto.jl notebook ###
# v0.20.19

using Markdown
using InteractiveUtils

# ╔═╡ 0c3555e8-b38b-4278-bef0-03b77d2c3703
begin
	import Pkg
	# Use Base.current_project() to find the nearest Project.toml file
	# (Your notebook must be saved inside or below your JuliaDataProject folder for this to work)
	Pkg.activate(Base.current_project()) 
	
	# This command checks your Project.toml and downloads/installs any 
	# missing packages into this environment.
	Pkg.instantiate()
	
	# Now you can use your project packages
	using CSV, DataFrames, Plots, Parquet2
end

# ╔═╡ 8801b0fe-af4d-11f0-170b-972b2cf4deaa
md"""
# Read Data
"""

# ╔═╡ d998d25c-658c-4b8c-9c7e-418fe5bf2f5e
df = Parquet2.readfile("./vitality-vs-the-mongolz-m2-dust2/ticks.parquet") |> DataFrame

# ╔═╡ 17a61ab7-113d-4e4f-ac82-d4974141190d
selected_round = 3

# ╔═╡ 92cba50f-0b54-44bd-9809-739e8d1b958d
selected_round_df = filter(:round_num => x -> x == selected_round, df)

# ╔═╡ d8af838f-aa49-4883-9937-44f8e150e288
selected_round_df[1:1000:end,:]

# ╔═╡ Cell order:
# ╠═0c3555e8-b38b-4278-bef0-03b77d2c3703
# ╠═8801b0fe-af4d-11f0-170b-972b2cf4deaa
# ╠═d998d25c-658c-4b8c-9c7e-418fe5bf2f5e
# ╠═17a61ab7-113d-4e4f-ac82-d4974141190d
# ╠═92cba50f-0b54-44bd-9809-739e8d1b958d
# ╠═d8af838f-aa49-4883-9937-44f8e150e288
