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

# ╔═╡ 0fcc12e8-0e8d-45e7-b22f-025e905536da
using Clustering

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
    t_max_tick = 30
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
r2 = TacMetrics.calculate_path_r2(player_df,new_path)

# ╔═╡ d42e3d06-7bc4-472d-a66f-08af52913db7
start_pos,end_pos = collect.(eachrow(player_df[[1,end],[end-1,end]]))

# ╔═╡ 65b27d20-e6be-4fb3-8429-b30b8b1d59cc
displacement_vec = end_pos-start_pos

# ╔═╡ 90d9e734-5b8b-4f96-ac82-43f216914950
total_displacement_direct = sqrt(dot(displacement_vec,displacement_vec))

# ╔═╡ 6bfeacfe-e0f5-434e-8041-6ea7e4b810a0
filtered_player_df

# ╔═╡ d7a735b3-727e-4b65-9517-1283c82bf6b7
begin
	dx = diff(filtered_player_df[:,end-1])
	dy = diff(filtered_player_df[:,end])
end

# ╔═╡ 3d817104-aa2a-42f7-800d-d6c9c3fc66a6
total_displacement_path = sum(hypot.(dx,dy))

# ╔═╡ c5c756a5-25c3-43e4-a127-eb7ccc6c11e4
path_efficiency = total_displacement_direct/total_displacement_path
# this is very bad approach. if I want to really do this I really have to find the way to find the shortest path with map consideration so maybe transform the map in to kind of maze and make the algorithm work

# taking note that to explore the nav mesh

# ╔═╡ ab568eaa-9287-489b-8fb7-e0624325d02d
md"
# Dynamic Grouping
"

# ╔═╡ a1d1b2b4-7c1a-4b1c-bb6a-7e2df0e3b98a
sampled_df

# ╔═╡ 4580754e-007b-4c24-a703-82c1c37ec91c
trimmed_df = TacMetrics.trim_trajectory(sampled_df)

# ╔═╡ 0b2dfd31-0e1c-4c89-8a99-9b3a4d6d9190
cluster_df = filter(:tick => t -> t in trimmed_df.tick,transformed_df)

# ╔═╡ 92797969-e9f5-45f6-90f0-7fcd1946af3a
resampled_df = filter(:tick => t -> t in unique(cluster_df.tick)[1:50:end],cluster_df)

# ╔═╡ 72280500-981a-477a-9fc1-e9a71206f7d7
scatter(resampled_df.X, resampled_df.Y, 
    group = resampled_df.tick,      # This colors the dots by player
    xlabel = "X Coordinate", 
    ylabel = "Y Coordinate",
    title = "Player Positions",
    markersize = 4,
    alpha = 0.6,             # Makes overlapping points easier to see
    legend = :outertopright)

# ╔═╡ d9e2f756-8818-49ea-948e-92bada830257
using_tick = unique(resampled_df[:,:tick])[1]

# ╔═╡ 8072e2fe-dc85-468e-9aa9-ea7dfd98a13c
tick_df = filter(:tick => t -> t == using_tick,resampled_df)

# ╔═╡ 64bba327-4df4-4846-8b02-978988adc309
data_matrix = Matrix(tick_df[:,[:X,:Y]])

# ╔═╡ e1d9ee9c-2333-4f2b-a3d5-2186d5fbcefd
dist_mat = pairwise(Euclidean(), data_matrix, dims=1)

# ╔═╡ 54eed427-438a-406b-8dfc-b46b40a4aa08
h_result = hclust(dist_mat, linkage=:complete)

# ╔═╡ 7c365c7e-e5fe-45fa-bd9b-f58baa70e485
scatter(tick_df.X,tick_df.Y)

# ╔═╡ f9941c40-a945-4d40-a15b-5e9ac3c385c7
cutree(h_result, h = 50)

# ╔═╡ c4fae455-a6ee-4529-bd13-5f9c8b46f0ac
copy(resampled_df)

# ╔═╡ 4ca03643-71b1-4e03-82c7-96b747b1ed73
using_tick

