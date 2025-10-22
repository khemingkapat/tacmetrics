using DataFrames, Parquet2

df = Parquet2.readfile("./vitality-vs-the-mongolz-m2-dust2/ticks.parquet") |> DataFrame

println(first(df, 5))



