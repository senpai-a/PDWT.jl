#ifndef PDWT_H
#define PDWT_H

extern "C"{
    void dwt(float* in,float** bands,int dim1,int dim2,const char* wt,int lvl);
    void dwt_d(float* in,float** bands,int dim1,int dim2,const char* wt,int lvl);
}

#endif