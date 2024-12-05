module EnumSets
export @enumset
export push

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

function to_bit_index(::Type{E}, e::E) where {E}
    for (i, v) in enumerate(instances(E))
        if v === e
            return i
        end
    end
    error("Unreachable")
end

function from_bit_index(::Type{E}, i) where {E}
    instances(E)[i]
end

function suggest_carriertype(E)
    n = length(instances(E))
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

abstract type EnumSet{E, Carrier} <: AbstractSet{E} end

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
    i = to_bit_index(E, e)
    getbit(s, i)
end
function push(s::EnumSet{E}, e::E)::typeof(s) where {E}
    i = to_bit_index(E, e)
    setbit(s, i, true)
end
function pop(s::EnumSet{E}, e::E)::typeof(s) where {E}
    i = to_bit_index(E, e)
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
function Base.iterate(s::EnumSet{E}, i::Int=1)::Union{Nothing, Tuple{E, Int}} where {E}
    c = capacity(s)
    while i <= c
        if getbit(s, i)
            return from_bit_index(E, i), i + 1
        else
            i += 1
        end
    end
    return nothing
end

function Base.union(s1::S, ss::S...)::S where {S <: EnumSet}
    S((|)(_get_data(s1), map(_get_data, ss)...))
end

function Base.intersect(s1::S, ss::S...)::S where {S <: EnumSet}
    S((&)(_get_data(s1), map(_get_data, ss)...))
end

function make_error_msg(ex)
    """
    $ex is not an expression of the form
    MySet <: EnumSet{MyEnum}
    MySet <: EnumSet{MyEnum, UInt64}
    """
end

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
        Carrier = nothing
    elseif length(ex_EnumSet.args) == 3
        symbol_EnumSet, E, Carrier = ex_EnumSet.args
    else
        error(make_error_msg(ex_EnumSet))
    end
    E = __module__.eval(E)
    Carrier = __module__.eval(Carrier)
    if isnothing(Carrier)
        Carrier = suggest_carriertype(E)
    end
    esc(enumsetmacro(E, ESet, Carrier))
end

function enumsetmacro(E::Type, ESet::Symbol, Carrier::Type)

    if length(instances(E)) > nbits(Carrier)
        msg = """
        Enum $E does not fit into carrier type $Carrier.
        length(instances($E)) = $(length(instances(E)))
        nbits($Carrier)       = $(nbits(Carrier))
        """
    end
    quote
        struct $ESet <: $EnumSet{$E, $Carrier}
            _data::$Carrier
            function $ESet(carrier::$Carrier)
                new(carrier)
            end
        end
        function $ESet()::$ESet
            $ESet(zero($Carrier))
        end
        function $ESet(e::$ESet)::$ESet
            e
        end
        function $ESet(itr)::$ESet
            ret = $ESet()
            for e in itr
                ret = $push(ret, convert($E, e))
            end
            ret
        end
    end
end

end