# ╔═╡ a3b6e5b3-078d-47ef-893c-b7d953cd6472
indices = findall(resampled_df.tick .== using_tick)

# ╔═╡ 74332993-cd2e-44b0-bab1-5824ba730a1b
function cluster_players(df, height=50)
    result_df = copy(df)
    result_df.cluster = zeros(Int, nrow(df)) 
    
    for tick_df in groupby(result_df, :tick)
        if nrow(tick_df) > 1
            data_matrix = Matrix(tick_df[:, [:X, :Y]])
            dist_mat = pairwise(Euclidean(), data_matrix, dims=1)
            h_result = hclust(dist_mat, linkage=:complete)
            
            tick_df.cluster .= cutree(h_result, h = height)
        else
            tick_df.cluster .= 1
        end
    end
    return result_df
end

# ╔═╡ 668469d3-a55f-40f0-b54b-c2af31b8fdb1
clustered_df = cluster_players(resampled_df)			

# ╔═╡ c2b4b129-3065-4e8e-b0b5-06303f026d3f
function calculate_cluster_features(df)
    cluster_features = combine(groupby(df, [:cluster])) do group_df
        (
            centroid_x = mean(group_df.X),
            centroid_y = mean(group_df.Y),
            size = nrow(group_df),
            player_set = Set(group_df.steamid),
			player_name_set = Set(group_df.name)
        )
    end
    return cluster_features
end

# ╔═╡ e93bb742-86f8-416d-b8b1-c1b6bcda8907
function jaccard_similarity(set1::Set, set2::Set)
    intersection = length(intersect(set1, set2))
    union_size = length(union(set1, set2))
    return union_size > 0 ? intersection / union_size : 0.0
end

# ╔═╡ bb346e49-7c86-4a50-af43-830c7c2e173b
function construct_cost_matrix(
    curr_clusters::DataFrame, 
    next_clusters::DataFrame;
)
    n_curr = nrow(curr_clusters)
    n_next = nrow(next_clusters)
    
    # Initialize cost matrix
    cost_matrix = zeros(Float64, n_curr, n_next)
    
    # Calculate cost for each pair
    for i in 1:n_curr
        for j in 1:n_next
            # Player overlap similarity
            player_sim = jaccard_similarity(
                curr_clusters[i, :player_set],
                next_clusters[j, :player_set]
            )

            cost_matrix[i, j] = player_sim
				
        end
    end
    
    return cost_matrix
end



# ╔═╡ 657f30b7-d086-4422-8b74-31db49681870
function get_node_id(node_map::Dict, tick::Int, cluster::Int)
    if !haskey(node_map, (tick, cluster))
        next_id = length(node_map) + 1
        node_map[(tick, cluster)] = next_id
        return next_id
    end
    return node_map[(tick, cluster)]
end

# ╔═╡ 330bde73-ff87-49ee-b8e9-cbe54832cfbb
begin
    # Initialize graph and node mapping
    cluster_graph = SimpleWeightedDiGraph(0)
    node_map = Dict{Tuple{Int, Int}, Int}()
	next_id = 1
    # Get unique ticks
    ticks = unique(clustered_df.tick)
    n_tick = length(ticks)
    
    for idx in 1:n_tick-1
        # println("At idx = $(idx)")
        
        # Filter data for current and next tick
        curr_df = filter(:tick => t -> t == ticks[idx], clustered_df)
        next_df = filter(:tick => t -> t == ticks[idx+1], clustered_df)
        
        # Calculate cluster features
        curr_clusters = calculate_cluster_features(curr_df)
        next_clusters = calculate_cluster_features(next_df)
        
        # Construct cost matrix
        cost_matrix = construct_cost_matrix(
            curr_clusters,
            next_clusters,
        )

		# display(cost_matrix)
        # Hungarian algorithm
        assignments_zip = Tuple.(findall(!iszero, cost_matrix))
        
        for pos in assignments_zip
            from = pos[1]
            to = pos[2]
            weight = cost_matrix[from,to]
            # Convert Tuples to Unique Integers
            u = get_node_id(node_map, idx, from)      # Node at current tick
            v = get_node_id(node_map, idx + 1, to)    # Node at next tick
            
            # Add vertices if needed
            while nv(cluster_graph) < max(u, v)
                add_vertex!(cluster_graph)
            end
            
            # Add edge with weight
            add_edge!(cluster_graph, u, v, weight)
        end
    end
