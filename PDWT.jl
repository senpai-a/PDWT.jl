module PDWT
export dwt,idwt

using Images
using CuArrays
using CUDAdrv

function dwt(mat::AbstractArray{Float32,2},wavelet::String,L::Int)
	m,n = size(mat)
	mm,nn = m,n
	ret = Array{Float32,2}[]
	for l in 1:L
		mm = ceil(Int,mm/2); nn = ceil(Int,nn/2);
		for foo in 1:3
			push!(ret,Array{Float32,2}(undef,mm,nn))
		end
	end
	pushfirst!(ret,Array{Float32,2}(undef,mm,nn))

	"""	void dwt(	float* in, float** bands,
					int dim1, int dim2,
					const char* wt, int lvl,
        			int in_on_device, int bands_on_device)
	"""
	ccall((:dwt,:libpdwt),
		Cvoid,(Ptr{Cfloat},Ptr{Ptr{Cfloat}},
				Cint,Cint,
				Cstring,Cint,
				Cint,Cint),
		mat,ret,
		m,n,
		wavelet,L,
		0,0)
	return ret
end

function dwt(mat::CuArray{Float32,2},wavelet::String,L::Int)
	m,n = size(mat)
	mm,nn = m,n
	ret = CuArray{Float32,2}[]
	for l in 1:L
		mm = ceil(Int,mm/2); nn = ceil(Int,nn/2);
		for foo in 1:3
			push!(ret,CuArray{Float32,2}(undef,mm,nn))
		end
	end
	pushfirst!(ret,CuArray{Float32,2}(undef,mm,nn))
	retp = CuPtr[ret[i].ptr for i in 1:length(ret)]

	"""	void dwt(	float* in, float** bands,
					int dim1, int dim2,
					const char* wt, int lvl,
					int in_on_device, int bands_on_device)
	"""
	ccall((:dwt,:libpdwt),
		Cvoid,(CuPtr{Cfloat},Ptr{CuPtr{Cfloat}},
				Cint,Cint,
				Cstring,Cint,
				Cint,Cint),
		mat.ptr,retp,
		m,n,
		wavelet,L,
		1,1)
	return ret
end

function idwt(bands::Vector{<:AbstractArray{Float32,2}},wavelet::String)
	nbands = length(bands)
	L = (nbands-1)÷3
	m,n = size(bands[2]).*2
	ret = Array{Float32,2}(undef,m,n)

	"""	void idwt(	float* out, float** bands,
					int dim1, int dim2,
					const char* wt, int lvl,
					int in_on_device, int bands_on_device)
	"""
	ccall((:idwt,:libpdwt),
		Cvoid,(Ptr{Cfloat},Ptr{Ptr{Cfloat}},
				Cint,Cint,
				Cstring,Cint,
				Cint,Cint),
		ret,bands,
		m,n,
		wavelet,L,
		0,0)
	return ret
end

function idwt(bands::Vector{<:CuArray{Float32,2}},wavelet::String)
	nbands = length(bands)
	L = (nbands-1)÷3
	m,n = size(bands[2]).*2
	ret = CuArray{Float32,2}(undef,m,n)
	bandsp = CuPtr[bands[i].ptr for i in 1:nbands]
	"""	void idwt(	float* out, float** bands,
					int dim1, int dim2,
					const char* wt, int lvl,
					int in_on_device, int bands_on_device)
	"""
	ccall((:idwt,:libpdwt),
		Cvoid,(CuPtr{Cfloat},Ptr{CuPtr{Cfloat}},
				Cint,Cint,
				Cstring,Cint,
				Cint,Cint),
		ret.ptr,bandsp,
		m,n,
		wavelet,L,
		1,1)
	return ret
end

#the following are drafts for testing
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

function showcoeff(s,size)
	Gray.(coeff(Array.(s),size))
end

function copyimg(mat)
	ret = similar(mat)
	m,n = size(mat)
	d = isa(mat,CuArray) ? 1 : 0
	ccall((:copyImage,:libpdwt),
		Cvoid,(PtrOrCuPtr{Cfloat},PtrOrCuPtr{Cfloat},Cint,Cint,Cint,Cint),
		mat,ret,m,n,d,d)
	ret
end

"""
function copyimg(mat::CuArray)
	ret = similar(mat)
	m,n = size(mat)
	d = isa(mat,CuArray) ? 1 : 0
	ccall((:copyImage,:libpdwt),
		Cvoid,(CuPtr{Cfloat},CuPtr{Cfloat},Cint,Cint,Cint,Cint),
		mat.ptr,ret.ptr,m,n,d,d)
	ret
end
"""

function copycoeff(spec,m,n)
	ret = similar(spec)
	for i in 1:length(spec) ret[i]=similar(spec[i]) end
	lvl = (length(spec)-1)÷3
	d = isa(spec[1],CuArray) ? 1 : 0
	ccall((:copyCoeff,:libpdwt),
		Cvoid,(Ptr{Ptr{Cfloat}},Ptr{Ptr{Cfloat}},Cint,Cint,Cint,Cint,Cint),
		spec,ret,m,n,lvl,d,d)
	ret
end

function copycoeff(spec::Vector{<:CuArray},m,n)
	ret = similar(spec)
	for i in 1:length(spec) ret[i]=similar(spec[i])
	println(summary(ret[i])) end
	println(summary(ret))
	lvl = (length(spec)-1)÷3
	d = 1
	specp = CuPtr{Float32}[spec[i].ptr for i in 1:length(spec)]
	retp = CuPtr{Float32}[ret[i].ptr for i in 1:length(ret)]
	ccall((:copyCoeff,:libpdwt),
		Cvoid,(Ptr{CuPtr{Cfloat}},Ptr{CuPtr{Cfloat}},Cint,Cint,Cint,Cint,Cint),
		specp,retp,m,n,lvl,d,d)
	ret
end

pwd()

mat = Float32.(Gray.(load("lenna.png")))
matd = CuArray(mat)
Gray.(Array(matd))
m,n = size(mat)
siz = (m,n)
sd = Vector{CuArray}(undef,7)
sd[1] = matd[1:m÷4,1:n÷4]
sd[6] = matd[m÷4+1:m÷2,1:n÷4]
sd[5] = matd[1:m÷4,n÷4+1:n÷2]
sd[7] = matd[m÷4+1:m÷2,n÷4+1:n÷2]
sd[3] = matd[m÷2+1:m,1:n÷2]
sd[2] = matd[1:m÷2,n÷2+1:n]
sd[4] = matd[m÷2+1:m,n÷2+1:n]
s = Array.(sd)
showcoeff(s,siz)
showcoeff(sd,siz)

cs =copycoeff(s,m,n)
csd = copycoeff(sd,m,n)
showcoeff(cs,siz)
showcoeff(csd,siz)


cmatd=copyimg(matd)
Gray.(Array(cmatd))
cmat=copyimg(mat)
Gray.(cmat)

spec = dwt(copy(mat),"db8",2)
Gray.(spec[1])
showcoeff(spec,siz)

specd = dwt(matd,"db8",2);Gray.(coeff(Array.(specd),(m,n)))

imgd = idwt(CuArray.(spec),"db8")
Gray.(Array(imgd))

img = idwt(spec,"db8")
Gray.(img)

end#module PDWT
