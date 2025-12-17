module PathDecomposition

using DataFrames, Graphs, SimpleWeightedGraphs, Statistics

# Include sub-files for organization
include("preprocessing.jl")
include("core.jl")
include("compression.jl")

# Exports from preprocessing.jl
export select_single_player, trim_trajectory

# Exports from core.jl
export decompose_path

# Exports from compression.jl
export calculate_segment_distances, process_distances, process_path, build_compressed_graph

end
