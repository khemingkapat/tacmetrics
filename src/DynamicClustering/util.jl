function get_node_id(node_map::Dict, tick::Int, cluster::Int)
    if !haskey(node_map, (tick, cluster))
        next_id = length(node_map) + 1
        node_map[(tick, cluster)] = next_id
        return next_id
    end
    return node_map[(tick, cluster)]
end
