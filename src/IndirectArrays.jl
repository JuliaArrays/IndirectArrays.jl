__precompile__(true)

module IndirectArrays

using Compat

export IndirectArray

"""
    IndirectArray(index, values)

creates an array `A` where the values are looked up in the value table,
`values`, using the `index`.  Concretely, `A[i,j] =
values[index[i,j]]`.
"""
struct IndirectArray{T,N,I<:Integer} <: AbstractArray{T,N}
    index::Array{I,N}
    values::Vector{T}

    @inline function IndirectArray{T,N,I}(index, values) where {T,N,I}
        # The typical logic for testing bounds and then using
        # @inbounds will not check whether index is inbounds for
        # values. So we had better check this on construction.
        @boundscheck checkbounds(values, index)
        new{T,N,I}(index, values)
    end
end
Base.@propagate_inbounds IndirectArray(index::Array{I,N},values::Vector{T}) where {T,N,I<:Integer} = IndirectArray{T,N,I}(index,values)

Base.size(A::IndirectArray) = size(A.index)
Base.IndexStyle(::Type{<:IndirectArray}) = IndexLinear()

@inline function Base.getindex(A::IndirectArray, i::Int)
    @boundscheck checkbounds(A.index, i)
    @inbounds idx = A.index[i]
    @boundscheck checkbounds(A.values, idx)
    @inbounds ret = A.values[idx]
    ret
end

@inline function Base.getindex(A::IndirectArray{T,N}, I::Vararg{Int,N}) where {T,N}
    @boundscheck checkbounds(A.index, I...)
    @inbounds idx = A.index[I...]
    @boundscheck checkbounds(A.values, idx)
    @inbounds ret = A.values[idx]
    ret
end

end # module
