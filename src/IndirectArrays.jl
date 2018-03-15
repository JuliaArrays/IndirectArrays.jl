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
struct IndirectArray{T,N,A<:AbstractArray{<:Integer,N},V<:AbstractVector{T}} <: AbstractArray{T,N}
    index::A
    values::V

    @inline function IndirectArray{T,N,A,V}(index, values) where {T,N,A,V}
        # The typical logic for testing bounds and then using
        # @inbounds will not check whether index is inbounds for
        # values. So we had better check this on construction.
        @boundscheck checkbounds(values, index)
        new{T,N,A,V}(index, values)
    end
end
Base.@propagate_inbounds IndirectArray(index::AbstractArray{<:Integer,N}, values::AbstractVector{T}) where {T,N} =
    IndirectArray{T,N,typeof(index),typeof(values)}(index, values)

function (::Type{IndirectArray{T}})(A::AbstractArray, values::AbstractVector = unique(A)) where {T}
    index = convert(Array{T}, indexin(A, values))
    return IndirectArray(index, values)
end
IndirectArray(A::AbstractArray, values::AbstractVector = unique(A)) = IndirectArray{UInt8}(A, values)

Base.size(A::IndirectArray) = size(A.index)
Base.indices(A::IndirectArray) = indices(A.index)
Base.IndexStyle(::Type{IndirectArray{T,N,A,V}}) where {T,N,A,V} = IndexStyle(A)

Base.copy(A::IndirectArray) = IndirectArray(copy(A.index), copy(A.values))

if VERSION < v"0.6.3"
    # This method is only necessary because of a bug in Julia 0.6.2 and can be removed
    # when we no longer support that version
    @inline function Base.getindex(A::IndirectArray{<:Any,1}, i::Int)
        @boundscheck checkbounds(A.index, i)
        @inbounds idx = A.index[i]
        @boundscheck checkbounds(A.values, idx)
        @inbounds ret = A.values[idx]
        ret
    end
end

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

@inline function Base.setindex!(A::IndirectArray, x, i::Int)
    @boundscheck checkbounds(A.index, i)
    idx = Compat.findfirst(A.values, x)
    if idx == nothing
        push!(A.values, x)
        A.index[i] = length(A.values)
    else
        A.index[i] = idx
    end
    return A
end

@inline function Base.push!(A::IndirectArray{T,1} where T, x)
    idx = Compat.findfirst(A.values, x)
    if idx == nothing
        push!(A.values, x)
        push!(A.index, length(A.values))
    else
        push!(A.index, idx)
    end
    return A
end

function Base.append!(A::IndirectArray{T,1}, B::IndirectArray{T,1}) where T
    if A.values == B.values
        append!(A.index, B.index)
    else # pretty inefficient but let's get something going
        for b in B
            push!(A, b)
        end
    end
    return A
end

end # module
