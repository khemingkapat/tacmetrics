using JSON, DataFrames

# Default path for awpy map data
const DEFAULT_MAP_DATA_PATH = joinpath(dirname(@__DIR__), ".awpy", "maps", "map_data.json")


"""
    transform_coord(map_data::Dict, player_loc::DataFrame; 
                    x_col::Symbol=:x, y_col::Symbol=:y, 
                    image_dim::Float64=1024.0) -> DataFrame

Transform coordinates from game space to image space for a single coordinate pair.
"""
function transform_coord(
    map_data::Dict,
    player_loc::AbstractDataFrame;
    x_col::Symbol=:x,
    y_col::Symbol=:y,
    image_dim::Float64=1024.0
)::DataFrame
    result = copy(player_loc)

    pos_x = map_data["pos_x"]
    pos_y = map_data["pos_y"]
    scale = map_data["scale"]

    # Transform X coordinate
    result[!, x_col] = (result[!, x_col] .- pos_x) ./ scale

    # Transform Y coordinate (with image dimension inversion)
    result[!, y_col] = image_dim .- (pos_y .- result[!, y_col]) ./ scale

    return result
end

"""
    transform_coords(map_data::Dict, player_loc::DataFrame, 
                     status::Vector{String}; 
                     image_dim::Float64=1024.0) -> DataFrame

Transform multiple coordinate pairs (e.g., for different player states or positions).
"""
function transform_coords(
    map_data::Dict,
    player_loc::AbstractDataFrame,
    status::Vector{String};
    image_dim::Float64=1024.0
)::DataFrame
    tf = copy(player_loc)

    for st in status
        x_col = Symbol("$(st)_x")
        y_col = Symbol("$(st)_y")

        tf = transform_coord(
            map_data,
            tf,
            x_col=x_col,
            y_col=y_col,
            image_dim=image_dim
        )
    end

    return tf
end

"""
    transform_coords(map_data::Dict, player_loc::DataFrame, 
                     status::Vector{Symbol}; 
                     image_dim::Float64=1024.0) -> DataFrame

Variant accepting Symbol vector instead of String vector.
"""
function transform_coords(
    map_data::Dict,
    player_loc::AbstractDataFrame,
    status::Vector{Symbol};
    image_dim::Float64=1024.0
)::DataFrame
    # Convert symbols to strings and call the main function
    status_strings = String.(status)
    return transform_coords(map_data, player_loc, status_strings; image_dim=image_dim)
end

"""
    load_map_data(map_name::String; path::String=DEFAULT_MAP_DATA_PATH) -> Dict

Load map data from the awpy map_data.json file.
"""
function load_map_data(map_name::String; path::String=DEFAULT_MAP_DATA_PATH)::Dict
    if !isfile(path)
        error("Map data file not found at: $path")
    end

    # Read and parse JSON
    all_maps = JSON.parsefile(path)

    if !haskey(all_maps, map_name)
        available_maps = join(keys(all_maps), ", ")
        error("Map '$map_name' not found in map_data.json. Available maps: $available_maps")
    end

    return all_maps[map_name]
end


include("types.jl")


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
function transform_wide(df::AbstractDataFrame, group_col::Symbol)::DataFrame
    grouped = groupby(df, group_col)
    return combine(grouped, transform_group)
end