end

# ╔═╡ b5f97be8-28e5-46c4-9455-ac7ea2bb94c2
cluster_graph

# ╔═╡ 73a75965-12d2-4373-b790-dd8c8bad0a0d
id_to_node = Dict(value => key for (key, value) in node_map)

# ╔═╡ 5e3a45a7-2c7b-4691-b6ca-cc9e50df7dd8
begin
	x_coords = zeros(nv(cluster_graph))
	y_coords = zeros(nv(cluster_graph))
	
	for i in 1:nv(cluster_graph)
	    # Get (tick_index, cluster_index) from your inverted dictionary
	    tick, cluster_num = id_to_node[i]
	    
	    # x is the actual tick value from your ticks array
	    x_coords[i] = tick
	    
	    # y is the cluster number
	    y_coords[i] = cluster_num
	end
	
	# 2. Plot the graph using the coordinates
	graphplot(cluster_graph, 
	          x = x_coords*2, 
	          y = y_coords*5, 
	          nodesize = 2,
	          linealpha = 1,          # Makes lines slightly transparent
	          curves = false,           # Straight lines look better for timelines
	          xlabel = "Tick",
	          ylabel = "Cluster Number",
	          title = "Cluster Transitions Over Time")
	
end

# ╔═╡ aeacfac5-a92c-409e-95db-f706eb4caf7b
clustered_grouped_df = combine(groupby(clustered_df, :tick), 
    group_df -> calculate_cluster_features(group_df))

# ╔═╡ 39f32d64-0fe4-42c2-a36f-b04de840aaff
describe(clustered_grouped_df)

# ╔═╡ f1c52c9f-1e19-42e9-979d-5bfd9092c0bb
nv(cluster_graph) == length(clustered_grouped_df.centroid_x) == length(clustered_grouped_df.centroid_y)

# ╔═╡ dafe943a-3ea5-4611-ba31-cb4abb2bf2c4
# Define shapes for sizes 1 through 5
marker_shape_dict = Dict(
    1 => :circle,
    2 => :square,
    3 => :diamond,
    4 => :utriangle,
    5 => :pentagon
)

