__precompile__(true)

module IndirectArrays

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
function IndirectArray{T}(A::AbstractArray) where {T}
    values = unique(A)
    index = convert(Array{T}, indexin(A, values))
    return IndirectArray(index, values)
end
IndirectArray(A::AbstractArray) = IndirectArray{UInt8}(A)

Base.size(A::IndirectArray) = size(A.index)
Base.axes(A::IndirectArray) = axes(A.index)
Base.IndexStyle(::Type{IndirectArray{T,N,A,V}}) where {T,N,A,V} = IndexStyle(A)

Base.copy(A::IndirectArray) = IndirectArray(copy(A.index), copy(A.values))

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
    idx = findfirst(isequal(x), A.values)
    if idx == nothing
        push!(A.values, x)
        A.index[i] = length(A.values)
    else
        A.index[i] = idx
    end
    return A
end

@inline function Base.push!(A::IndirectArray{T,1} where T, x)
    idx = findfirst(isequal(x), A.values)
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

function Base.append!(A::IndirectArray{<:Any,1}, B::AbstractVector)
    for b in B
        push!(A, b)
    end
    return A
end

end # module
