#include "pdwt.h"
#include "wt.h"

// bands indexing:
// A  H1 V1 D1  H2 V2 D2 ...
// 0  1  2  3   4  5  6 ...

void dwt(float* in,float** bands,int dim1,int dim2, const char* wt,int lvl,
            int in_on_device,int bands_on_device)
{
    Wavelets W(in, dim2, dim1, wt, lvl, in_on_device?0:1);//0:mem on device 1:mem on host
    W.forward();
    int nbands = lvl*3+1;
    for(int i=0;i<nbands;i++){
        W.get_coeff(bands[i],i,bands_on_device);
    }
    return;
}

void idwt(float* out,float** bands,int dim1,int dim2,const char* wt,int lvl,
            int out_on_device,int bands_on_device)
{
    Wavelets W(nullptr, dim2, dim1, wt, lvl);
    int nbands = lvl*3+1;
    for(int i=0;i<nbands;i++){
        W.set_coeff(bands[i],i,bands_on_device);
    }
    W.inverse();
    W.get_image(out,out_on_device);
    return;
}
