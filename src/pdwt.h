#ifndef PDWT_H
#define PDWT_H

extern "C"{
    void dwt(float* in,float** bands,int dim1,int dim2,const char* wt,int lvl,int in_on_device,int bands_on_device);
    void idwt(float* out,float** bands,int dim1,int dim2,const char* wt,int lvl,int out_on_device,int bands_on_device);
    void copyCoeff(float** bands,float** out,int dim1,int dim2,int lvl,int in_on_device,int out_on_device);
    void copyImage(float* img,float* out,int dim1,int dim2,int in_on_device,int out_on_device);
}

#endif