using Clustering, DataFrames, LinearAlgebra, Statistics, Distances, Graphs, SimpleWeightedGraphs

include("util.jl")


function cluster_players(df, height=50)
    result_df = copy(df)
    result_df.cluster = zeros(Int, nrow(df))

    for tick_df in groupby(result_df, :tick)
        if nrow(tick_df) > 1
            data_matrix = Matrix(tick_df[:, [:X, :Y]])
            dist_mat = pairwise(Euclidean(), data_matrix, dims=1)
            h_result = hclust(dist_mat, linkage=:complete)

            tick_df.cluster .= cutree(h_result, h=height)
        else
            tick_df.cluster .= 1
        end
    end
    return result_df
end

function calculate_cluster_features(df)
    cluster_features = combine(groupby(df, [:cluster])) do group_df
        (
            centroid_x=mean(group_df.X),
            centroid_y=mean(group_df.Y),
            size=nrow(group_df),
            player_set=Set(group_df.steamid),
            player_name_set=Set(group_df.name)
        )
    end
    return cluster_features
end

function jaccard_similarity(set1::Set, set2::Set)
    intersection = length(intersect(set1, set2))
    return Int(intersection)
end

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

function build_cluster_graph(clustered_df::DataFrame)
    # Initialize graph and node mapping
    cluster_graph = SimpleWeightedDiGraph(0)
    node_map = Dict{Tuple{Int,Int},Int}()

    # Get unique ticks
    ticks = unique(clustered_df.tick)
    n_tick = length(ticks)

    # Process consecutive tick pairs
    for idx in 1:n_tick-1
        # Filter data for current and next tick
        curr_df = filter(:tick => t -> t == ticks[idx], clustered_df)
        next_df = filter(:tick => t -> t == ticks[idx+1], clustered_df)

        # Calculate cluster features
        curr_clusters = calculate_cluster_features(curr_df)
        next_clusters = calculate_cluster_features(next_df)

        # Construct cost matrix
        cost_matrix = construct_cost_matrix(curr_clusters, next_clusters)


        # Find assignments using cost matrix
        assignments_zip = Tuple.(findall(!iszero, cost_matrix))

        # Add edges for each assignment
        for (from, to) in assignments_zip
            weight = cost_matrix[from, to]

            # Convert cluster positions to unique node IDs
            u = get_node_id(node_map, idx, from)
            v = get_node_id(node_map, idx + 1, to)

            # Ensure graph has enough vertices
            while nv(cluster_graph) < max(u, v)
                add_vertex!(cluster_graph)
            end

            # Add weighted edge
            add_edge!(cluster_graph, u, v, weight)
        end
    end

    return cluster_graph, node_map
end
