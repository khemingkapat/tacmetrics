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
    
    using CSV, DataFrames, Plots, Parquet2, Plots, Graphs, GraphRecipes, SimpleWeightedGraphs, Images, FileIO,LinearAlgebra,Statistics
	
	using TacMetrics
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
# Uses the exported `transform_wide` function from TacMetrics
wide_df = TacMetrics.transform_wide(transformed_df,:tick)

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
player_num = 4

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
# Decompose & Compress Path
"

# ╔═╡ a7fe237b-6212-4e1f-9da2-0241eb69c294
sampled_df

# ╔═╡ 170da4f9-26bd-4eb8-99d3-8dc3cce4ead2
# STEP 1: Select single player data (using exported package function)
all_player_df = TacMetrics.select_single_player(sampled_df, player_num)

# ╔═╡ 079a0c3a-f387-446f-bc00-c154b237db4b
# STEP 2: Trim stationary periods (using exported package function)
player_df = TacMetrics.trim_trajectory(all_player_df)

# ╔═╡ 706da211-86f7-4605-a8d0-5fae73f25906
n = nrow(player_df)

# ╔═╡ 2c301874-08a2-4c83-b503-eab753f7e7cb
begin
    t_max_tick = 50
    d_max = 30.0     
    alpha = 1 # Weight for distance
	beta = 1 # Weight for time
end

# ╔═╡ f3bce198-f52f-4e08-9a43-e71cb85fea35
# Extracts coordinates to local variables for visualization cells
begin
    # x = column -2, y = column -1
    x = Float64.(player_df[!, end-1])
    y = Float64.(player_df[!, end])
end

# ╔═╡ 6c6592f4-ecca-415c-983c-0e66f3209e80
# STEP 3: Decompose path (using exported package function)
begin
    # Call the exported function and capture the graph (g) and the path (path)
    g, path = TacMetrics.decompose_path(
        player_df, 
        t_max_tick=t_max_tick, 
        d_max=d_max, 
        alpha=alpha, 
        beta=beta
    )
    path # Pluto display output for the path vector
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

    # Note: 'g' is the variable returned by the new decompose_path call
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

# ╔═╡ 68084c51-12d1-488d-86ca-9a34518dd425
# Coordinates of the optimal path
coords = collect(zip(path_x,path_y))

# ╔═╡ 46fa1f03-cdb0-4cb9-a8b2-c59cc9b96889
# STEP 4: Calculate segment distances (using exported package function)
distances = TacMetrics.calculate_segment_distances(path, player_df)

# ╔═╡ 46b55875-1d6c-4c7e-a56c-3c290b90d203
distances

# ╔═╡ 4942826a-0466-4d07-bbb8-123a9d3b091d
begin
	plot(1:length(distances), distances, 
	     xlabel="Segment Index", 
	     ylabel="Distance", 
	     title="Segment Distances",
			grid=true,)
	mean_distance = Statistics.mean(distances)
	hline!([mean_distance], 
       line=(:dash, 2, :red),
       label="Mean Distance ($(round(mean_distance, digits=2)))")
end

# ╔═╡ bb9704e7-c2b7-4ac7-a5a0-501b7e79e906
distances

# ╔═╡ 66809b7e-4dc9-4591-a952-f4d1f91aaaee
# STEP 5: Identify low-movement segments (using exported package function)
segments = TacMetrics.process_distances(distances, 2, 1)

# ╔═╡ f003052e-f148-4ff2-b20a-9b9f5c9c71ea
for segment in segments
	println(segment, " ",distances[segment])
end

# ╔═╡ a49ca75f-0a05-4d9f-8e3c-270d504b544b
for segment in segments
	println(segment, " ",path[segment])
end

# ╔═╡ d0c6e073-246e-41a3-b13a-0c8bbf0f1178
# STEP 6: Compress the path (using exported package function)
filtered_player_df,new_path = TacMetrics.process_path(path, segments, player_df)

# ╔═╡ 14393a9a-5e83-439b-a2ac-5927c105f0e5
begin
    # Recalculate coordinates for the new path
	new_path_x = filtered_player_df[:,end-1]
	new_path_y = filtered_player_df[:,end]

	bgp_compressed = plot(load("../.awpy/maps/$(selected_map).png"),
           yflip=true,          
           aspect_ratio=:equal,
           legend=false,
			size=(1000,1000),
			title = "Compressed Path"
		)
	xlims!(bgp_compressed, 0, img_dim)
	ylims!(bgp_compressed, 0, img_dim)
	scatter!(
		bgp_compressed,
        x, img_dim.-y,
        markersize = 3,
		markercolor="lightblue",
        aspect_ratio = :equal,
        legend = false,
    )
    
	plot!(
    	bgp_compressed, 
    	new_path_x, 
    	img_dim.-new_path_y, 
    	line = (:red, 3, :solid), # Thicker red line for the new path
    	label = "Compressed Path"
	)
end

# ╔═╡ b5acfea7-0ad5-4d9a-b3df-c1b30965c323
# STEP 7: Build compressed graph (using exported package function)
g_compressed = TacMetrics.build_compressed_graph(filtered_player_df)

# ╔═╡ f18376cc-1e05-4ef4-a435-b20e67d6dfd9
plot(1:nrow(filtered_player_df),filtered_player_df.tick)

# ╔═╡ e6ddee0a-2ba3-4aa0-bcb9-4a5ee2f3b132
TacMetrics.calculate_path_r2(player_df,new_path)

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
# ╠═170da4f9-26bd-4eb8-99d3-8dc3cce4ead2
# ╠═079a0c3a-f387-446f-bc00-c154b237db4b
# ╠═706da211-86f7-4605-a8d0-5fae73f25906
# ╠═2c301874-08a2-4c83-b503-eab753f7e7cb
# ╠═f3bce198-f52f-4e08-9a43-e71cb85fea35
# ╠═6c6592f4-ecca-415c-983c-0e66f3209e80
# ╠═8367e60c-44e2-4c48-bf3f-584641ca00ab
# ╠═ebdf6c80-063e-44f6-9dae-36bcff05dd4d
# ╠═ab6ed8ab-b70b-4535-abe0-82e6ddc628f7
# ╠═9145376d-ff52-4142-aedd-4e2bc81e832f
# ╠═c8a7079b-c1fb-4433-a19f-ec909f6b38ee
# ╠═68084c51-12d1-488d-86ca-9a34518dd425
# ╠═46fa1f03-cdb0-4cb9-a8b2-c59cc9b96889
# ╠═46b55875-1d6c-4c7e-a56c-3c290b90d203
# ╠═4942826a-0466-4d07-bbb8-123a9d3b091d
# ╠═bb9704e7-c2b7-4ac7-a5a0-501b7e79e906
# ╠═66809b7e-4dc9-4591-a952-f4d1f91aaaee
# ╠═f003052e-f148-4ff2-b20a-9b9f5c9c71ea
# ╠═a49ca75f-0a05-4d9f-8e3c-270d504b544b
# ╠═d0c6e073-246e-41a3-b13a-0c8bbf0f1178
# ╠═14393a9a-5e83-439b-a2ac-5927c105f0e5
# ╠═b5acfea7-0ad5-4d9a-b3df-c1b30965c323
# ╠═f18376cc-1e05-4ef4-a435-b20e67d6dfd9
# ╠═e6ddee0a-2ba3-4aa0-bcb9-4a5ee2f3b132
