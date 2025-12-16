module TacMetrics

include("PathDecomposition/PathDecomposition.jl")
using .PathDecomposition

# Export module and its core functions
export PathDecomposition, decompose_path, select_single_player

include("transformer.jl")
# Export functions from transformer.jl, including the newly moved one
export transform_coord, transform_coords, load_map_data, transform_wide

end
