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

pwd()
mat = Float32.(Gray.(load("lenna.png")))
matd = CuArray(mat)
Gray.(mat)
m,n = size(mat)


spec = dwt(mat,"db8",2)
Gray.(spec[1])
Gray.(coeff(spec,(m,n)))

specd = dwt(matd,"db8",2)
Gray.(Array(specd[1]))
Gray.(coeff(Array(specd),(m,n)))

imgd = idwt(CuArray.(spec),"db8")
Gray.(Array(imgd))

img = idwt(spec,"db8")
Gray.(img)

end#module PDWT
