
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
