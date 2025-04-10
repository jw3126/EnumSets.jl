module EnumSets
export push, enumsettype
export enumdicttype

function nbits(::Type{T}) where {T}
    8 * sizeof(T)
end

function getbit(xT::Integer, i)::Bool
    T = typeof(xT)
    iT = convert(T, i)
    (xT >> iT) & one(T)
end

function setbit(xT::Integer, i, val)
    T = typeof(xT)
    iT = convert(T, i)
    valT = convert(T, val)
    xT | (valT << iT)
end

abstract type PackingTrait end
struct InstanceBasedPacking <:PackingTrait
end
struct OffsetBasedPacking{offset} <:PackingTrait end

function get_offset(::OffsetBasedPacking{offset})::Int where {offset}
    offset
end

function carriertype(::Type{<:Enum{T}}) where {T} 
    T
end

function unsafe_enum_from_int(::Type{E}, x::Integer)::E where {E <: Enum}
    T = carriertype(E)
    xT = convert(T, x)
    reinterpret(E, xT)
end

function bitindex_from_instance(::Type{E}, trait::OffsetBasedPacking, e::E)::Int where {E}
    Int(e) + get_offset(trait)
end

function instance_from_bitindex(::Type{E}, trait::OffsetBasedPacking, i::Int)::E where {E}
    # TODO does this make a performance difference?
    # In theory it should, but I was not yet able to measure one in practice
    # unsafe_enum_from_int(E, i - get_offset(trait))
    E(i - get_offset(trait))
end

function bitindex_from_instance(::Type{E}, ::InstanceBasedPacking, e::E)::Int where {E}
    for (i, v) in enumerate(instances(E))
        if v === e
            return i
        end
    end
    error("Unreachable")
end

function instance_from_bitindex(::Type{E}, ::InstanceBasedPacking, i::Int)::E where {E}
    instances(E)[i]
end

function suggest_carriertype(E)
    n = if enum_fits_into_offset_packing(E, 128)
        lo, hi = extrema(Integer, instances(E))
        hi - lo
    else
        length(instances(E))
    end
    if n <= 8
        UInt8
    elseif n <= 16
        UInt16
    elseif n <= 32
        UInt32
    elseif n <= 64
        UInt64
    elseif n <= 128
        UInt128
    else
        error("Enum $E does not fit into carrier type UInt128.")
    end
end

struct EnumSetT{E, C, P <: PackingTrait} <: AbstractSet{E} 
    _data::C
    function EnumSetT{E,C,P}(data::C) where {E,C,P}
        new{E,C,P}(data)
    end
end

function default_packing_type()
    OffsetBasedPacking{0}
end

const EnumSet8{E} = EnumSetT{E, UInt8, default_packing_type()}
const EnumSet16{E} = EnumSetT{E, UInt16, default_packing_type()}
const EnumSet32{E} = EnumSetT{E, UInt32, default_packing_type()}
const EnumSet64{E} = EnumSetT{E, UInt64, default_packing_type()}
const EnumSet128{E} = EnumSetT{E, UInt128, default_packing_type()}

function Base.show(io::IO, s::EnumSetT)
    print(io, typeof(s), '(', Tuple(s), ')')
end

function EnumSetT{E,C,P}()::EnumSetT{E,C,P} where {E,C,P}
    EnumSetT{E,C,P}(zero(C))
end

function EnumSetT{E,C,P}(s::EnumSetT{E,C,P})::EnumSetT{E,C,P} where {E,C,P}
    s
end

function EnumSetT{E,C,P}(itr)::EnumSetT{E,C,P} where {E,C,P}
    ret = EnumSetT{E,C,P}()
    for e in itr
        ret = push(ret, convert(E, e))
    end
    ret
end

function PackingTrait(s::EnumSetT{E,C,P})::PackingTrait where {E,C,P}
    P()
end

function _get_data(s)
    s._data
end

function setbit(s::EnumSetT, i::Int, val::Bool)::typeof(s)
    typeof(s)(setbit(_get_data(s), i, val))
end
function getbit(s::EnumSetT, i::Int)::Bool
    getbit(_get_data(s), i)
end

function Base.in(e::E, s::EnumSetT{E})::Bool where {E}
    i = bitindex_from_instance(E, PackingTrait(s), e)
    getbit(s, i)
end
function push(s::EnumSetT{E}, e::E)::typeof(s) where {E}
    i = bitindex_from_instance(E, PackingTrait(s), e)
    setbit(s, i, true)
