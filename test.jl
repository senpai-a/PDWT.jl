using Images
using CuArrays
using CUDAdrv
include("../cameraFingerprint/rwt.jl")
using .rwt

function dwt1(mat::AbstractArray{Float32,2},wavelet::String,L::Int)
	m,n = size(mat)
	ret = [Array{Float32,2}(undef,ceil(Int,m/2^L),ceil(Int,n/2^L))]
	for l in 1:L
		for foo in 1:3
			push!(ret,Array{Float32,2}(undef,ceil(Int,m/2^l),ceil(Int,n/2^l)))
		end
	end
	ccall((:dwt,:libpdwt),
		Cvoid,(Ptr{Cfloat},Ptr{Ptr{Cfloat}},Cint,Cint,Cstring,Cint),
		mat,ret,m,n,wavelet,L)
	return ret
end

function dwt1(mat::CuArray{Float32,2},wavelet::String,L::Int)
	m,n = size(mat)
	ret::Vector{CuArray} = [CuArray{Float32,2}(undef,ceil(Int,m/2^L),ceil(Int,n/2^L))]
	for l in 1:L
		for foo in 1:3
			push!(ret,CuArray{Float32,2}(undef,ceil(Int,m/2^l),ceil(Int,n/2^l)))
		end
	end
	retp = CuPtr{Float32}[ret[i].ptr for i in 1:length(ret)]
	ccall((:dwt_d,:libpdwt),
		Cvoid,(CuPtr{Cfloat},Ptr{CuPtr{Cfloat}},Cint,Cint,Cstring,Cint),
		mat.ptr,retp,m,n,wavelet,L)
	return ret
end

function coeff(spec,size)
	m,n = size
	ret = Array{Float32,2}(undef,m,n)
	ret[1:m÷4,1:n÷4].=spec[1]
	ret[m÷4+1:m÷2,1:n÷4].=spec[6]
	ret[1:m÷4,n÷4+1:n÷2].=spec[5]
	ret[m÷4+1:m÷2,n÷4+1:n÷2].=spec[7]
	ret[m÷2+1:m,1:n÷2].=spec[3]
	ret[1:m÷2,n÷2+1:n].=spec[2]
	ret[m÷2+1:m,n÷2+1:n].=spec[4]
	ret
end

pwd()
mat = Float32.(Gray.(load("lenna.png")))
matd = CuArray(mat)
Gray.(mat)
m,n = size(mat)

Gray.(rwt.dwt(Float64.(mat),wavelet["DB8"],2))

specd = dwt1(matd,"db8",2)
spec = dwt1(mat,"db8",2)
Gray.(coeff(specd,(m,n)))

bar = Gray.(rwt.dwt(Float64.(mat),wavelet["DB8"],2))

save("lennaCoeff.png",foo)
save("lennaCoeffrwt.png",bar)
save("lennagray.png",Gray.(mat))
