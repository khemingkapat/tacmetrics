using LinearAlgebra, DataFrames
function point_segment_dist2(p::AbstractVector,
    a::AbstractVector,
    b::AbstractVector)
    ab = b - a
    denom = dot(ab, ab)

    # Degenerate segment
    if denom < eps()
        return dot(p - a, p - a)
    end

    t = clamp(dot(p - a, ab) / denom, 0.0, 1.0)
    proj = a + t * ab
    return dot(p - proj, p - proj)
end

function calculate_path_r2(player_df::AbstractDataFrame,
    path::Vector{Int})

    x_col, y_col = names(player_df)[end-1:end]

    # positions as vectors
    pos = [@views Float64[player_df[i, x_col],
        player_df[i, y_col]] for i in 1:nrow(player_df)]

    n = length(pos)

    rss = 0.0
    for k in 1:length(path)-1
        i, j = path[k], path[k+1]
        a, b = pos[i], pos[j]

        for idx in i:(j-1)
            rss += point_segment_dist2(pos[idx], a, b)
        end
    end

    a, b = pos[1], pos[end]
    tss = sum(point_segment_dist2(p, a, b) for p in pos)

    return tss < 1e-9 ? 1.0 : 1.0 - rss / tss
end

