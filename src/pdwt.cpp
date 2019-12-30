#include "pdwt.h"
#include "wt.h"

void dwt(float* in,float** bands,int dim1,int dim2,const char* wt,int lvl){
    Wavelets W(in, dim2, dim1, wt, lvl, 1);//0:mem on device 1:mem on host
    W.forward();
    int nbands = lvl*3+1;
    for(int i=0;i<nbands;i++){
        W.get_coeff(bands[i],i);
    }
    return;
}

void dwt_d(float* in,float** bands,int dim1,int dim2,const char* wt,int lvl){
    Wavelets W(in, dim2, dim1, wt, lvl, 0);//0:mem on device 1:mem on host
    W.forward();
    int nbands = lvl*3+1;
    for(int i=0;i<nbands;i++){
        W.get_coeff(bands[i],i);
    }
    return;
}

