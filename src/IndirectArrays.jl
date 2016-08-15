module IndirectArrays

export IndirectArray

"""
    IndirectArray(index, values)

creates an array `A` where the values are looked up in the value table,
`values`, using the `index`.  Concretely, `A[i,j] =
values[index[i,j]]`.
"""
immutable IndirectArray{T,N,I<:Integer} <: AbstractArray{T,N}
    index::Array{I,N}
    values::Vector{T}

    @inline function IndirectArray(index, values)
        # The typical logic for testing bounds and then using
        # @inbounds will not check whether index is inbounds for
        # values. So we had better check this on construction.
        @boundscheck checkbounds(values, index)
        new(index, values)
    end
end
Base.@propagate_inbounds IndirectArray{T,N,I<:Integer}(index::Array{I,N},values::Vector{T}) = IndirectArray{T,N,I}(index,values)

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
