### A Pluto.jl notebook ###
# v0.20.19

using Markdown
using InteractiveUtils

# ╔═╡ 0c3555e8-b38b-4278-bef0-03b77d2c3703
begin
    import Pkg
    Pkg.activate(Base.current_project())
    Pkg.instantiate()
    
    # Load Revise FIRST
    using Revise
    
    # Now load your packages - changes will auto-update!
    using CSV, DataFrames, Plots, Parquet2, TacMetrics
end

# ╔═╡ 8801b0fe-af4d-11f0-170b-972b2cf4deaa
md"""
# Read Data
"""

# ╔═╡ d998d25c-658c-4b8c-9c7e-418fe5bf2f5e
df = Parquet2.readfile("../demos/vitality-vs-the-mongolz-m2-dust2/ticks.parquet") |> DataFrame

# ╔═╡ dc4d9def-d9c8-49d2-9780-7c52075a8578
md"# Round and Side Selection"

# ╔═╡ 17a61ab7-113d-4e4f-ac82-d4974141190d
selected_round = 3

# ╔═╡ 01c0dddd-cbf2-4dc3-afab-5718e603d434
selected_side = "ct"

# ╔═╡ 92cba50f-0b54-44bd-9809-739e8d1b958d
selected_df = filter(row -> row.round_num == selected_round && row.side == selected_side, df, view=false)

# ╔═╡ 9c7a6fca-e151-4583-a9da-89556a254e84
md"# Transform DataFrames"

# ╔═╡ 3890ab65-d19c-4178-b26f-854ac84defda
wide_df = wide_transform(selected_df,:tick)

# ╔═╡ Cell order:
# ╠═0c3555e8-b38b-4278-bef0-03b77d2c3703
# ╟─8801b0fe-af4d-11f0-170b-972b2cf4deaa
# ╠═d998d25c-658c-4b8c-9c7e-418fe5bf2f5e
# ╟─dc4d9def-d9c8-49d2-9780-7c52075a8578
# ╠═17a61ab7-113d-4e4f-ac82-d4974141190d
# ╠═01c0dddd-cbf2-4dc3-afab-5718e603d434
# ╠═92cba50f-0b54-44bd-9809-739e8d1b958d
# ╟─9c7a6fca-e151-4583-a9da-89556a254e84
# ╠═3890ab65-d19c-4178-b26f-854ac84defda
