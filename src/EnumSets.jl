module EnumSets
export @enumset
export push, enumsettype

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

struct EnumSet{E, C, P <: PackingTrait} <: AbstractSet{E} 
    _data::C
    function EnumSet{E,C,P}(data::C) where {E,C,P}
        new{E,C,P}(data)
    end
end

function Base.show(io::IO, s::EnumSet)
    print(io, typeof(s), '(', Tuple(s), ')')
end

function EnumSet{E,C,P}()::EnumSet{E,C,P} where {E,C,P}
    EnumSet{E,C,P}(zero(C))
end

function EnumSet{E,C,P}(s::EnumSet{E,C,P})::EnumSet{E,C,P} where {E,C,P}
    s
end

function EnumSet{E,C,P}(itr)::EnumSet{E,C,P} where {E,C,P}
    ret = EnumSet{E,C,P}()
    for e in itr
        ret = push(ret, convert(E, e))
    end
    ret
end

function PackingTrait(s::EnumSet{E,C,P})::PackingTrait where {E,C,P}
    P()
end

function _get_data(s)
    s._data
end

function setbit(s::EnumSet, i::Int, val::Bool)::typeof(s)
    typeof(s)(setbit(_get_data(s), i, val))
end
function getbit(s::EnumSet, i::Int)::Bool
    getbit(_get_data(s), i)
end

function Base.in(e::E, s::EnumSet{E})::Bool where {E}
    i = bitindex_from_instance(E, PackingTrait(s), e)
    getbit(s, i)
end
function push(s::EnumSet{E}, e::E)::typeof(s) where {E}
    i = bitindex_from_instance(E, PackingTrait(s), e)
    setbit(s, i, true)
end
function push(s::EnumSet{E}, es...)::typeof(s) where {E}
    union(s, es)
end
function pop(s::EnumSet{E}, e::E)::typeof(s) where {E}
    i = bitindex_from_instance(E, PackingTrait(s), e)
    @boundscheck if !getbit(s, i)
        throw(KeyError(e))
    end
    setbit(s, i, false)
end
function capacity(s::EnumSet)::Int
    8*sizeof(s)
end
function Base.length(s::EnumSet)::Int
    count_ones(s._data)
end

function Base.hash(s::EnumSet{E}, h::UInt)::UInt where {E}
    h = hash(E, h)
    hash(_get_data(s), h)
end

function Base.filter(f, s::EnumSet)::typeof(s)
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

function Base.iterate(s::EnumSet{E,I}, state=_get_data(s))::Union{Nothing, Tuple{E, I}} where {E,I}
    next_state = blsr(state)
    if next_state === state
        return nothing
    else
        i = trailing_zeros(state)
        instance_from_bitindex(E, PackingTrait(s), i), next_state
    end
end

function boolean(f,s::S, ss...)::S where {S <: EnumSet}
    d = _get_data(s)
    ds = map(_get_data ∘ S, ss)
    S(f(d, ds...))
end

function Base.union(s1::S, ss...)::S where {S <: EnumSet}
    boolean((|),s1,ss...)
end

function Base.intersect(s1::S, ss...)::S where {S <: EnumSet}
    boolean((&),s1,ss...)
end

function Base.symdiff(s1::S, ss...)::S where {S <: EnumSet}
    boolean(xor,s1,ss...)
end

function bitdiff(x, xs...)
    (&)(x, map(~, xs)...)
end

function Base.setdiff(s1::S, ss...)::S where {S <: EnumSet}
    boolean(bitdiff,s1,ss...)
end

function Base.issubset(s1::S, s2::S)::Bool where {S <: EnumSet}
    s1 ∩ s2 === s1
end

function make_error_msg(ex)
    """
    $ex is not an expression of the form
    MySet <: EnumSet{MyEnum}
    MySet <: EnumSet{MyEnum, UInt64}
    """
end

"""
This macro is deprecate. Use `const MySet = enumsettype(MyEnum)` instead.
"""
macro enumset(ex)
    if !Meta.isexpr(ex, :<:)
        error(make_error_msg(ex))
    end
    ESet, ex_EnumSet = ex.args
    if !Meta.isexpr(ex_EnumSet, :curly)
        error(make_error_msg(ex_EnumSet))
    end
    if length(ex_EnumSet.args) == 2
        symbol_EnumSet, E = ex_EnumSet.args
        C = nothing
    elseif length(ex_EnumSet.args) == 3
        symbol_EnumSet, E, C = ex_EnumSet.args
    else
        error(make_error_msg(ex_EnumSet))
    end
    E = __module__.eval(E)
    C = __module__.eval(C)
    if isnothing(C)
        C = suggest_carriertype(E)
    end
    esc(:(const $ESet = $enumsettype($E; carrier=$C)))
end


function enum_fits_into_offset_packing(E, nbits)
    lo, hi = extrema(Integer, instances(E))
    # convert to Float64 to prevent overflow issues
    (abs(hi - lo) < nbits) && (abs(Float64(hi) - Float64(lo)) < nbits)
end

"""
    enumsettype(::Type{E})::Type

Return a subtype of `EnumSet` suitable for storing instances of an enum `E`.
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
    P = if enum_fits_into_offset_packing(E, nbits(C))
        OffsetBasedPacking{-minimum(Int, instances(E))}
    else
        InstanceBasedPacking
    end
    EnumSet{E, C, P}
end


end
