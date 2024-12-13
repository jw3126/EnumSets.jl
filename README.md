# EnumSets

[![Build Status](https://github.com/jw3126/EnumSets.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/jw3126/EnumSets.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/jw3126/EnumSets.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/jw3126/EnumSets.jl)

This packages allows to create a very fast immutable type that represents a set of enum values.
```julia
julia> using EnumSets

julia> @enum Lang Python Julia C

julia> const LangSet = enumsettype(Lang)

julia> s = LangSet((Python, Julia))
LangSet with 2 elements:
  Python
  Julia

julia> push(s, C) # s is immutable, but we can create modified copies
LangSet with 3 elements:
  Python
  Julia
  C

julia> s
LangSet with 2 elements:
  Python
  Julia

julia> s2 = LangSet((C, Python))
LangSet with 2 elements:
  Python
  C

julia> s ∪ s2
LangSet with 3 elements:
  Python
  Julia
  C

julia> s ∩ s2
LangSet with 1 element:
  Python

...
```

## Performance

```julia
using EnumSets

@enum Alphabet A B C D E F G H I J K L M N O P Q R S T U V W X Y Z

function workout(sets)
    s = first(sets)
    b = false
    ESet = eltype(sets)
    E = eltype(ESet)
    for s1 in sets
        for s2 in sets
            for e in instances(E)
                s = (s ∩ s2) ∪ s1
                s = s ∪ s1
                s = symdiff(s, ESet((e,)))
                b = b ⊻ (s1 ⊆ s2)
                b = b ⊻ (s1 ⊊ s2)
                b = b ⊻ (e in s)
            end
        end
    end
    s, b
end

@enumset AlphabetSet <: EnumSet{Alphabet}

sets = [AlphabetSet(rand(instances(Alphabet)) for _ in 0:length(instances(Alphabet))) for _ in 1:100]
basesets = map(Set, sets)

# warmup
workout(sets, )
workout(basesets, )
# benchmark
println(eltype(sets))
res1 = @time workout(sets, )
println(eltype(basesets))
res2 = @time workout(basesets, )

@assert res1 == res2 # both yield the same result

# AlphabetSet
#   0.000279 seconds (1 allocation: 16 bytes)
# Set{Alphabet}
#   0.503022 seconds (8.15 M allocations: 756.469 MiB, 13.51% gc time)
```
