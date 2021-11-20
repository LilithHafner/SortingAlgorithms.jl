using OffsetArrays
using Base.Sort
import Base.Sort.sort!

struct RadixSort2Alg <: Algorithm end # Not exported by base
const RadixSort2 = RadixSort2Alg()    # Not exported by base

function sort!(v::AbstractVector, lo::Integer, hi::Integer, ::RadixSort2Alg, o::Ordering)

    T = Serializable(o, typeof(v))
    T === nothing && return sort!(v, lo, hi, MergeSort, o) # This has to be MergeSort rather
    # than defalg because defalg is unstable: https://github.com/JuliaLang/julia/issues/42713

    lo < hi || return v

    us, mn, mx = serialize(something(T), v, lo, hi, o)

    compression, bits, chunk_size = heuristic(mn, mx, hi-lo+1)

    us = compress!(us, compression)

    us = radix_sort!(us, similar(us, lo:hi), lo, hi, unsigned(bits), Val(UInt8(chunk_size)))

    deserialize!(v, us, lo, hi, o, compression)
end

used_bits(x::Union{Signed, Unsigned}) = sizeof(x)*8 - leading_zeros(x)
function heuristic(mn, mx, length)
    if used_bits(mx-mn) < used_bits(mx)
        compression = mn
        bits = used_bits(mx-mn)
    else
        compression = nothing
        bits = used_bits(mx)
    end

    bits == 0 && return compression, bits, 0

    guess = log(length)*3/4+3
    chunk = Int(cld(bits, cld(bits, guess)))

    compression, bits, chunk
end

function Base.Sort.Float.fpsort!(v::AbstractVector, a::RadixSort2Alg, o::Ordering)
    @static if VERSION >= v"1.7.0-DEV"
        lo, hi = Base.Sort.Float.specials2end!(v, a, o)
    else
        lo, hi = Base.Sort.Float.nans2end!(v, o)
    end
    sort!(v, lo, hi, a, o)
end

#TODO re-use memory where possible
# this is possible in a lot of cases, but for now, I am pretty much not reusing memory at all.
# e.g. us, mn, mx = (sizeof(U) <= sizeof(T) ? serialize! : serialize)(v, lo, hi, order)
#TODO perform type compression where possible
# this is possible in a lot of cases, but for now, I am not doing it at all.
#TODO special case sort() to copy on serialization
#TODO check type stability
#=TODO entierly rewrite the heuristic
a) benchmark
b) implement a simple, accurate, intuitive & performant heuristic
=#
#TODO consider & benchmark Unsigned, try to get performanceimprovlements, and hopefully
# remove almost all Unsigned.
