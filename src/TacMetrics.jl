# src/TacMetrics.jl
module TacMetrics

include("PathDecomposition/PathDecomposition.jl")
using .PathDecomposition

# Add these lines for clustering
include("DynamicClustering/DynamicClustering.jl")
using .DynamicClustering

# Export module and its core functions
export PathDecomposition, decompose_path, select_single_player
export DynamicClustering, cluster_players, construct_cost_matrix, build_cluster_graph

include("transformer.jl")
export transform_coord, transform_coords, load_map_data, transform_wide

end
