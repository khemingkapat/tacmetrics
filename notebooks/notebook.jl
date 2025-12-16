### A Pluto.jl notebook ###
# v0.20.21

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
    using CSV, DataFrames, Plots, Parquet2, Plots, Graphs, GraphRecipes, SimpleWeightedGraphs, Images, FileIO
	using TacMetrics
	using TacMetrics: PathDecomposition 
end

# ╔═╡ 8801b0fe-af4d-11f0-170b-972b2cf4deaa
md"""
# Read Data
"""

# ╔═╡ d998d25c-658c-4b8c-9c7e-418fe5bf2f5e
df = Parquet2.readfile("../demos/vitality-vs-the-mongolz-m2-dust2/ticks.parquet") |> DataFrame

# ╔═╡ dc4d9def-d9c8-49d2-9780-7c52075a8578
md"# Map, Round and Side Selection"

# ╔═╡ e17b0c1f-4ae2-45da-886e-8813918ae711
selected_map = "de_dust2"

# ╔═╡ 17a61ab7-113d-4e4f-ac82-d4974141190d
selected_round = 3

# ╔═╡ 01c0dddd-cbf2-4dc3-afab-5718e603d434
selected_side = "ct"

# ╔═╡ 92cba50f-0b54-44bd-9809-739e8d1b958d
selected_df = filter(row -> row.round_num == selected_round && row.side == selected_side, df, view=false)

# ╔═╡ f00e9a30-0938-4c17-a733-4048ff36e1c6
md"
# Transform Coordinates
"

# ╔═╡ 7f3181f8-aa57-4be4-8795-c42b0daf791d
map_data = TacMetrics.load_map_data(selected_map)

# ╔═╡ 0f0306fd-520c-41e4-bfd9-7a7c05951f83
transformed_df = TacMetrics.transform_coord(map_data,selected_df,x_col=:X,y_col=:Y)

# ╔═╡ 9c7a6fca-e151-4583-a9da-89556a254e84
md"# Transform DataFrames"

# ╔═╡ 3890ab65-d19c-4178-b26f-854ac84defda
wide_df = PathDecomposition.transform_wide(transformed_df,:tick)

# ╔═╡ 26cfda01-43cb-4a70-a73b-5fc434915ffb
md"
# Sample DataFrame
"

# ╔═╡ c48bd488-f7ba-46f2-935c-2075b2b54b64
sampling_rate = 0.05

# ╔═╡ 59d714ae-93e8-4404-b709-b20e09f2be6a
step_size = round(Int,1/sampling_rate)

# ╔═╡ a956dd82-6958-474a-932b-08ab157af5b9
sampled_df = wide_df[1:step_size:end,:]

# ╔═╡ 9cb4e3c8-7113-43d7-87a3-c7187d068e8c
md"
# Visualize
"

# ╔═╡ b5ff756a-325c-41ef-a115-e652cc57ac26
player_num = 5

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
    	title = "Player $(player_num) Trajectory Colored by Tick", 
    	legend = false, 
    	colorbar_title = "Game Tick",
	)
end

# ╔═╡ 03ea4413-41c3-4f57-bba5-37f69be69b56
md"
# Decompose
"

# ╔═╡ a7fe237b-6212-4e1f-9da2-0241eb69c294
sampled_df

# ╔═╡ 775de0d3-37b9-46aa-8379-0002eefc3c33
function select_single_player(df::DataFrame, num::Int)
    x_col_name = Symbol("p", num, "x")
    y_col_name = Symbol("p", num, "y")

    required_cols = string.([:tick, x_col_name, y_col_name])
    
    if !all(col -> col in names(df), required_cols)
        error("One or more required columns (:$x_col_name, :$y_col_name) for point $num do not exist in the input DataFrame.")
    end

    new_df = select(df, :tick, x_col_name, y_col_name)

    return new_df
end

# ╔═╡ 170da4f9-26bd-4eb8-99d3-8dc3cce4ead2
player_df = select_single_player(sampled_df,4)

# ╔═╡ 706da211-86f7-4605-a8d0-5fae73f25906
n = nrow(player_df)

# ╔═╡ 2c301874-08a2-4c83-b503-eab753f7e7cb
begin
    t_max_tick = 150
    d_max = 20      
end

# ╔═╡ f3bce198-f52f-4e08-9a43-e71cb85fea35
begin
    # x = column -2, y = column -1
    x = Float64.(player_df[!, end-1])
    y = Float64.(player_df[!, end])

end

# ╔═╡ 024600b3-2a33-4eaa-bb52-38752843b89c
dist(i::Int, j::Int) = hypot(x[i] - x[j], y[i] - y[j])

# ╔═╡ 6c6592f4-ecca-415c-983c-0e66f3209e80
begin
    g = SimpleWeightedDiGraph{Int64, Float64}(n)
	alpha = 10
	beta=0.5

    for i in 1:n
        ti = player_df.tick[i]
	
        for j in (i+1):n
            dt_tick = player_df.tick[j] - ti
            # stop once time window exceeded
            dt_tick > t_max_tick && break
			d_ij = dist(i, j)

            if d_ij ≤ d_max
				w_ij = alpha * d_ij + beta * dt_tick
                add_edge!(g, i, j, w_ij)
            end
        end
    end
    g
