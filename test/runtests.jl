using IndirectArrays
using Base.Test, Colors

colors = [RGB(1,0,0), RGB(0,1,0), RGB(0,0,1)]
index = [1 2;
         3 1]
A = IndirectArray(index, colors)
@test eltype(A) == RGB{U8}
@test size(A) == (2,2)
@test ndims(A) == 2
@test A[1,1] === A[1] === RGB(1,0,0)
@test A[2,1] === A[2] === RGB(0,0,1)
@test A[1,2] === A[3] === RGB(0,1,0)
@test A[2,2] === A[4] === RGB(1,0,0)
@test isa(eachindex(A), AbstractUnitRange)

# Bounds checking upon construction
index_ob = copy(index)
index_ob[1] = 5   # out-of-bounds
unsafe_ia(idx, vals) = (@inbounds ret = IndirectArray(idx, vals); ret)
  safe_ia(idx, vals) = (ret = IndirectArray(idx, vals); ret)
@test_throws BoundsError safe_ia(index_ob, colors)
# This requires inlining, which means it fails on Travis since we turn
# off inlining for better coverage stats
# B = unsafe_ia(index_ob, colors)
# @test_throws BoundsError B[1]
# @test B[2] == RGB(0,0,1)
