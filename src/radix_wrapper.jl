using OffsetArrays
using Base.Sort
using Base.Sort: sort_int_range!
import Base.Sort.sort!
import Base.Sort.defalg

struct RadixSort2Alg <: Algorithm # Not exported by base
    fallback::Algorithm
end

#defalg(v::AbstractArray) = RadixSort2Alg(DEFAULT_STABLE)
#defalg(v::AbstractArray{<:Union{Number, Missing}}) = RadixSort2Alg(DEFAULT_UNSTABLE)

function sort!(v::AbstractVector, lo::Integer, hi::Integer, a::RadixSort2Alg, o::Ordering)

    hi <= lo && return v

    (hi - lo < 500 || (hi - lo < 10_000 && sizeof(eltype(v)) == 16)) && return sort!(v, lo, hi, a.fallback, nan_free_unwrap(o))

    T = Serializable(o, typeof(v))
    T === nothing && return sort!(v, lo, hi, a.fallback, o)

    us, mn, mx = serialize(something(T), v, lo, hi, o)

    compression, bits, chunk_size, count = heuristic(mn, mx, hi-lo+1)

    if count
        us = sort_int_range!(us, mx-mn+1, mn, identity) # 1 not one().
    else
        us = compress!(us, compression)

        us = radix_sort!(us, similar(us, lo:hi), lo, hi, unsigned(bits), Val(UInt8(chunk_size)))
    end

    deserialize!(v, us, lo, hi, o, compression)
end

used_bits(x::Union{Signed, Unsigned}) = sizeof(x)*8 - leading_zeros(x)
function heuristic(mn, mx, length)
    mn == mx && return nothing, 0, 0, false
    length + mn > mx && return nothing, 0, 0, true #TODO optimize

    if used_bits(mx-mn) < used_bits(mx)
        compression = mn
        bits = used_bits(mx-mn)
    else
        compression = nothing
        bits = used_bits(mx)
    end

    guess = log(length)*3/4+3
    chunk = Int(cld(bits, cld(bits, guess)))

    compression, bits, chunk, false
end

function Base.Sort.Float.fpsort!(v::AbstractVector, a::RadixSort2Alg, o::Ordering)
    @static if VERSION >= v"1.7.0-DEV"
        lo, hi = Base.Sort.Float.specials2end!(v, a, o)
    else
        lo, hi = Base.Sort.Float.nans2end!(v, o)
    end
    sort!(v, lo, hi, a, nan_free(o))
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
