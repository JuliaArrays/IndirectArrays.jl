module IndirectArrays

export IndirectArray

"""
    IndirectArray(index, values)

creates an array `A` where the values are looked up in the value table,
`values`, using the `index`.  Concretely, `A[i,j] =
values[index[i,j]]`.
"""
immutable IndirectArray{T,N} <: AbstractArray{T,N}
    index::Array{Int,N}
    values::Vector{T}
end

Base.size(A::IndirectArray) = size(A.index)
Base.linearindexing(A::IndirectArray) = Base.LinearFast()

@inline function Base.getindex(A::IndirectArray, i::Int)
    @boundscheck checkbounds(A.index, i)
    @inbounds idx = A.index[i]
    @boundscheck checkbounds(A.values, idx)
    @inbounds ret = A.values[idx]
    ret
end

@inline function Base.getindex{T,N}(A::IndirectArray{T,N}, I::Vararg{Int,N})
    @boundscheck checkbounds(A.index, I...)
    @inbounds idx = A.index[I...]
    @boundscheck checkbounds(A.values, idx)
    @inbounds ret = A.values[idx]
    ret
end

end # module
