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
    # Removed specific PathDecomposition import as functions are now top-level exports
    using CSV, DataFrames, Plots, Parquet2, Plots, Graphs, GraphRecipes, SimpleWeightedGraphs, Images, FileIO
	using TacMetrics
	
    # Removed explicit PathDecomposition: PathDecomposition import.
    # Functions are now imported directly from TacMetrics.
    # e.g., TacMetrics.PathDecomposition.select_single_player is now select_single_player
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
# Uses the exported `transform_wide` function, which is now a top-level export
wide_df = transform_wide(transformed_df,:tick)

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
    	title = "Player $(player_num) Trajectory Colored 
by Tick", 
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

# ╔═╡ 170da4f9-26bd-4eb8-99d3-8dc3cce4ead2
# Uses the exported `select_single_player` function
all_player_df = select_single_player(sampled_df, player_num)

# ╔═╡ 079a0c3a-f387-446f-bc00-c154b237db4b
begin
	x_prev = vcat(missing, all_player_df[1:end-1,end-1])
	y_prev = vcat(missing, all_player_df[1:end-1,end])

	moved = (all_player_df[:,end-1] .!= x_prev) .|
        (all_player_df[:,end] .!= y_prev)
	
	moved = coalesce.(moved, false)
	first_move_idx = findfirst(moved)

	last_move_idx = length(moved) - findfirst(reverse(moved)) + 1
	last_move_idx = max(1, last_move_idx) 


	player_df = all_player_df[first_move_idx-1:last_move_idx, :]

end

# ╔═╡ 706da211-86f7-4605-a8d0-5fae73f25906
n = nrow(player_df)

# ╔═╡ 2c301874-08a2-4c83-b503-eab753f7e7cb
begin
    t_max_tick = 50
    d_max = 30.0     # Changed from 20 to 20.0
    alpha = 1 # Changed from 10 to 10.0
	beta = 1
end

# ╔═╡ f3bce198-f52f-4e08-9a43-e71cb85fea35
# Extracts coordinates to local variables for visualization cells
begin
    # x = column -2, y = column -1
    x = Float64.(player_df[!, end-1])
    y = Float64.(player_df[!, end])

end

# ╔═╡ 6c6592f4-ecca-415c-983c-0e66f3209e80
# REPLACED graph construction with a single call to the exported function
begin
    # Call the encapsulated function and capture the graph (g) and the path (path)
    g,path = decompose_path(
        player_df, 
        t_max_tick=t_max_tick, 
        d_max=d_max, 
        alpha=alpha, 
        beta=beta
    )
    path # Pluto display output for 	the graph object
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

    # Note: 'g' is the variable returned by the new find_optimal_path call
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
coords = collect(zip(path_x,path_y))

# ╔═╡ 46fa1f03-cdb0-4cb9-a8b2-c59cc9b96889
begin
	distances = []
	for idx in 2:size(coords,1)
		x_prev,y_prev = coords[idx-1]
		x,y = coords[idx]
		push!(distances,hypot(x-x_prev,y-y_prev))
	end
	distances
end

# ╔═╡ 4942826a-0466-4d07-bbb8-123a9d3b091d
begin
	using Statistics
	plot(1:length(distances), distances, 
	     xlabel="Segment Index", 
	     ylabel="Distance", 
	     title="Segment Distances",
			grid=true,)
	mean_distance = mean(distances)
	hline!([mean_distance], 
       line=(:dash, 2, :red),
       label="Mean Distance ($(round(mean_distance, digits=2)))")
end

# ╔═╡ 46b55875-1d6c-4c7e-a56c-3c290b90d203
distances

# ╔═╡ 865d979d-8c5f-4658-82d7-c2575ab02c4e
function process_distances(distances,max_fault = 2,mean_multiplier=1)
    n = length(distances)
    n == 0 && return UnitRange{Int}[]

    mean_distance = mean(distances)*mean_multiplier
    segments = UnitRange{Int}[]

    in_segment = false
    start_idx = 0
    fault = 0

    for i in 1:n
        if distances[i] < mean_distance
            if !in_segment
                start_idx = i
                in_segment = true
            end
            fault = 0
        else
            if in_segment
                fault += 1
                if fault > max_fault
                    end_idx = i - fault
                    if end_idx >= start_idx + max_fault
                        push!(segments, start_idx:end_idx)
                    end
                    in_segment = false
                    fault = 0
                end
            end
        end
    end

    if in_segment
        end_idx = n - fault
        if end_idx >= start_idx+max_fault
            push!(segments, start_idx:end_idx)
        end
    end

    return segments
end


# ╔═╡ bb9704e7-c2b7-4ac7-a5a0-501b7e79e906
distances

# ╔═╡ 66809b7e-4dc9-4591-a952-f4d1f91aaaee
segments = process_distances(distances,2)

# ╔═╡ f003052e-f148-4ff2-b20a-9b9f5c9c71ea
for segment in segments
	println(segment, " ",distances[segment])
end

# ╔═╡ a49ca75f-0a05-4d9f-8e3c-270d504b544b
for segment in segments
	println(segment, " ",path[segment])
end

# ╔═╡ 8b7bba1b-91ea-40b5-a42f-40249b3586af
begin
    new_path = Int[]
    segment_idx = 1
    n_segment = length(segments)

    in_segment = false
    idx = 1
    while idx <= length(path)

        if (segment_idx <= n_segment) && idx == segments[segment_idx].start
            if isempty(new_path) || last(new_path) != path[idx]
                push!(new_path, path[idx])
            end
            in_segment = true
            idx += 1
            continue
        end

        if (segment_idx <= n_segment) && idx == segments[segment_idx].stop
            in_segment = false
            if segments[segment_idx].stop + 1 <= length(path)
                if last(new_path) != path[segments[segment_idx].stop + 1]
                    push!(new_path, path[segments[segment_idx].stop + 1])
                end
            end
            segment_idx += 1
            idx += 2
            continue
        end

        if !in_segment
            if isempty(new_path) || last(new_path) != path[idx]
                push!(new_path, path[idx])
            end
        end

        idx += 1
    end

    new_path
end


# ╔═╡ 14393a9a-5e83-439b-a2ac-5927c105f0e5
begin
    # Recalculate coordinates for the new path
	new_path_x = x[new_path]
	new_path_y = y[new_path]

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
# ╠═865d979d-8c5f-4658-82d7-c2575ab02c4e
# ╠═bb9704e7-c2b7-4ac7-a5a0-501b7e79e906
# ╠═66809b7e-4dc9-4591-a952-f4d1f91aaaee
# ╠═f003052e-f148-4ff2-b20a-9b9f5c9c71ea
# ╠═a49ca75f-0a05-4d9f-8e3c-270d504b544b
# ╠═8b7bba1b-91ea-40b5-a42f-40249b3586af
# ╠═14393a9a-5e83-439b-a2ac-5927c105f0e5
