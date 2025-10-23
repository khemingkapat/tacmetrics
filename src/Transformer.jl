using DataFrames

"""
Type representing player coordinates for 5 players (X,Y pairs).
"""
const PlayerCoords = @NamedTuple{
    p1x::Union{Float64,Missing}, p1y::Union{Float64,Missing},
    p2x::Union{Float64,Missing}, p2y::Union{Float64,Missing},
    p3x::Union{Float64,Missing}, p3y::Union{Float64,Missing},
    p4x::Union{Float64,Missing}, p4y::Union{Float64,Missing},
    p5x::Union{Float64,Missing}, p5y::Union{Float64,Missing}
}

"""
    transform_group(group)

Transform a group of players from long format to wide format.
Sorts by steamid and extracts X,Y coordinates for up to 5 players.
"""
function transform_group(group::AbstractDataFrame)::PlayerCoords
    sorted_group = sort(group, :steamid)
    coords = Vector{Union{Float64,Missing}}(undef, 10)
    fill!(coords, missing)

    num_players = min(size(sorted_group, 1), 5)

    for i in 1:num_players
        x_index = 2 * i - 1
        y_index = 2 * i

        coords[x_index] = sorted_group[i, :X]
        coords[y_index] = sorted_group[i, :Y]
    end

    # Return explicit NamedTuple
    return (
        p1x=coords[1], p1y=coords[2],
        p2x=coords[3], p2y=coords[4],
        p3x=coords[5], p3y=coords[6],
        p4x=coords[7], p4y=coords[8],
        p5x=coords[9], p5y=coords[10]
    )
end

"""
    wide_transform(df, group_col)

Transform a DataFrame from long to wide format, grouping by `group_col`.
"""
function wide_transform(df::AbstractDataFrame, group_col::Symbol)::DataFrame
    grouped = groupby(df, group_col)
    return combine(grouped, transform_group)
end
