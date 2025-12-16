module PathDecomposition

using Base: decompose
using DataFrames, Graphs, SimpleWeightedGraphs

export decompose_path, select_single_player

"""
    select_single_player(df::AbstractDataFrame, num::Int; 
                         x_suffix="x", y_suffix="y") -> DataFrame

Selects the :tick and (X, Y) columns for a single player identified by `num` 
from a wide DataFrame. (Moved from notebook)
"""
function select_single_player(df::AbstractDataFrame, num::Int; x_suffix="x", y_suffix="y")
    x_col_name = Symbol("p", num, x_suffix)
    y_col_name = Symbol("p", num, y_suffix)

    required_cols = string.([x_col_name, y_col_name])

    if !all(col -> col in names(df), required_cols)
        error("One or more required columns (:$x_col_name, :$y_col_name) for player $num do not exist in the input DataFrame.")
    end

    return select(df, :tick, x_col_name, y_col_name)
end

"""
    decompose_path(player_df::AbstractDataFrame;
                      t_max_tick::Int = 150, d_max::Real = 20.0,
                      alpha::Real = 10.0, beta::Real = 0.5) -> Tuple{SimpleWeightedDiGraph, Vector{Int}}

Applies Path Decomposition (Dijkstra's shortest path) to find the minimum-cost 
path through a player's trajectory.

Returns: A tuple containing the constructed SimpleWeightedDiGraph and 
         a vector of row indices (path) from the start (1) to the end (N).
"""
function decompose_path(
    player_df::AbstractDataFrame;
    t_max_tick::Int=50,
    d_max::Real=20.0,
    alpha::Real=1.0,
    beta::Real=1.0
)::Tuple{SimpleWeightedDiGraph,Vector{Int}} # <- FIXED: Returns a Tuple

    n = nrow(player_df)

    # 1. Extract Coordinates
    # Assumes coordinate columns are the last two in the selected DataFrame
    x_col = names(player_df)[end-1]
    y_col = names(player_df)[end]

    x = Float64.(player_df[!, x_col])
    y = Float64.(player_df[!, y_col])
    ticks = player_df[!, :tick]

    # Helper function for distance

    dist(i::Int, j::Int) = hypot(x[i] - x[j], y[i] - y[j]) #

    # 2. Build the Weighted Directed Graph
    g = SimpleWeightedDiGraph{Int64,Float64}(n)

    # Define a tiny number (epsilon) to prevent division by zero

    for i in 1:n
        ti = ticks[i]

        for j in (i+1):n
            dt_tick = ticks[j] - ti

            # Stop once time window exceeded
            dt_tick > t_max_tick && break #

            d_ij = dist(i, j)

            if d_ij ≤ d_max
                # Calculate the raw combined cost (Distance + Time Jump)
                raw_cost = alpha * d_ij + beta * dt_tick

                # Apply the inverse cost function: 1 / (raw_cost + epsilon)
                # The small EPSILON prevents division by zero.
                w_ij = 1.0 / (raw_cost + 1e-16)

                add_edge!(g, i,
                    j, w_ij) #
            end
        end
    end

    # 3. Find Shortest Path
    distances = dijkstra_shortest_paths(g, 1)

    # Get the path to the last node
    path = enumerate_paths(distances, n)

    return g, path # <- FIXED: Return both the graph and the path
end
end