end


# ╔═╡ 8367e60c-44e2-4c48-bf3f-584641ca00ab
g

# ╔═╡ ebdf6c80-063e-44f6-9dae-36bcff05dd4d
begin
    p = scatter(
        x, y,
        markersize = 3,
        aspect_ratio = :equal,
        legend = false,
        title = "Directed movement graph"
    )

    for e in edges(g)
        i = src(e)
        j = dst(e)

        plot!(
            p,
            [x[i], x[j]],
            [y[i], y[j]],
            arrow = :arrow,
            linewidth = 1,
            color = :black,
            alpha = 0.3
        )
    end

    p   # ← THIS is critical
end


# ╔═╡ dd2952c1-cd15-4ab3-af61-266dc5afd0ab
distances = dijkstra_shortest_paths(g, 1)

# ╔═╡ 6fd17f4d-0adb-43de-b9fd-bb71871e9cc8
path = enumerate_paths(distances, n)

# ╔═╡ ab6ed8ab-b70b-4535-abe0-82e6ddc628f7
begin
	path_x = x[path]
	path_y = y[path]
end

# ╔═╡ 9145376d-ff52-4142-aedd-4e2bc81e832f
plot!(
    p, 
    path_x, 
    path_y, 
    line = (:red, 3, :solid), # Sets color to red, thickness to 3
    label = "Shortest Path (Cost-Optimized)"
)

# ╔═╡ c8a7079b-c1fb-4433-a19f-ec909f6b38ee
begin
	img_dim = 1024
	bgp = plot(load("../.awpy/maps/$(selected_map).png"),
           yflip=true,                  
           aspect_ratio=:equal,
           legend=false,
			size=(1000,1000)
		)
	xlims!(bgp, 0, img_dim)
	ylims!(bgp, 0, img_dim)
	scatter!(
		bgp,
        x, img_dim.-y,
        markersize = 3,
		markercolor="lightblue",
        aspect_ratio = :equal,
        legend = false,
        title = "Directed movement graph"
    )
	plot!(
    	bgp, 
    	path_x, 
    	img_dim.-path_y, 
    	line = (:red, 1, :solid), # Sets color to red, thickness to 3
    	label = "Shortest Path (Cost-Optimized)"
	)
end


# ╔═╡ Cell order:
# ╠═0c3555e8-b38b-4278-bef0-03b77d2c3703
# ╟─8801b0fe-af4d-11f0-170b-972b2cf4deaa
# ╠═d998d25c-658c-4b8c-9c7e-418fe5bf2f5e
# ╟─dc4d9def-d9c8-49d2-9780-7c52075a8578
# ╠═e17b0c1f-4ae2-45da-886e-8813918ae711
# ╠═17a61ab7-113d-4e4f-ac82-d4974141190d
# ╠═01c0dddd-cbf2-4dc3-afab-5718e603d434
# ╠═92cba50f-0b54-44bd-9809-739e8d1b958d
# ╟─f00e9a30-0938-4c17-a733-4048ff36e1c6
# ╠═7f3181f8-aa57-4be4-8795-c42b0daf791d
# ╠═0f0306fd-520c-41e4-bfd9-7a7c05951f83
# ╟─9c7a6fca-e151-4583-a9da-89556a254e84
# ╠═3890ab65-d19c-4178-b26f-854ac84defda
# ╟─26cfda01-43cb-4a70-a73b-5fc434915ffb
# ╠═c48bd488-f7ba-46f2-935c-2075b2b54b64
# ╠═59d714ae-93e8-4404-b709-b20e09f2be6a
# ╠═a956dd82-6958-474a-932b-08ab157af5b9
# ╟─9cb4e3c8-7113-43d7-87a3-c7187d068e8c
# ╠═b5ff756a-325c-41ef-a115-e652cc57ac26
# ╠═ed10fe60-02b3-45d6-9fa3-470577401cab
# ╟─03ea4413-41c3-4f57-bba5-37f69be69b56
# ╠═a7fe237b-6212-4e1f-9da2-0241eb69c294
# ╠═775de0d3-37b9-46aa-8379-0002eefc3c33
# ╠═170da4f9-26bd-4eb8-99d3-8dc3cce4ead2
# ╠═706da211-86f7-4605-a8d0-5fae73f25906
# ╠═2c301874-08a2-4c83-b503-eab753f7e7cb
# ╠═f3bce198-f52f-4e08-9a43-e71cb85fea35
# ╠═024600b3-2a33-4eaa-bb52-38752843b89c
# ╠═6c6592f4-ecca-415c-983c-0e66f3209e80
# ╠═8367e60c-44e2-4c48-bf3f-584641ca00ab
# ╠═ebdf6c80-063e-44f6-9dae-36bcff05dd4d
# ╠═dd2952c1-cd15-4ab3-af61-266dc5afd0ab
# ╠═6fd17f4d-0adb-43de-b9fd-bb71871e9cc8
# ╠═ab6ed8ab-b70b-4535-abe0-82e6ddc628f7
# ╠═9145376d-ff52-4142-aedd-4e2bc81e832f
# ╠═c8a7079b-c1fb-4433-a19f-ec909f6b38ee
