using DataFrames
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
    trim_trajectory(df::AbstractDataFrame) -> DataFrame

Removes leading and trailing rows from the player's DataFrame where the player 
is stationary (coordinates do not change). This ensures the path decomposition 
focuses only on the active movement phase.

The returned DataFrame includes the tick *before* the first move and the tick 
*after* the last move for a complete segment.
"""
function trim_trajectory(df::AbstractDataFrame)
    coords = select(df, Not(:tick))

    mat = Matrix(coords)
    deltas = diff(mat, dims=1)

    moved_flags = any(deltas .!= 0, dims=2)

    first_move = findfirst(vec(moved_flags))
    last_move = findlast(vec(moved_flags))

    if isnothing(first_move)
        return df[1:1, :]
    end

    return df[first_move:last_move+1, :]
end