end
function push(s::EnumSetT{E}, es...)::typeof(s) where {E}
    union(s, es)
end
function pop(s::EnumSetT{E}, e::E)::typeof(s) where {E}
    i = bitindex_from_instance(E, PackingTrait(s), e)
    @boundscheck if !getbit(s, i)
        throw(KeyError(e))
    end
    setbit(s, i, false)
end
function capacity(s::EnumSetT)::Int
    8*sizeof(s)
end
function Base.length(s::EnumSetT)::Int
    count_ones(s._data)
end

function Base.hash(s::EnumSetT{E}, h::UInt)::UInt where {E}
    h = hash(E, h)
    hash(_get_data(s), h)
end

function Base.filter(f, s::EnumSetT)::typeof(s)
    # could use boolean here
    ret = typeof(s)()
    for e in s
        if f(e)
            ret = push(ret, e)
        end
    end
    ret
end

function blsr(x::T)::T where {T<:Integer}
    # Reset Lowest Set Bit i. Toggles lowest 1 bit into zero
    # input : 01011100 
    # output: 01011000
    # leaves zero as is:
    # input : 00000000
    # output: 00000000
    convert(T,Base._blsr(x))
end

function Base.iterate(s::EnumSetT{E,I}, state=_get_data(s))::Union{Nothing, Tuple{E, I}} where {E,I}
    next_state = blsr(state)
    if next_state === state
        return nothing
    else
        i = trailing_zeros(state)
        instance_from_bitindex(E, PackingTrait(s), i), next_state
    end
end

function boolean(f,s::S, ss...)::S where {S <: EnumSetT}
    d = _get_data(s)
    ds = map(_get_data ∘ S, ss)
    S(f(d, ds...))
end

function Base.union(s1::S, ss...)::S where {S <: EnumSetT}
    boolean((|),s1,ss...)
end

function Base.intersect(s1::S, ss...)::S where {S <: EnumSetT}
    boolean((&),s1,ss...)
end

function Base.symdiff(s1::S, ss...)::S where {S <: EnumSetT}
    boolean(xor,s1,ss...)
end

function bitdiff(x, xs...)
    (&)(x, map(~, xs)...)
end

function Base.setdiff(s1::S, ss...)::S where {S <: EnumSetT}
    boolean(bitdiff,s1,ss...)
end

function Base.issubset(s1::S, s2::S)::Bool where {S <: EnumSetT}
    s1 ∩ s2 === s1
end

function enum_fits_into_offset_packing(E, nbits)
    lo, hi = extrema(Integer, instances(E))
    # convert to Float64 to prevent overflow issues
    (abs(hi - lo) < nbits) && (abs(Float64(hi) - Float64(lo)) < nbits)
end

function enum_fits_into_default_packing(E, nbits)
    lo, hi = extrema(Integer, instances(E))
    if lo < 0
        return false
    else
        hi < nbits
    end
end

"""
    enumsettype(::Type{E})::Type

Return a subtype of `EnumSetT` suitable for storing instances of an enum `E`.
Typical usage looks like this:
```julia
@enum Alphabet A B C
const MySet = enumsettype(Alphabet)

ab = MySet((A, B))
bc = MySet((B, C))
ab ∩ bc
...
```
"""
function enumsettype(::Type{E}; carrier::Union{Nothing, Type}=nothing)::Type where {E}
    C = if isnothing(carrier)
        suggest_carriertype(E)
    else
        carrier
    end
    if length(instances(E)) > nbits(C)
        msg = """
        Enum $E does not fit into carrier type $C.
        length(instances($E)) = $(length(instances(E)))
        nbits($C)       = $(nbits(C))
        """
        error(msg)
    end
    P = if enum_fits_into_default_packing(E, nbits(C))
        default_packing_type()
    elseif enum_fits_into_offset_packing(E, nbits(C))
        OffsetBasedPacking{-minimum(Int, instances(E))}
    else
        InstanceBasedPacking
    end
    EnumSetT{E, C, P}
end

