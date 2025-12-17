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
    trim_trajectory(all_player_df::AbstractDataFrame) -> DataFrame

Removes leading and trailing rows from the player's DataFrame where the player 
is stationary (coordinates do not change). This ensures the path decomposition 
focuses only on the active movement phase.

The returned DataFrame includes the tick *before* the first move and the tick 
*after* the last move for a complete segment.
"""
function trim_trajectory(all_player_df::AbstractDataFrame)
    n = nrow(all_player_df)
    if n <= 1
        return all_player_df
    end

    # Extract coordinates (assumed to be the last two columns)
    x_col = all_player_df[:, end-1]
    y_col = all_player_df[:, end]

    # Calculate previous position (using missing for the first row)
    x_prev = vcat(missing, x_col[1:end-1])
    y_prev = vcat(missing, y_col[1:end-1])

    # Determine if the player moved from the previous tick
    moved = (x_col .!= x_prev) .| (y_col .!= y_prev)
    moved = coalesce.(moved, false)

    # Find first tick where movement happened
    first_move_idx = findfirst(moved)
    if isnothing(first_move_idx)
        # Player never moved, return the whole path
        return all_player_df
    end

    # Find last tick where movement happened
    last_move_idx_relative = findfirst(reverse(moved))
    if isnothing(last_move_idx_relative)
        # Should not happen if first_move_idx is not nothing, but for safety
        return all_player_df
    end
    last_move_idx = n - last_move_idx_relative + 1

    # Adjust indices to include the tick just before the first move (for starting point)
    start_idx = max(1, first_move_idx - 1)
    # The last_move_idx already points to the last moving tick, we don't need +1
    end_idx = last_move_idx

    return all_player_df[start_idx:end_idx, :]
end
