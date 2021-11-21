using SortingAlgorithms, SortMark

df = SortMark.make_df([SortingAlgorithms.RadixSort2Alg(QuickSort), QuickSort, SortingAlgorithms.RadixSort2Alg(MergeSort), MergeSort],
    unstable=[SortingAlgorithms.RadixSort2Alg(QuickSort), QuickSort])
expected = (df.Type .∉ [[UInt64, UInt128]]) .| (df.order .!= [Base.Order.Reverse]) .| (df.source_key .!= [:small_positive])
df = df[expected, :]
compute!(df, fail_fast=false)
stat!(df, 1, 2)
display(df[first(df.worst_first),[2:5...,15:17...]]) # few unique can be 2x slower.
wf = df[df.worst_first,[2:5...,15:17...]]
display(wf[findfirst(wf.source_key .== :simple), :])

x1 = df[(df.source_key .== :simple) .& (df.len .> 100) .& (df.Type .== Int) .&
    ((df.order .== [Base.Order.Forward]) .| (df.len .> 400)), :]
x1.seconds .= .05
compute!(x1)
stat!(x1, 1, 2)
println("always an improvement: ", maximum(first.(x1.confint)) < 1)
#Yay!

#Much still to do...


df = SortMark.make_df([RadixSort2, RadixSort], Types=SortMark.Ints ∪ SortMark.UInts)
expected = (df.Type .∉ [[UInt64, UInt128]]) .| (df.order .!= [Base.Order.Reverse]) .| (df.source_key .!= [:small_positive])
df = df[expected, :]
compute!(df)
stat!(df, 1, 2)

x2 = df[[83],:]
x2.seconds .= 1
compute!(x2)
stat!(x2, 1, 2)
#TODO why is this slower than RadixSort for large arrays of Int64?

df = SortMark.make_df([SortingAlgorithms.RawRadixSort2, RadixSort],
    Types=[UInt64], orders=[Base.Order.Forward],
    lens=SortMark.lengths(300, 1_000_000, 3),
    sources=Dict(:simple=>SortMark.sources[:simple]),
    seconds=nothing, samples=20)
compute!(df)
stat!(df)
display(df[:, [3,15:17...]])