################################################################################
# EnumDictT 
################################################################################
mutable struct EnumDictT{K,V,Keys <: EnumSetT,ValStore} <: AbstractDict{K,V}
    keys::Keys
    value_store::ValStore
    function EnumDictT{K,V,Keys,ValStore}(keys::Keys, value_store::ValStore) where {K,V,Keys,ValStore}
        if eltype(keys) !== K
            msg = """
            eltype(keys) === K must hold. Got:
            K = $K
            Keys = $Keys
            eltype(Keys) = $(eltype(Keys))
            """
            throw(ArgumentError(msg))
        end
        if eltype(value_store) !== V
            msg = """
            eltype(value_store) === V must hold. Got:
            V = $V
            ValStore = $ValStore
            eltype(ValStore) = $(eltype(ValStore))
            """
            throw(ArgumentError(msg))
        end
        new{K,V,Keys,ValStore}(keys, value_store)
    end
end

function make_empty(::Type{EnumDictT{K,V,Keys,ValStore}}) where {K,V,Keys,ValStore}
    keys::Keys = Keys()
    value_store::ValStore = ValStore(undef, 8*sizeof(Keys)) # we could make this smaller
    EnumDictT{K,V,Keys,ValStore}(keys, value_store)
end

function cmd_dict(eq, d1, d2)::Bool
    if !eq(keys(d1), keys(d2))
        return false
    end
    for k in keys(d1)
        if !eq(d1[k], d2[k])
            return false
        end
    end
    return true
end

function Base.isequal(d1::EnumDictT, d2::EnumDictT)
    cmd_dict(isequal, d1, d2)
end
function Base.:(==)(d1::EnumDictT, d2::EnumDictT)
    cmd_dict(==, d1, d2)
end

function Base.hash(d::EnumDictT, h::UInt)
    h = hash(d.keys, h)
    for v in values(d)
        h = hash(v, h)
    end
    h
end

function Base.empty(d::EnumDictT)
    make_empty(typeof(d))
end

function EnumDictT{K,V,Keys,ValStore}(pairs::Pair...) where {K,V,Keys,ValStore}
    d = make_empty(EnumDictT{K,V,Keys,ValStore})
    for (k,v) in pairs
        d[k] = v
    end
    d
end

function EnumDictT{K,V,Keys,ValStore}((k,v)::Pair) where {K,V,Keys,ValStore}
    d = make_empty(EnumDictT{K,V,Keys,ValStore})
    d[k] = v
    d
end

function EnumDictT{K,V,Keys,ValStore}(pairs) where {K,V,Keys,ValStore}
    ret = EnumDictT{K,V,Keys,ValStore}()
    for (k,v) in pairs
        ret[k] = v
    end
    ret
end

const EnumDict8{K,V} = EnumDictT{K,V,EnumSet8{K},Vector{V}}
const EnumDict16{K,V} = EnumDictT{K,V,EnumSet16{K},Vector{V}}
const EnumDict32{K,V} = EnumDictT{K,V,EnumSet32{K},Vector{V}}
const EnumDict64{K,V} = EnumDictT{K,V,EnumSet64{K},Vector{V}}
const EnumDict128{K,V} = EnumDictT{K,V,EnumSet128{K},Vector{V}}

function enumdicttype(::Type{Keys}) where {Keys}
    K = eltype(Keys)
    EnumDictT{K,V,Keys,Vector{V}} where {V}
end

function enumdicttype(::Type{Keys}, ::Type{V}) where {Keys <: EnumSetT,V}
    enumdicttype(Keys){V}
end


function Base.keys(d::EnumDictT)
    d.keys
end

function store_index_from_instance(d::EnumDictT{K,V,Keys}, key)::Int where {K,V,Keys}
    keyT = convert(K, key)
    bitindex_from_instance(K, PackingTrait(keys(d)), keyT) + 1
end
function Base.length(d::EnumDictT)
    length(keys(d))
end

Base.@propagate_inbounds function Base.getindex(d::EnumDictT{K,V,Keys}, k)::V where {K,V,Keys}
    i = store_index_from_instance(d, k)
    d.value_store[i]
end

Base.@propagate_inbounds function Base.setindex!(d::EnumDictT, v, k)
    i = store_index_from_instance(d, k)
    d.value_store[i] = v
    d.keys = push(d.keys, k)
    d
end
function Base.delete!(d::EnumDictT, k)
    d.keys = setdiff(d.keys, (k,))
    d
end
function Base.iterate(d::EnumDictT, kstate...)
    knext = iterate(keys(d), kstate...)
    if isnothing(knext)
        nothing
    else
        k, state = knext
        v = getindex(d, k)
        (k => v), state
    end
end

function Base.merge(d::EnumDictT, others::AbstractDict...)
    ret = copy(d)
    merge!(ret, others...)
    ret
end

end