# ╔═╡ ed7af2cf-16a8-4bfa-9156-eb007cf801b8
begin
	img = load("../.awpy/maps/$(selected_map).png")
    img_height, img_width = size(img)

	x_coord = collect(clustered_grouped_df.centroid_x)
    y_coord = img_height .- collect(clustered_grouped_df.centroid_y)
	markersize=5 .+ collect(clustered_grouped_df.size)
	shapes_array = get.(Ref(marker_shape_dict), collect(clustered_grouped_df.size), :circle)
    
    bgc = plot(img,
               yflip=true,                  
               aspect_ratio=:equal,
               legend=false,
               size=(1000,1000),
               xlims=(1, img_width),
               ylims=(1, img_height),
               axis=false,
               ticks=false)
    for edge in edges(cluster_graph)
        src_idx = src(edge)
        dst_idx = dst(edge)
        plot!(bgc,
              [x_coord[src_idx], x_coord[dst_idx]], 
              [y_coord[src_idx], y_coord[dst_idx]], 
              color=:red, 
              alpha=0.6, 
              linewidth=1.5,
              label="")
    end
    
    # Draw nodes on top
    c_scatter_plot = scatter(bgc,
             x_coord, 
             y_coord, 
             markersize=markersize, 
			markershape=shapes_array,
             markercolor=:red,
             markerstrokewidth=0,
             label="",
             title="Cluster Transitions Over Time")
    
	c_scatter_plot
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
# ╠═bb9704e7-c2b7-4ac7-a5a0-501b7e79e906
# ╠═66809b7e-4dc9-4591-a952-f4d1f91aaaee
# ╠═f003052e-f148-4ff2-b20a-9b9f5c9c71ea
# ╠═a49ca75f-0a05-4d9f-8e3c-270d504b544b
# ╠═d0c6e073-246e-41a3-b13a-0c8bbf0f1178
# ╠═14393a9a-5e83-439b-a2ac-5927c105f0e5
# ╠═b5acfea7-0ad5-4d9a-b3df-c1b30965c323
# ╠═f18376cc-1e05-4ef4-a435-b20e67d6dfd9
# ╠═e6ddee0a-2ba3-4aa0-bcb9-4a5ee2f3b132
# ╠═d42e3d06-7bc4-472d-a66f-08af52913db7
# ╠═65b27d20-e6be-4fb3-8429-b30b8b1d59cc
# ╠═90d9e734-5b8b-4f96-ac82-43f216914950
# ╠═6bfeacfe-e0f5-434e-8041-6ea7e4b810a0
# ╠═d7a735b3-727e-4b65-9517-1283c82bf6b7
# ╠═3d817104-aa2a-42f7-800d-d6c9c3fc66a6
# ╠═c5c756a5-25c3-43e4-a127-eb7ccc6c11e4
# ╟─ab568eaa-9287-489b-8fb7-e0624325d02d
# ╠═a1d1b2b4-7c1a-4b1c-bb6a-7e2df0e3b98a
# ╠═4580754e-007b-4c24-a703-82c1c37ec91c
# ╠═0b2dfd31-0e1c-4c89-8a99-9b3a4d6d9190
# ╠═92797969-e9f5-45f6-90f0-7fcd1946af3a
# ╠═72280500-981a-477a-9fc1-e9a71206f7d7
# ╠═0fcc12e8-0e8d-45e7-b22f-025e905536da
# ╠═d9e2f756-8818-49ea-948e-92bada830257
# ╠═8072e2fe-dc85-468e-9aa9-ea7dfd98a13c
# ╠═64bba327-4df4-4846-8b02-978988adc309
# ╠═e1d9ee9c-2333-4f2b-a3d5-2186d5fbcefd
# ╠═54eed427-438a-406b-8dfc-b46b40a4aa08
# ╠═7c365c7e-e5fe-45fa-bd9b-f58baa70e485
# ╠═f9941c40-a945-4d40-a15b-5e9ac3c385c7
# ╠═c4fae455-a6ee-4529-bd13-5f9c8b46f0ac
# ╠═4ca03643-71b1-4e03-82c7-96b747b1ed73
# ╠═a3b6e5b3-078d-47ef-893c-b7d953cd6472
# ╠═74332993-cd2e-44b0-bab1-5824ba730a1b
# ╠═668469d3-a55f-40f0-b54b-c2af31b8fdb1
# ╠═c2b4b129-3065-4e8e-b0b5-06303f026d3f
# ╠═e93bb742-86f8-416d-b8b1-c1b6bcda8907
# ╠═bb346e49-7c86-4a50-af43-830c7c2e173b
# ╠═657f30b7-d086-4422-8b74-31db49681870
# ╠═330bde73-ff87-49ee-b8e9-cbe54832cfbb
# ╠═b5f97be8-28e5-46c4-9455-ac7ea2bb94c2
# ╠═73a75965-12d2-4373-b790-dd8c8bad0a0d
# ╠═5e3a45a7-2c7b-4691-b6ca-cc9e50df7dd8
# ╠═aeacfac5-a92c-409e-95db-f706eb4caf7b
# ╠═39f32d64-0fe4-42c2-a36f-b04de840aaff
# ╠═f1c52c9f-1e19-42e9-979d-5bfd9092c0bb
# ╠═dafe943a-3ea5-4611-ba31-cb4abb2bf2c4
# ╠═ed7af2cf-16a8-4bfa-9156-eb007cf801b8
