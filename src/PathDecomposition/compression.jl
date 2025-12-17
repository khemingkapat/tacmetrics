using DataFrames, Graphs, SimpleWeightedGraphs, Statistics
# This file contains functions for analyzing and compressing the decomposed path.

"""
    calculate_segment_distances(path::Vector{Int}, player_df::AbstractDataFrame) -> Vector{Float64}

Calculates the Euclidean distance for each segment in the optimal `path`.
The path indices refer to rows in `player_df`.

Returns a vector of distances, where the i-th element is the distance between 
`path[i]` and `path[i+1]`.
"""
function calculate_segment_distances(path::Vector{Int}, player_df::AbstractDataFrame)::Vector{Float64}
    n_path = length(path)
    n_path <= 1 && return Float64[]

    # Extract coordinates for the points in the optimal path
    x = Float64.(player_df[path, end-1])
    y = Float64.(player_df[path, end])

    distances = Vector{Float64}(undef, n_path - 1)

    for i in 1:(n_path-1)
        x_prev, y_prev = x[i], y[i]
        x_curr, y_curr = x[i+1], y[i+1]
        distances[i] = hypot(x_curr - x_prev, y_curr - y_prev)
    end

    return distances
end


"""
    process_distances(distances::Vector{Float64}, max_fault::Int=2, mean_multiplier::Real=1) -> Vector{UnitRange{Int}}

Identifies continuous segments of low movement based on the segment distances.
A segment is defined as a series of distances below a threshold, allowing for 
a small number of 'faults' (distances above the threshold).

# Arguments:
- `distances`: Vector of segment distances (from `calculate_segment_distances`).
- `max_fault`: The number of high-distance points allowed before a segment break.
- `mean_multiplier`: Multiplier for the mean distance to set the low-movement threshold.

Returns: A vector of UnitRanges, where each range indicates the indices (in 
the `distances` vector) corresponding to a low-movement segment.
"""
function process_distances(distances::Vector{Float64}, max_fault::Int=2, mean_multiplier::Real=1)::Vector{UnitRange{Int}}
    n = length(distances)
    n == 0 && return UnitRange{Int}[]

    mean_distance = Statistics.mean(distances) * mean_multiplier
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
            fault = 0 # Reset fault count if distance is below threshold
        else # Distance is high (potential segment end)
            if in_segment
                fault += 1
                if fault > max_fault
                    # Segment ended `max_fault` steps ago
                    end_idx = i - fault

                    # NOTE: Reverting segment length check to original notebook logic:
                    if end_idx >= start_idx + max_fault
                        push!(segments, start_idx:end_idx)
                    end
                    in_segment = false
                    fault = 0
                end
            end
        end
    end

    # Handle segment still active at the end of the path
    if in_segment
        end_idx = n - fault
        # NOTE: Reverting segment length check to original notebook logic:
        if end_idx >= start_idx + max_fault
            push!(segments, start_idx:end_idx)
        end
    end

    return segments
end


"""
    process_path(path::Vector{Int}, segments::Vector{UnitRange{Int}}, player_df::AbstractDataFrame) -> DataFrame

Compresses the optimal path (`path`) by replacing low-movement segments with 
a single point representing the mean coordinates of that segment's trajectory.
All non-segment points are kept.

# Arguments:
- `path`: Vector of indices from the decomposed path.
- `segments`: Vector of segment ranges (indices into the *path* vector).
- `player_df`: The full DataFrame containing the points referenced by `path`.

Returns: A new DataFrame (`filtered_player_df`) with the simplified trajectory.
"""
function process_path(path::Vector{Int}, segments::Vector{UnitRange{Int}}, player_df::AbstractDataFrame)::DataFrame
    filtered_rows = []

    segment_idx = 1
    n_segment = length(segments)

    # State variable to track the index of the last point added from player_df row indices
    last_path_index_added = -1

    idx = 1
    while idx <= length(path)
        current_index = path[idx] # Row index in player_df

        # 1. Handle START of a segment edge index
        if (segment_idx <= n_segment) && (idx == segments[segment_idx].start)
            # This logic is copied exactly from the notebook's conditional block
            if last_path_index_added != current_index
                # Original notebook had 'push' commented out, keeping it that way
                last_path_index_added = current_index
            end

            # Jump idx to the index corresponding to the last edge of the segment + 1
            idx = segments[segment_idx].stop + 1
            continue
        end

        # 2. Handle END of a segment edge index
        if (segment_idx <= n_segment) && (idx == segments[segment_idx].stop)
            segment = segments[segment_idx]

            # Calculate the mean point for the segment. 
            # Original notebook used nodes from path[segment.start] to path[segment.stop].
            segment_point_indices = path[segment.start:segment.stop]
            segment_data = player_df[segment_point_indices, :]

            # Use Statistics.mean for explicit import
            segment_row = combine(segment_data, All() .=> Statistics.mean; renamecols=false)
            push!(filtered_rows, segment_row[1, :])

            # Add the end node of the segment (path[idx]) if not a duplicate
            if current_index != last_path_index_added
                push!(filtered_rows, player_df[current_index, :])
                last_path_index_added = current_index
            end

            segment_idx += 1
            idx += 1
            continue
        end

        # 3. Handle non-segment points
        if last_path_index_added != current_index
            push!(filtered_rows, player_df[current_index, :])
            last_path_index_added = current_index
        end

        idx += 1
    end

    # Note: The original notebook does not include the final coordinate-based 
    # deduplication, so that logic has been removed to maintain fidelity.
    filtered_player_df = DataFrame(filtered_rows)

    return filtered_player_df
end


"""
    build_compressed_graph(filtered_player_df::AbstractDataFrame) -> SimpleWeightedDiGraph

Builds a new directed, weighted graph from the compressed trajectory.
The nodes are the rows of `filtered_player_df`.
The edge weights are the time differences (ticks) between consecutive nodes.
"""
function build_compressed_graph(filtered_player_df::AbstractDataFrame)::SimpleWeightedDiGraph
    n_nodes = nrow(filtered_player_df)
    n_nodes <= 1 && return SimpleWeightedDiGraph(0)

    g_compressed = SimpleWeightedDiGraph(n_nodes)

    ticks = filtered_player_df.tick

    for i in 1:(n_nodes-1)
        source_node = i
        target_node = i + 1

        # Weight is the time difference (tick delta)
        weight = ticks[i+1] - ticks[i]
        # Ensure weight is positive/non-negative for distance/time metrics
        if weight >= 0
            add_edge!(g_compressed, source_node, target_node, weight)
        end
    end

    return g_compressed
end
