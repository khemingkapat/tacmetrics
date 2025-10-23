### A Pluto.jl notebook ###
# v0.20.19

using Markdown
using InteractiveUtils

# ╔═╡ 0c3555e8-b38b-4278-bef0-03b77d2c3703
begin
    import Pkg
    Pkg.activate(Base.current_project())
    Pkg.instantiate()
    
    # Load Revise FIRST
    using Revise
    
    # Now load your packages - changes will auto-update!
    using CSV, DataFrames, Plots, Parquet2, TacMetrics, Plots
end

# ╔═╡ 8801b0fe-af4d-11f0-170b-972b2cf4deaa
md"""
# Read Data
"""

# ╔═╡ d998d25c-658c-4b8c-9c7e-418fe5bf2f5e
df = Parquet2.readfile("../demos/vitality-vs-the-mongolz-m2-dust2/ticks.parquet") |> DataFrame

# ╔═╡ dc4d9def-d9c8-49d2-9780-7c52075a8578
md"# Round and Side Selection"

# ╔═╡ 17a61ab7-113d-4e4f-ac82-d4974141190d
selected_round = 3

# ╔═╡ 01c0dddd-cbf2-4dc3-afab-5718e603d434
selected_side = "ct"

# ╔═╡ 92cba50f-0b54-44bd-9809-739e8d1b958d
selected_df = filter(row -> row.round_num == selected_round && row.side == selected_side, df, view=false)

# ╔═╡ 9c7a6fca-e151-4583-a9da-89556a254e84
md"# Transform DataFrames"

# ╔═╡ 3890ab65-d19c-4178-b26f-854ac84defda
wide_df = wide_transform(selected_df,:tick)

# ╔═╡ 26cfda01-43cb-4a70-a73b-5fc434915ffb
md"
# Sample DataFrame
"

# ╔═╡ c48bd488-f7ba-46f2-935c-2075b2b54b64
sampling_rate = 0.2

# ╔═╡ 59d714ae-93e8-4404-b709-b20e09f2be6a
step_size = round(Int,1/sampling_rate)

# ╔═╡ a956dd82-6958-474a-932b-08ab157af5b9
sampled_df = wide_df[1:step_size:end,:]

# ╔═╡ 9cb4e3c8-7113-43d7-87a3-c7187d068e8c
md"
# Visualize
"

# ╔═╡ b5ff756a-325c-41ef-a115-e652cc57ac26
player_num = 1

# ╔═╡ ed10fe60-02b3-45d6-9fa3-470577401cab
begin
	x_col_name = Symbol("p$(player_num)x")
    y_col_name = Symbol("p$(player_num)y")
	
	x_data = sampled_df[!,x_col_name]
	y_data = sampled_df[!,y_col_name]
	color_data = sampled_df.tick # Use 'tick' for coloring

# 2. Create the scatter plot with color mapping
	plot(
    	x_data, 
    	y_data,
    	seriestype = :scatter,
    	marker_z = color_data,
    	colormap = :viridis,
		colorbar = true,          # Ensures the color bar is displayed
    	xlabel = "P1 X-Coordinate", 
    	ylabel = "P1 Y-Coordinate", 
    	title = "Player 1 Trajectory Colored by Tick", 
    	legend = false, 
    	colorbar_title = "Game Tick",
	)
end

# ╔═╡ Cell order:
# ╠═0c3555e8-b38b-4278-bef0-03b77d2c3703
# ╟─8801b0fe-af4d-11f0-170b-972b2cf4deaa
# ╠═d998d25c-658c-4b8c-9c7e-418fe5bf2f5e
# ╟─dc4d9def-d9c8-49d2-9780-7c52075a8578
# ╠═17a61ab7-113d-4e4f-ac82-d4974141190d
# ╠═01c0dddd-cbf2-4dc3-afab-5718e603d434
# ╠═92cba50f-0b54-44bd-9809-739e8d1b958d
# ╟─9c7a6fca-e151-4583-a9da-89556a254e84
# ╠═3890ab65-d19c-4178-b26f-854ac84defda
# ╟─26cfda01-43cb-4a70-a73b-5fc434915ffb
# ╠═c48bd488-f7ba-46f2-935c-2075b2b54b64
# ╠═59d714ae-93e8-4404-b709-b20e09f2be6a
# ╠═a956dd82-6958-474a-932b-08ab157af5b9
# ╟─9cb4e3c8-7113-43d7-87a3-c7187d068e8c
# ╠═b5ff756a-325c-41ef-a115-e652cc57ac26
# ╠═ed10fe60-02b3-45d6-9fa3-470577401cab
